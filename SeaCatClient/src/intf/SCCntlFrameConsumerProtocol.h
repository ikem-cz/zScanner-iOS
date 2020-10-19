//
//  SCCntlFrameConsumerProtocol.h
//  SeaCatClient
//
//  Created by Ales Teska on 04/12/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCFrame;
@class SCReactor;

@protocol SCCntlFrameConsumerProtocol <NSObject>

-(bool)receivedControlFrame:(SCFrame *)frame reactor:(SCReactor *)reactor frameVersionType:(uint32_t)versiontype frameLength:(uint16_t)lenght frameFlags:(uint8_t)flags;

@end
