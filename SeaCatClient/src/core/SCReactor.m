//
//  Reactor.m
//  SeaCatClient
//
//  Created by Ales Teska on 30/11/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import "SeaCatInternals.h"
#import "SCPingFactory.h"
#import "SCStreamFactory.h"
#import "SCCntlFrameConsumerProtocol.h"


// Global pointer to reactor
SCReactor * SeaCatReactor = NULL;

///

static void hook_write_ready(void ** data, uint16_t * data_len);
static void hook_read_ready(void ** data, uint16_t * data_len);
static void hook_frame_received(void * data, uint16_t frame_len);
static void hook_frame_return(void *data);
static void hook_worker_request(char worker);
static double hook_evloop_heartbeat(double now);
static void hook_state_changed(void);
static void hook_gwconn_reset(void);
static void hook_gwconn_connected(void);
static void hook_clientid_changed(void);

///

static NSNumber * SPDY_buildFrameVersionType(uint16_t cntlFrameVersion, uint16_t cntlType)
{
	uint32_t ret = cntlFrameVersion;
	ret <<= 16;
	ret |= cntlType;
	return [NSNumber numberWithUnsignedInt:ret];
}

///

@implementation SCReactor
{
    bool started;
    
    SCFrame * readFrame;
    SCFrame * writeFrame;

	//TODO: Check if NSMutableDictionary<NSNumber *, ...> is the most effective way (NSNumber is constantly created)
	NSMutableDictionary<NSNumber *, id<SCCntlFrameConsumerProtocol>> * cntlFrameConsumers;
	NSMutableArray<id<SCFrameProviderProtocol>> * frameProviders;
}

@synthesize pingFactory;
@synthesize streamFactory;
@synthesize framePool;
@synthesize CSRDelegate;
@synthesize networkReachability;
@synthesize lastState;
@synthesize clientTag;
@synthesize clientId;

-(SCReactor *)init:(NSString *)appId
{
    int rc;
	NSError * error;
	
    self = [super init];
    if (!self) return self;

	started = false;

    
	framePool = [SCFramePool new];
	readFrame = NULL;
	writeFrame = NULL;
    lastState = @"?????";
    clientTag = @"[AAAAAAAAAAAAAAAA]";
    clientId = @"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    
	cntlFrameConsumers = [NSMutableDictionary<NSNumber *, id<SCCntlFrameConsumerProtocol>> new];
	frameProviders = [NSMutableArray<id<SCFrameProviderProtocol>> new];
	
    
	pingFactory = [SCPingFactory new];
	[cntlFrameConsumers
		setObject:pingFactory
		forKey:SPDY_buildFrameVersionType(SEACATCC_SPDY_CNTL_FRAME_VERSION_SPD3, SEACATCC_SPDY_CNTL_TYPE_PING)
	];

    streamFactory = [SCStreamFactory new];
    [cntlFrameConsumers
        setObject:streamFactory
        forKey:SPDY_buildFrameVersionType(SEACATCC_SPDY_CNTL_FRAME_VERSION_ALX1, SEACATCC_SPDY_CNTL_TYPE_SYN_REPLY)
    ];
    [cntlFrameConsumers
        setObject:streamFactory
        forKey:SPDY_buildFrameVersionType(SEACATCC_SPDY_CNTL_FRAME_VERSION_SPD3, SEACATCC_SPDY_CNTL_TYPE_RST_STREAM)
    ];

    rc = seacatcc_hook_register('S', hook_state_changed);
    assert(rc == SEACATCC_RC_OK);
    rc = seacatcc_hook_register('R', hook_gwconn_reset);
    assert(rc == SEACATCC_RC_OK);
    rc = seacatcc_hook_register('c', hook_gwconn_connected);
    assert(rc == SEACATCC_RC_OK);
    rc = seacatcc_hook_register('i', hook_clientid_changed);
    assert(rc == SEACATCC_RC_OK);

    
	// Construct var dir
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSMutableString *varDir = [[paths objectAtIndex:0] mutableCopy];
	[varDir appendString:SeaCatHostSuffix];


    rc = seacatcc_init(
		[appId UTF8String],
		NULL, //TODO: Application Id suffix
#if TARGET_OS_IOS
        "ios",
#elif TARGET_OS_TV
        "tvs",
#else
        "gen",
#endif
		[varDir UTF8String],
        hook_write_ready,
        hook_read_ready,
        hook_frame_received,
        hook_frame_return,
        hook_worker_request,
        hook_evloop_heartbeat,
        NULL // There is no OpenSSL engine on iOS
    );
	error = SeaCatCheckRC(rc, @"seacatcc_init");
    if (error != NULL) return NULL;

    //TODO: Use the gateway address instead of generic reachabilityForInternetConnection
    self.networkReachability = [Reachability reachabilityForInternetConnection];
    [self.networkReachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    return self;
}


-(void)start
{
    if (!self->started)
    {
        [NSThread detachNewThreadSelector: @selector(_run) toTarget:self withObject:NULL];
        self->started = true;
    }
}

- (void)_run
{
//    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [[NSThread currentThread] setName:@"SeaCatReactorThread"];

    int rc;
    rc = seacatcc_run();
	NSError * error = SeaCatCheckRC(rc, @"seacatcc_run");
	if (error != NULL) SCLOG_ERROR(@"%@", error);
    
//    [pool release];
}


-(void)registerFrameProvider:(id<SCFrameProviderProtocol>)provider single:(bool)single
{
	@synchronized(frameProviders) {
		if ((single) && ([frameProviders containsObject:provider])) return;
		[frameProviders addObject:provider];
	}

	// Yield to C-Core that we have frame to send
	int rc = seacatcc_yield('W');
	if ((rc > 7900) && (rc < 8000))
	{
		SCLOG_WARN(@"return code %d in %s",rc ,"seacatcc_yield");
		rc = SEACATCC_RC_OK;
	}

	NSError * error = SeaCatCheckRC(rc, @"seacatcc_yield");
	if (error != NULL) SCLOG_ERROR(@"%@", error);
}


-(void)callbackWriteReady:(void **)data data_len:(uint16_t *)data_len;
{
	assert(writeFrame == NULL);

	@synchronized(frameProviders)
	{

		NSMutableArray<id<SCFrameProviderProtocol>> * providersToKeep = NULL;

		while (writeFrame == NULL)
		{
			id<SCFrameProviderProtocol> provider = [frameProviders firstObject];
			if (provider == NULL)  break;
			[frameProviders removeObjectAtIndex:0];

			bool keep = false;
			writeFrame = [provider buildFrame:&keep reactor:self];
			
			if (keep)
			{
				if (providersToKeep == NULL) providersToKeep = [NSMutableArray<id<SCFrameProviderProtocol>> new];
				[providersToKeep addObject:provider];
			}
		}
		
		if (providersToKeep != NULL)
			[frameProviders addObjectsFromArray:providersToKeep];
	}
	
	if (writeFrame != NULL)
	{
		[writeFrame flip];
		*data = (void *)[writeFrame bytes];
		*data_len = [writeFrame length];
	}
}


-(void)callbackReadReady:(void **)data data_len:(uint16_t *)data_len;
{
    assert(readFrame == NULL);
	
    readFrame = [framePool borrow:@"Reactor:callbackReadReady"];
    *data = (void *)[readFrame bytes];
    *data_len = [readFrame length];
}


-(void)callbackFrameReceived:(void *)data frame_len:(uint16_t)frame_len;
{
	bool giveBackFrame = true;

	if ([readFrame bytes] != data)
	{
		SCLOG_WARN(@"Invalid frame received: %p", data);
		return;
	}

	SCFrame * frame = readFrame;
	readFrame = NULL;
	[frame flip:frame_len];
	
	uint8_t fb = [frame get8at:0];
	
	if ((fb & (1L << 7)) != 0)
	{
		giveBackFrame = [self receivedControlFrame:frame];
	}
	
	else
	{
        giveBackFrame = [streamFactory receivedDataFrame:frame reactor:self];
	}

	
	if (giveBackFrame)
	{
		[framePool giveBack:frame];
	}
}


-(void)callbackFrameReturn:(void *)data;
{
    if ([readFrame bytes] == data)
    {
        [framePool giveBack:readFrame];
        readFrame = NULL;
        return;
    }

	if ([writeFrame bytes] == data)
	{
		[framePool giveBack:writeFrame];
		writeFrame = NULL;
		return;
	}

    SCLOG_WARN(@"Unknown frame returned: %p", data);
}


-(double)callbackEvloopHeartbeat:(double)now
{
	// This method is called periodically from event loop (period is fairly arbitrary)
	// Return value of this method represent the longest time when it should be called again
	// It will very likely be called in shorter period too (as a result of heart beat triggered by other events)
	
	[pingFactory heartBeat:now];
	[framePool heartBeat:now];
    
    return 5.0;
}


-(bool)receivedControlFrame:(SCFrame *)frame
{
	uint32_t frameVersionType = [frame load32] & 0x7fffffff;

	uint32_t frameLength = [frame load32];
	uint8_t frameFlags = (uint8_t)(frameLength >> 24);
	frameLength &= 0xffffff;

	if ((frameLength + SEACATCC_SPDY_HEADER_SIZE) != [frame length])
	{
		SCLOG_WARN(@"Incorrect frame received: %d %x %d %x - closing connection", [frame length], frameVersionType, frameLength, frameFlags);
		
		// Invalid frame received - shutdown a reactor (disconnect) ...
		//TODO: [self shutdown];
		return true;
	}
	
	id<SCCntlFrameConsumerProtocol> consumer = [cntlFrameConsumers objectForKey:[NSNumber numberWithUnsignedInt:frameVersionType]];
	if (consumer == NULL)
	{
		SCLOG_WARN(@"Unidentified Control frame received: %d %x %d %x", [frame length], frameVersionType, frameLength, frameFlags);
		return true;
	}

	return [consumer receivedControlFrame:frame reactor:self frameVersionType:frameVersionType frameLength:frameLength frameFlags:frameFlags];
}

-(void)updateState
{
    char state_buf[SEACATCC_STATE_BUF_SIZE];
    seacatcc_state(state_buf);
    lastState = [[NSString alloc] initWithUTF8String:state_buf];
    [self postNotificationName:SeaCat_Notification_StateChanged];
}

-(void)postNotificationName:(NSString *)notificationName
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    });
}


-(void)reachabilityChanged:(NSNotification *)note
{
    int rc;

    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);

    if (curReach.currentReachabilityStatus == NotReachable)
    {
        // Network is not reachable but client is connecting ...
        char c = [lastState characterAtIndex:0];
        if ((c == 'E') || (c == 'H') || (c == 'P') || (c == 'p')  || (c == 'C'))
        {
            rc = seacatcc_yield('d');
            NSError * error = SeaCatCheckRC(rc, @"seacatcc_yield");
            if (error != NULL) SCLOG_ERROR(@"%@", error);

            [self postNotificationName:SeaCat_Notification_GWConnReset];
        }
    } else {
        char c = [lastState characterAtIndex:0];
        if (c == 'n')
        {
            rc = seacatcc_yield('Q');
            NSError * error = SeaCatCheckRC(rc, @"seacatcc_yield");
            if (error != NULL) SCLOG_ERROR(@"%@", error);
        }
    }
}

-(void)onGWConnReset
{
    [pingFactory reset];
    //[streamFactory reset];

    [self postNotificationName:SeaCat_Notification_GWConnReset];
}

-(void)onGWConnConnected
{
    [self postNotificationName:SeaCat_Notification_GWConnConnected];
}

-(void)onClientIdChanged:(NSString *)client_id tag:(NSString*)client_tag
{
    clientTag = client_tag;
    clientId = client_id;
    
    [self postNotificationName:SeaCat_Notification_ClientIdChanged];
}

@end

/// Hooks

static void hook_write_ready(void ** data, uint16_t * data_len)
{
    assert(SeaCatReactor != NULL);
    [SeaCatReactor callbackWriteReady:data data_len:data_len];
}

static void hook_read_ready(void ** data, uint16_t * data_len)
{
    assert(SeaCatReactor != NULL);
    [SeaCatReactor callbackReadReady:data data_len:data_len];
}

static void hook_frame_received(void * data, uint16_t frame_len)
{
    assert(SeaCatReactor != NULL);
    [SeaCatReactor callbackFrameReceived:data frame_len:frame_len];
}

static void hook_frame_return(void *data)
{
    assert(SeaCatReactor != NULL);
    [SeaCatReactor callbackFrameReturn:data];
}

static void hook_worker_request(char worker)
{
    switch (worker) {
        case 'P':
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                seacatcc_ppkgen_worker();
            });
            break;

        case 'C':
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[SeaCatReactor CSRDelegate] submit:nil];

            });
            if (SeaCatReactor != NULL)
            {
                [SeaCatReactor postNotificationName:SeaCat_Notification_CSRNeeded];
            }
            break;
            
        case 'n':
            break;

        case 's':
            SCLOG_DEBUG(@"Secret key requested.");
            [SeaCatClient startAuth];
            break;

        default:
            SCLOG_WARN(@"Unknown worker requested: %c", worker);
            break;
    }
}

static double hook_evloop_heartbeat(double now)
{
    assert(SeaCatReactor != NULL);
    return [SeaCatReactor callbackEvloopHeartbeat:now];
}

void hook_state_changed(void)
{
    if (SeaCatReactor == NULL) return;
    [SeaCatReactor updateState];
}

void hook_gwconn_reset(void)
{
    if (SeaCatReactor == NULL) return;
    [SeaCatReactor onGWConnReset];
}

void hook_gwconn_connected(void)
{
    if (SeaCatReactor == NULL) return;
    [SeaCatReactor onGWConnConnected];
}

void hook_clientid_changed(void)
{
    if (SeaCatReactor == NULL) return;
    [SeaCatReactor onClientIdChanged:[[NSString alloc] initWithUTF8String:seacatcc_client_id()] tag:[[NSString alloc] initWithUTF8String:seacatcc_client_tag()]];
}
