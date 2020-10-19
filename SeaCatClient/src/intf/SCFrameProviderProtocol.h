//
//  SCFrameProviderProtocol.h
//  SeaCatClient
//
//  Created by Ales Teska on 03/12/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCFrame;
@class SCReactor;

@protocol SCFrameProviderProtocol <NSObject>

-(SCFrame *)buildFrame:(bool *)keep reactor:(SCReactor *)reactor;
//TODO: -(int)getFrameProviderPriority;

@end
