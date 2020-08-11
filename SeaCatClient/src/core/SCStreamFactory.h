//
//  SCStreamFactory.h
//  SeaCatClient
//
//  Created by Ales Teska on 16.4.18.
//


#import <Foundation/Foundation.h>
#import "SCStreamProtocol.h"
#import "SCCntlFrameConsumerProtocol.h"

@interface SCStreamFactory : NSObject <SCCntlFrameConsumerProtocol>

-(SCStreamFactory *)init;
-(int32_t)registerStream:(id<SCStreamProtocol>)stream;

-(bool)receivedDataFrame:(SCFrame *)frame reactor:(SCReactor *)reactor;

@end
