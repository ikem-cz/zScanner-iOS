//
//  SCPingFactory.m
//  SeaCatClient
//
//  Created by Ales Teska on 03/12/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import "SeaCatInternals.h"
#import "SCPingFactory.h"
#import "SCPing.h"
#import "SCReactor.h"
#import "SCFramePool.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
#include <libkern/OSAtomic.h>
#else
#include <stdatomic.h>
#endif

@implementation SCPingFactory
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
    volatile int32_t idSequence;
#else
    atomic_int idSequence;
#endif

	NSMutableArray<SCPing *> * outboundPingQueue;
	NSMutableDictionary<NSNumber *, SCPing *> * waitingPingDict;
}

-(SCPingFactory *)init
{
	self = [super init];
	if (!self) return self;
	
	idSequence = 1;
	outboundPingQueue = [NSMutableArray<SCPing *> new];
	waitingPingDict = [NSMutableDictionary<NSNumber *, SCPing *> new];
	
	return self;
}

-(void)reset
{
    idSequence = 1;

    for (NSNumber * key in waitingPingDict)
    {
        SCPing * ping = [waitingPingDict objectForKey:key];
        [ping cancel];
    }
    [waitingPingDict removeAllObjects];

}

-(void)ping:(id<SeaCatPingDelegate>)delegate reactor:(SCReactor *)reactor
{
	SCPing * ping = [[SCPing alloc] init:delegate];
	@synchronized(outboundPingQueue) {
		[outboundPingQueue addObject:ping];
	}

	[reactor registerFrameProvider:self single:true];
}

-(SCFrame *)buildFrame:(bool *)keep reactor:(SCReactor *)reactor
{
	SCPing * ping = NULL;
	@synchronized(outboundPingQueue) {
		ping = [outboundPingQueue firstObject];
		if (ping != NULL) [outboundPingQueue removeObjectAtIndex:0];
	}

	if (ping == NULL)
	{
		*keep = false;
		return NULL;
	}
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
    int32_t pingId = OSAtomicAdd32(2, &idSequence) - 2;
#else
    int32_t pingId = atomic_fetch_add(&idSequence, 2);
#endif
	[ping setPingId:pingId];
	[waitingPingDict setObject:ping forKey:[NSNumber numberWithUnsignedInteger:pingId]];

	SCFrame * frame = [reactor.framePool borrow:@"PingFactory.ping"];
	[frame buildSPD3Ping:pingId];
	
	@synchronized(outboundPingQueue) {
		*keep = ([outboundPingQueue firstObject] != NULL);
	}

	return frame;
}


-(bool)receivedControlFrame:(SCFrame *)frame reactor:(SCReactor *)reactor frameVersionType:(uint32_t)versiontype frameLength:(uint16_t)lenght frameFlags:(uint8_t)flags
{
	uint32_t pingId = [frame load32];
	
	if ((pingId % 2) == 1)
	{
		// Pong frame received ...
		NSNumber * pingIdKey = [NSNumber numberWithUnsignedInteger:pingId];
		SCPing * ping = [waitingPingDict objectForKey:pingIdKey];
		if (ping != NULL)
		{
			[waitingPingDict removeObjectForKey:pingIdKey];
			[ping pong];
		}

		else
		{
			SCLOG_WARN(@"received pong with unknown ping id: %u", pingId);
		}		
	}
	
	else
	{
		//TODO: Send pong back to server
/*
		outboundPingQueue.add(new Pong(pingId));
		try {
			reactor.registerFrameProvider(this, true);
		} catch (Exception e) {
			// We can ignore error in this case, right?
		}
*/
	}

	return true;
}

-(void)heartBeat:(double)now
{
	for (NSNumber *key in [waitingPingDict allKeys])
	{
		SCPing * ping = [waitingPingDict objectForKey:key];
		assert(ping != NULL);
		if ([ping isExpired:now])
		{
			[waitingPingDict removeObjectForKey:key];
			[ping cancel];
		}
	}

	
	// Iterate from the end because we will be removing members
	for (unsigned long i = [outboundPingQueue count]; i > 0; i--)
	{
		SCPing * ping = [outboundPingQueue objectAtIndex:i-1];
		if ([ping isExpired:now])
		{
			[outboundPingQueue removeObjectAtIndex:i-1];
			[ping cancel];
		}
	}

}


@end
