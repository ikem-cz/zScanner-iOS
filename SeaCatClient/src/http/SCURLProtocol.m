#import "SeaCatInternals.h"
#import "SCCanonicalRequest.h"

#import <zlib.h>

// Heavily inspired by https://github.com/twitter/CocoaSPDY
// For more info see: http://nshipster.com/nsurlprotocol/

///

#define DECOMPRESSED_CHUNK_LENGTH 8192
NSString * SeaCatHostSuffix = @".seacat";

///

@implementation SCURLProtocol
{
    struct {
        BOOL didStartLoading;
        BOOL responseFin;
        BOOL didSentSynStream;
        BOOL HTTPBodyStream;
        BOOL didStopLoading;
        BOOL compressedResponse;
    } flags;
    
    int zlibStreamStatus;
    z_stream zlibStream;
    
    NSInputStream * bodyStream;
}

@synthesize streamId;

#pragma mark NSURLProtocol implementation

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{

    NSString *scheme = request.URL.scheme.lowercaseString;
    if ([scheme isEqualToString:@"http"] | [scheme isEqualToString:@"https"])
	{
		return [request.URL.host hasSuffix:SeaCatHostSuffix];
	}
    
	return FALSE;
}

- (void)dealloc
{
    if (flags.compressedResponse)
    {
        inflateEnd(&zlibStream);
    }
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *canonicalRequest = SCCanonicalRequestForRequest(request);
    [SCURLProtocol setProperty:@(YES) forKey:@"x-spdy-is-canonical-request" inRequest:canonicalRequest];
    return canonicalRequest;
}


- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client
{
    // iOS 8 will call this using the 'request' returned from canonicalRequestForRequest. However,
    // iOS 7 passes the original (non-canonical) request. As SPDYCanonicalRequestForRequest is
    // somewhat heavyweight, we'll use a flag to detect non-canonical requests. Ensuring the
    // canonical form is used for processing is important for correctness.
    BOOL isCanonical = ([SCURLProtocol propertyForKey:@"x-spdy-is-canonical-request" inRequest:request] != nil);
    if (!isCanonical) {
        request = [SCURLProtocol canonicalRequestForRequest:request];
    }
    
    flags.didStartLoading = NO;
    flags.didStopLoading = NO;
    flags.HTTPBodyStream = NO;
    flags.didSentSynStream = NO;
    flags.compressedResponse = NO;
    flags.responseFin = NO;
    streamId = -1;
    bodyStream = nil;
    
    return [super initWithRequest:request cachedResponse:cachedResponse client:client];
}

///

- (void)startLoading
{
    // Only allow one startLoading call. iOS 8 using NSURLSession has exhibited different
    // behavior, by calling startLoading, then stopLoading, then startLoading, etc, over and
    // over. This happens asynchronously when using a NSURLSessionDataTaskDelegate after the
    // URLSession:dataTask:didReceiveResponse:completionHandler: callback.
    if (flags.didStartLoading != NO) {
        SCLOG_WARN(@"start loading already called, ignoring %@", self.request.URL.absoluteString);
        return;
    }
    flags.didStartLoading = YES;

    if (SeaCatReactor == NULL)
    {
        SCLOG_ERROR(@"URL request when not initialized.");
        [[self client]
            URLProtocol:self
            didFailWithError:SeaCatError(SeaCat_ErrorCore_GENERIC, @"SeaCat URL request started but SeaCat is not ready.")
         ];

        return; // Report error
    }

    [SeaCatReactor registerFrameProvider:self single:true];
}

- (void)stopLoading
{
//    SCLOG_DEBUG(@"SCURLProtocol >> stopLoading: %@", self);
    
    flags.didStopLoading = YES;
}

-(SCFrame *)buildFrame:(bool *)keep reactor:(SCReactor *)reactor
{
    if (flags.didSentSynStream == NO)
    {
        return [self buildFrameSYN_STREAM:keep reactor:reactor];
    }

    if (bodyStream != nil)
    {
//        NSLog(@"bodyStream 2 status %lu", (unsigned long)[bodyStream streamStatus]);
        
        SCFrame * frame = [reactor.framePool borrow:@"SCURLProtocol.buildFrame"];
        
        [frame store32:streamId];
        uint16_t length_position = frame.position;
        [frame store32:0];
        NSInteger bytesRead = [bodyStream read:(frame.bytes + frame.position) maxLength:(frame.capacity - frame.position)];
        if (bytesRead < 0)
        {
            SCLOG_ERROR(@"Reading from HTTP body stream: %@", bodyStream.streamError);
            return nil;
        }

//        NSLog(@"bodyStream 3 status %lu, bytes: %ld", (unsigned long)[bodyStream streamStatus], bytesRead);
        
        bool fin_flag = ([bodyStream streamStatus] == NSStreamStatusAtEnd);
        if (bytesRead == 0) fin_flag = true;
        
        uint32_t length = (long)bytesRead;
        if (fin_flag) length |= SEACATCC_SPDY_FLAG_FIN << 24;

        [frame store32at:length_position value:length];
        [frame advance:length];

        *keep = !fin_flag;

        return frame;
    }
    
    return nil;
}

-(SCFrame *)buildFrameSYN_STREAM:(bool *)keep reactor:(SCReactor *)reactor
{
    assert(streamId == -1);
    assert(flags.didSentSynStream == NO);
    
    streamId = [reactor.streamFactory registerStream:self];
    
    bool fin_flag = true;
    if ([[self request] HTTPBody] != nil)
    {
        flags.HTTPBodyStream = NO;
        fin_flag = false;
    }
    else
    {
        bodyStream = [[self request] HTTPBodyStream];
        if (bodyStream != nil)
        {
            [bodyStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [bodyStream open];
            NSLog(@"bodyStream status %lu", (unsigned long)[bodyStream streamStatus]);
            flags.HTTPBodyStream = YES;
            fin_flag = false;
        }
    }

    // Build header frame, called after startLoading() from a SeaCat
    SCFrame * frame = [reactor.framePool borrow:@"SCURLProtocol.buildFrameSYN_STREAM"];
    [frame buildALX1_SYN_STREAM:self.request streamId:streamId fin_flag:fin_flag priority:1];

    *keep = !fin_flag;
    flags.didSentSynStream = YES;
    
    return frame;
}

- (bool)receivedALX1_SYN_REPLY:(SCFrame *)frame reactor:(SCReactor *)reactor frameVersionType:(uint32_t)versiontype frameLength:(uint16_t)lenght frameFlags:(uint8_t)flags
{
    // Called by stream factory when response header is received

    // Will contain a value of 'Location' header if provided
    NSString * location = nil;
    
    // Prepare headers
    NSMutableDictionary * headers = [[NSMutableDictionary alloc] init];

    NSMutableArray * cookies = nil;
    BOOL handleCookies = self.request.HTTPShouldHandleCookies;
    
    // Status code
    int status = [frame load16];

    // Reserved
    /*int __res =*/ [frame load16];
    
    while ([frame position] < [frame length])
    {
        NSString * name = [frame loadvle];
        NSString * value = [frame loadvle];
        
        if (handleCookies && ([name caseInsensitiveCompare:@"set-cookie"] == NSOrderedSame))
        {
            if (cookies == nil) cookies = [[NSMutableArray alloc]init];
            
            NSDictionary *cookieHeaders = @{ @"Set-Cookie": value };
            NSArray * a = [NSHTTPCookie cookiesWithResponseHeaderFields:cookieHeaders forURL:self.request.URL];
            if (a != nil) [cookies addObjectsFromArray:a];
        }
        
        if ((location == nil) && ([name caseInsensitiveCompare:@"location"] == NSOrderedSame))
            location = value;
        
        if ([name caseInsensitiveCompare:@"content-encoding"] == NSOrderedSame)
        {
            self->flags.compressedResponse = [value hasPrefix:@"deflate"] || [value hasPrefix:@"gzip"];
        }
        
        /* AT: Chunked parser is disabled because it is not handed by SeaCat gateway
         if (([name caseInsensitiveCompare:@"transfer-encoding"] == NSOrderedSame) && ([value caseInsensitiveCompare:@"chunked"] == NSOrderedSame))
         {
         // Response is in chunked transfer encoding -> enable parser
         chunked_parser = [SCChunkedParser new];
         continue;
         }
         */
        
        [headers setValue:value forKey:name];
    }

    if (handleCookies && (cookies != nil))
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:self.request.URL mainDocumentURL:self.request.mainDocumentURL];
    }

    if (self->flags.compressedResponse)
    {
        bzero(&zlibStream, sizeof(zlibStream));
        zlibStreamStatus = inflateInit2(&zlibStream, MAX_WBITS + 32);
    }
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[[self request] URL] statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:headers];
    
    // Handle redirection ...
    if (((status == 301) || (status == 302) || (status == 307)) && (location != nil))
    {
        // If location is missing scheme (starts with '//'), use scheme from current protocol
        if ([location hasPrefix:@"//"])
        {
                location = [NSString stringWithFormat:@"%@:%@", [[[self request] URL] scheme], location];
        }
        
        NSURL *url = [NSURL URLWithString:location];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
        
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
    else
    {
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    }

    if ((flags & SEACATCC_SPDY_FLAG_FIN) == SEACATCC_SPDY_FLAG_FIN) [self FLAG_FIN];
    
    return true; // Return frame back to pool
}


- (bool)receivedDataFrame:(SCFrame *)frame reactor:(SCReactor *)reactor frameLength:(uint16_t)length frameFlags:(uint8_t)flags
{
    // Called by stream factory when response body fames arrives
    if (length > 0)
    {
        if (self->flags.compressedResponse) {
            zlibStream.avail_in = (uInt)length;
            zlibStream.next_in = (frame.bytes+frame.position);
            
            while (zlibStreamStatus == Z_OK && (zlibStream.avail_in > 0 || zlibStream.avail_out == 0))
            {
                uint8_t *inflatedBytes = malloc(sizeof(uint8_t) * DECOMPRESSED_CHUNK_LENGTH);
                if (inflatedBytes == NULL) {
                    SCLOG_ERROR(@"error decompressing response data: malloc failed");
                    NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain
                                                                code:NSURLErrorCannotDecodeContentData
                                                            userInfo:nil];
                    //TODO: [self closeWithError:error];
                    return true;
                }
                
                zlibStream.avail_out = DECOMPRESSED_CHUNK_LENGTH;
                zlibStream.next_out = inflatedBytes;
                zlibStreamStatus = inflate(&zlibStream, Z_SYNC_FLUSH);
                
                NSMutableData *inflatedData = [[NSMutableData alloc] initWithBytesNoCopy:inflatedBytes length:DECOMPRESSED_CHUNK_LENGTH freeWhenDone:YES];
                NSUInteger inflatedLength = DECOMPRESSED_CHUNK_LENGTH - zlibStream.avail_out;
                inflatedData.length = inflatedLength;
                if (inflatedLength > 0) {
                    [[self client] URLProtocol:self didLoadData:inflatedData];
                }
                
                // This can happen if the decompressed data is size N * DECOMPRESSED_CHUNK_LENGTH,
                // in which case we had to make an additional call to inflate() despite there being
                // no more input to ensure there wasn't any pending output in the zlib stream.
                if (zlibStreamStatus == Z_BUF_ERROR) {
                    zlibStreamStatus = Z_OK;
                    break;
                }
            }
            
            if (zlibStreamStatus != Z_OK && zlibStreamStatus != Z_STREAM_END) {
                SCLOG_ERROR(@"error decompressing response data: bad z_stream state");
                NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain
                                                            code:NSURLErrorCannotDecodeContentData
                                                        userInfo:nil];
                //TODO: [self closeWithError:error];
                return true;
            }
        }
        else
        {
            NSData * data = [NSData dataWithBytes:(frame.bytes+frame.position) length:length];
            [[self client] URLProtocol:self didLoadData:data];
        }
    }

    if ((flags & SEACATCC_SPDY_FLAG_FIN) == SEACATCC_SPDY_FLAG_FIN) [self FLAG_FIN];

    return true; // Return frame back to pool
}


- (bool)receivedSPD3_RST_STREAM:(SCFrame *)frame reactor:(SCReactor *)reactor frameVersionType:(uint32_t)versiontype frameLength:(uint16_t)lenght frameFlags:(uint8_t)flags
{
    // Called by stream factory when stream is reset by a server/gateway
    NSLog(@"SCURLProtocol receivedSPD3_RST_STREAM !");
    
    return true; // Return frame back to pool
}


- (void)FLAG_FIN
{
    if (flags.responseFin != YES)
    {
        // Called when received flag fin
        [[self client] URLProtocolDidFinishLoading:self];
        
        flags.responseFin = YES;
    }
}


- (void)reset
{
    NSLog(@"SCURLProtocol reset  !");

    // Called by stream factory when this stream is not valid any longer
}

@end
