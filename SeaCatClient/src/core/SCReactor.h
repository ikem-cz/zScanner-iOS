//
//  Reactor.h
//  SeaCatClient
//
//  Created by Ales Teska on 30/11/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCPingFactory;
@class SCStreamFactory;
@class SCFramePool;

#import "SCFrameProviderProtocol.h"
#import "../utils/Reachability.h"

@interface SCReactor : NSObject

@property (readonly) SCPingFactory * pingFactory;
@property (readonly) SCStreamFactory * streamFactory;
@property (readonly) SCFramePool * framePool;
@property (readwrite) id<SeaCatCSRDelegate> CSRDelegate;
@property (readonly) NSString * lastState;
@property (readonly) NSString * clientTag;
@property (readonly) NSString * clientId;

@property (nonatomic) Reachability *networkReachability;

-(SCReactor *)init:(NSString *)appId;

-(void)start;

-(void)registerFrameProvider:(id<SCFrameProviderProtocol>)provider single:(bool)single;

-(void)postNotificationName:(NSString *)notificationName;

@end

extern SCReactor * SeaCatReactor;
