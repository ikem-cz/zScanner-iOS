//
//  SCPingFactory.h
//  SeaCatClient
//
//  Created by Ales Teska on 03/12/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SeaCatClient.h"
#import "SCFrameProviderProtocol.h"
#import "SCCntlFrameConsumerProtocol.h"

@class SCReactor;

@interface SCPingFactory : NSObject <SCCntlFrameConsumerProtocol, SCFrameProviderProtocol>

-(SCPingFactory *)init;

-(void)ping:(id<SeaCatPingDelegate>)delegate reactor:(SCReactor *)reactor;

-(void)heartBeat:(double)now;
-(void)reset;

@end
