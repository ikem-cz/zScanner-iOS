//
//  SeaCatPlugin.h
//  SeaCatClient
//
//  Created by Ales Teska on 26.9.17.
//  Copyright © 2015-2017 TeskaLabs. All rights reserved.
//

@interface SeaCatPlugin : NSObject

- (instancetype)init;
- (NSDictionary *)getCharacteristics;

+ (void)commitCharacteristics;

@end
