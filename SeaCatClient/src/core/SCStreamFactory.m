//
//  SCStreamFactory.m
//  SeaCatiOSClient
//
//  Created by Ales Teska on 16.4.18.
//

#import "SeaCatInternals.h"
#import "SCStreamFactory.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
#include <libkern/OSAtomic.h>
#else
#include <stdatomic.h>
#endif

@implementation SCStreamFactory
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
    volatile int32_t idSequence;
#else
    atomic_int idSequence;
#endif
    
    NSMutableDictionary<NSNumber *, id<SCStreamProtocol>> * streams;
}

-(SCStreamFactory *)init
{
    self = [super init];
    if (!self) return self;
    
    idSequence = 1;
    streams = [NSMutableDictionary<NSNumber *, id<SCStreamProtocol>> new];
    
    return self;
}


-(int32_t)registerStream:(id<SCStreamProtocol>)stream
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
    int32_t streamId = OSAtomicAdd32(2, &idSequence) - 2;
#else
    int32_t streamId = atomic_fetch_add(&idSequence, 2);
#endif

    [streams setObject:stream forKey:[NSNumber numberWithUnsignedInteger:streamId]];

    return streamId;
}

-(void)unregisterStream:(int32_t)streamId
{
    NSNumber * streamIdKey = [NSNumber numberWithUnsignedInteger:streamId];
    [streams removeObjectForKey:streamIdKey];
}


- (bool)receivedControlFrame:(SCFrame *)frame reactor:(SCReactor *)reactor frameVersionType:(uint32_t)versiontype frameLength:(uint16_t)lenght frameFlags:(uint8_t)flags
{    
    // Get stream id from a frame (should be a next one, just at the position
    int32_t streamId = [frame load32];

    NSNumber * streamIdKey = [NSNumber numberWithUnsignedInteger:streamId];
    id<SCStreamProtocol> stream = [streams objectForKey:streamIdKey];
    if (stream == nil)
    {
        SCLOG_WARN(@"Received control frame for stream $@ but this stream is not registered", streamId);
        //TODO: Send reset frame to gateway
        return true;
    }

    switch (versiontype) {
        case (SEACATCC_SPDY_CNTL_FRAME_VERSION_ALX1 << 16) | SEACATCC_SPDY_CNTL_TYPE_SYN_REPLY:
            return [stream receivedALX1_SYN_REPLY:frame reactor:reactor frameVersionType:versiontype frameLength:lenght frameFlags:flags];

        case (SEACATCC_SPDY_CNTL_FRAME_VERSION_SPD3 << 16) | SEACATCC_SPDY_CNTL_TYPE_RST_STREAM:
            return [stream receivedSPD3_RST_STREAM:frame reactor:reactor frameVersionType:versiontype frameLength:lenght frameFlags:flags];

        default:
            SCLOG_ERROR(@"Unknown control frame in SCStreamFactory::receivedControlFrame: %X", versiontype);
            return true;
    }
}

-(bool)receivedDataFrame:(SCFrame *)frame reactor:(SCReactor *)reactor
{
    int32_t streamId = [frame load32];
    uint32_t frameLength = [frame load32];
    uint8_t frameFlags = (uint8_t)(frameLength >> 24);
    frameLength &= 0xffffff;
    
    NSNumber * streamIdKey = [NSNumber numberWithUnsignedInteger:streamId];
    id<SCStreamProtocol> stream = [streams objectForKey:streamIdKey];
    if (stream == nil)
    {
        SCLOG_WARN(@"Received control frame for stream $@ but this stream is not registered", streamId);
        //TODO: Send reset frame to gateway
        return true;
    }

    bool ret = [stream receivedDataFrame:frame reactor:reactor frameLength:frameLength frameFlags:frameFlags];
    
    if ((frameFlags & SEACATCC_SPDY_FLAG_FIN) == SEACATCC_SPDY_FLAG_FIN)
    {
        [self unregisterStream:streamId];
    }
    
    return ret;
}

@end

