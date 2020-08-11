//
//  SCURLProtocol.h
//  TeskaLabs SeaCat Client for iOS
//
//  Created by Ales Teska on 02/12/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "SeaCatClient.h"
#import "SCFrameProviderProtocol.h"
#import "SCCntlFrameConsumerProtocol.h"
#import "SCStreamProtocol.h"

@interface SCURLProtocol : NSURLProtocol <SCFrameProviderProtocol, SCStreamProtocol>

@property (readonly) int32_t streamId;

@end
