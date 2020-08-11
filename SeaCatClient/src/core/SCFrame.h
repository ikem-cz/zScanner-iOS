//
//  SCFrame.h
//  SeaCatClient
//
//  Created by Ales Teska on 30/11/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCFrame : NSObject

@property (readonly) uint8_t * bytes;
@property (readonly) uint16_t capacity;
@property (readonly) uint16_t position;
@property (readonly) uint16_t length;

-(SCFrame *)initWithCapacity:(const uint16_t)capacity;

-(void)flip;
-(void)flip:(const uint16_t)length;
-(void)clear;

-(void)store8:(const uint8_t)value;
-(void)store16:(const uint16_t)value;
-(void)store24:(const uint32_t)value;
-(void)store32:(const uint32_t)value;
-(void)store24at:(uint16_t)at_position value:(const uint32_t)value;
-(void)store32at:(uint16_t)at_position value:(const uint32_t)value;
-(void)storevle:(NSString *)value;

-(void)advance:(uint16_t)delta_position;

-(uint8_t)get8at:(const uint8_t)position;

-(uint8_t)load8;
-(uint32_t)load16;
-(uint32_t)load32;
-(NSString *)loadvle;

-(void)buildSPD3Ping:(const int32_t)pingId;
-(void)buildALX1_SYN_STREAM:(NSURLRequest *)request streamId:(const int32_t)streamId fin_flag:(bool)in_fin_flag priority:(uint8_t)priority;

@end
