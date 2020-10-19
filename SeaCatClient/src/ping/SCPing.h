//
//  SCPing.h
//  SeaCatClient
//
//  Created by Ales Teska on 03/12/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SeaCatClient.h"

@interface SCPing : NSObject

@property (readonly) id<SeaCatPingDelegate> delegate;

-(SCPing *)init:(id<SeaCatPingDelegate>)delegate;

-(void)setPingId:(int32_t)pingId;

-(void)pong;
-(void)cancel;

-(bool)isExpired:(double)now;

@end
