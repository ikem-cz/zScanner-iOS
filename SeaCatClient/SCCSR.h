//
//  SCCSR.h
//  TeskaLabs SeaCat Client for iOS
//
//  Created by Ales Teska on 02/12/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCCSR : NSObject

-(SCCSR *)init;

-(void)set:(NSString *)key value:(NSString *)value;
-(NSString *)get:(NSString *)key;

-(NSString *)getCountry;
-(void)setCountry:(NSString *) value;

-(NSString *)getState;
-(void)setState:(NSString *) value;

-(NSString *)getLocality;
-(void)setLocality:(NSString *) value;

-(NSString *)getOrganization;
-(void)setOrganization:(NSString *) value;

-(NSString *)getOrganizationUnit;
-(void)setOrganizationUnit:(NSString *) value;

-(NSString *)getCommonName;
-(void)setCommonName:(NSString *) value;

-(NSString *)getSurname;
-(void)setSurname:(NSString *) value;

-(NSString *)getGivenName;
-(void)setGivenName:(NSString *) value;

-(NSString *)getEmailAddress;
-(void)setEmailAddress:(NSString *) value;


-(NSString *)getUniqueIdentifier;
-(void)setUniqueIdentifier:(NSString *) value;
-(void)setUniqueIdentifier;


-(void)setData:(NSString *)data;
-(NSError *)setJsonData:(NSArray *)jsonObject;

///

-(bool)submit:(NSError **)error;

+(id<SeaCatCSRDelegate>)submitDefault;


@end

@interface SCCSRDefaultCSRDelegate : NSObject <SeaCatCSRDelegate>
-(bool)submit:(NSError **)out_error;
@end
