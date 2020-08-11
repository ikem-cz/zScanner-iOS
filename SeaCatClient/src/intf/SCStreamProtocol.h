//
//  SCStreamProtocol.h
//  SeaCatClient
//
//  Created by Ales Teska on 16.4.18.
//

#import <Foundation/Foundation.h>

@class SCFrame;
@class SCReactor;

@protocol SCStreamProtocol <NSObject>

-(void)reset;

-(bool)receivedALX1_SYN_REPLY:(SCFrame *)frame reactor:(SCReactor *)reactor frameVersionType:(uint32_t)versiontype frameLength:(uint16_t)length frameFlags:(uint8_t)flags;
-(bool)receivedSPD3_RST_STREAM:(SCFrame *)frame reactor:(SCReactor *)reactor frameVersionType:(uint32_t)versiontype frameLength:(uint16_t)length frameFlags:(uint8_t)flags;
-(bool)receivedDataFrame:(SCFrame *)frame reactor:(SCReactor *)reactor frameLength:(uint16_t)length frameFlags:(uint8_t)flags;

@end
