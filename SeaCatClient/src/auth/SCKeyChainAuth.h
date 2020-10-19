//
//  KeyChainAuth.h
//  SeaCatClient
//
//  Created by Ales Teska on 29.5.18.
//

#import <Foundation/Foundation.h>

@interface SCKeyChainAuth : NSObject

-(void)startAuth:(SCReactor *)reactor;
-(void)deauth:(SCReactor *)reactor;

@end
