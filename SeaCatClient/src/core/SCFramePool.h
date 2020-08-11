//
//  SCFramePool.h
//  SeaCatClient
//
//  Created by Ales Teska on 30/11/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCFrame.h"

@interface SCFramePool : NSObject

-(SCFramePool *)init;

-(SCFrame *)borrow:(NSString *)reason;
-(void)giveBack:(SCFrame *)frame;

-(NSUInteger)size;
-(NSUInteger)capacity;

-(void)heartBeat:(double)now;

@end
