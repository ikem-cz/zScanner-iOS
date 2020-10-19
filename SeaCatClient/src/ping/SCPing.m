//
//  SCPing.m
//  SeaCatClient
//
//  Created by Ales Teska on 03/12/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import "SeaCatInternals.h"
#import "SCPing.h"

@implementation SCPing
{
    int32_t pingId;
    double deadline; //TODO: Add support for deadline (skip&cancel objects that are behind deadline)
}

@synthesize delegate;


-(SCPing *)init:(id<SeaCatPingDelegate>)in_delegate
{
    self = [super init];
    if (!self) return self;

    pingId = 0;
    deadline = seacatcc_time() + 60.0;
	delegate = in_delegate;

    return self;
}


-(void) pong
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[delegate pong:pingId];
	});
}


-(void)setPingId:(int32_t)in_pingId{
	assert(pingId == 0);
	assert(in_pingId > 0);
	pingId = in_pingId;
}


-(void)cancel
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[delegate pingCanceled:pingId];
	});
}


-(bool)isExpired:(double)now
{
	return now >= deadline;
}


@end
