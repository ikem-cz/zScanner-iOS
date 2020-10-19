//
//  SCFramePool.m
//  SeaCatClient
//
//  Created by Ales Teska on 30/11/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import "SeaCatInternals.h"
#import "SCFramePool.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
#include <libkern/OSAtomic.h>
#else
#include <stdatomic.h>
#endif

@implementation SCFramePool
{
    NSMutableArray * stack;

    int32_t lowWaterMark;
    int32_t highWaterMark;
    uint32_t frameCapacity;

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
    volatile int32_t totalCount;
#else
    atomic_uint totalCount;
#endif
}


-(SCFramePool *)init
{
    self = [super init];
	if (!self) return self;

    stack = [[NSMutableArray alloc] init];
    
    lowWaterMark = 16;     //TODO: Read this from configuration
    highWaterMark = 40960; //TODO: Read this from configuration
    frameCapacity = 16*1024;
    totalCount = 0;

    return self;
}


-(SCFrame *)borrow:(NSString *)reason
{
    SCFrame * frame = NULL;

    @synchronized (stack)
    {
        frame = [stack lastObject];
        if (frame != NULL) [stack removeLastObject];
    }

    if (frame == NULL)
    {
        // stack is empty ...
        frame = [self createFrame];

        //TODO: if (totalCount.intValue() >= highWaterMark) throw new IOException("No more available frames in the pool.");
    }

    SCLOG_DEBUG(@"FramePool stats / size:%u capacity:%u", [self size], [self capacity]);
    
    return frame;
}


-(void)giveBack:(SCFrame *)frame
{
    assert(frame != NULL);

    if (totalCount > lowWaterMark)
    {
        [frame clear];
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
        OSAtomicDecrement32(&totalCount);
#else
        atomic_fetch_sub(&totalCount, 1);
#endif

        // Discard frame
    }
    
    else
    {
        [frame clear];
        @synchronized(stack) {
            [stack addObject:frame];
        }
    }
}


-(SCFrame *)createFrame
{
    SCFrame * frame = [[SCFrame alloc] initWithCapacity:frameCapacity];
    if (frame != NULL)
    {
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
        OSAtomicIncrement32(&totalCount);
#else
        atomic_fetch_add(&totalCount, 1);
#endif
    }
    return frame;
}


-(NSUInteger)size
{
    return [stack count];
}


-(NSUInteger)capacity
{
    return totalCount;
}


-(void)heartBeat:(double)now
{
/*
	static double before = 0;
	if (now > (before + 5))
	{
		before = now;
		SCLOG_DEBUG(@"FramePool stats / size:%u capacity:%u", [self size], [self capacity]);
	}
*/
}

@end
