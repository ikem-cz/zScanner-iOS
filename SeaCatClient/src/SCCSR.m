//
//  SCCSR.m
//  SeaCatClient
//
//  Created by Ales Teska on 02/12/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import "SeaCatInternals.h"
#import <UIKit/UIKIT.h>

@implementation SCCSR
{
    NSMutableDictionary<NSString *, NSString *> * paramMap;
}

///

-(SCCSR *)init
{
    self = [super init];
    if (!self) return self;

    paramMap = [NSMutableDictionary<NSString *, NSString *> new];
    
    return self;
}

///

-(void)set:(NSString *)key value:(NSString *)value
{
    [paramMap setObject:value forKey:key];
}

-(NSString *)get:(NSString *)key
{
    return [paramMap objectForKey:key];
}

///

-(NSString *)getCountry { return [self get:@"C"]; }
-(void)setCountry:(NSString *) value { [self set:@"C" value:value]; }

-(NSString *)getState { return [self get:@"ST"]; }
-(void)setState:(NSString *) value { [self set:@"ST" value:value]; }

-(NSString *)getLocality { return [self get:@"L"]; }
-(void)setLocality:(NSString *) value { [self set:@"L" value:value]; }

-(NSString *)getOrganization { return [self get:@"O"]; }
-(void)setOrganization:(NSString *) value { [self set:@"O" value:value]; }

-(NSString *)getOrganizationUnit { return [self get:@"OU"]; }
-(void)setOrganizationUnit:(NSString *) value { [self set:@"OU" value:value]; }

-(NSString *)getCommonName { return [self get:@"CN"]; }
-(void)setCommonName:(NSString *) value { [self set:@"CN" value:value]; }

-(NSString *)getSurname { return [self get:@"SN"]; }
-(void)setSurname:(NSString *) value { [self set:@"SN" value:value]; }

-(NSString *)getGivenName { return [self get:@"GN"]; }
-(void)setGivenName:(NSString *) value { [self set:@"GN" value:value]; }

-(NSString *)getEmailAddress { return [self get:@"emailAddress"]; }
-(void)setEmailAddress:(NSString *) value { [self set:@"emailAddress" value:value]; }


-(NSString *)getUniqueIdentifier { return [self get:@"UID"]; }
-(void)setUniqueIdentifier:(NSString *) value { [self set:@"UID" value:value]; }

-(void)setUniqueIdentifier
{
	NSUUID *uuid = [[UIDevice currentDevice] identifierForVendor];
	uuid_t uuid_bytes;
	[uuid getUUIDBytes:uuid_bytes];

	NSString * uuid_str = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
		uuid_bytes[0], uuid_bytes[1], uuid_bytes[2], uuid_bytes[3],
		uuid_bytes[4], uuid_bytes[5], uuid_bytes[6], uuid_bytes[7],
		uuid_bytes[8], uuid_bytes[9], uuid_bytes[10], uuid_bytes[11],
		uuid_bytes[12], uuid_bytes[13], uuid_bytes[14], uuid_bytes[15]
	];
	
	[self setUniqueIdentifier:uuid_str];
}


///

-(void)setData:(NSString *)data
{
    [self set:@"description" value:data];
}

-(NSError *)setJsonData:(NSArray *)jsonObject
{
    NSError * error = NULL;
    NSData * data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];

    if (error != NULL)
    {
        SCLOG_WARN(@"CSR / setJsonData failed: %@", error);
        return error;
    }

    [self setData:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    
    return NULL;
}

///

-(bool)submit:(NSError **)out_error;
{
    unsigned long length = [paramMap count] * 2 + 1;

    const char * entries[length];
    entries[length - 1] = NULL;
    
    NSEnumerator *enumerator = [paramMap keyEnumerator];
    NSString * key;
    int pos = 0;
    while((key = [enumerator nextObject]))
    {
        NSString * value = [paramMap objectForKey:key];
        entries[pos*2 + 0] = [key UTF8String];
        entries[pos*2 + 1] = [value UTF8String];
        pos += 1;
    }
    assert((pos*2+1) == length);
	
    int rc = seacatcc_csrgen_worker(entries);
    NSError * error = SeaCatCheckRC(rc, @"seacatcc_csrgen_worker");
	if (error != NULL)
	{
		if (out_error != NULL) *out_error = error;
		return false;
	}

	if (out_error != NULL) *out_error = NULL;
	return true;
}

///

+(id<SeaCatCSRDelegate>)submitDefault
{
    SCCSRDefaultCSRDelegate * csrDelegate = [[SCCSRDefaultCSRDelegate alloc] init];
    return csrDelegate;
}

@end

@implementation SCCSRDefaultCSRDelegate

-(bool)submit:(NSError **)out_error;
{
    SCCSR * csr = [[SCCSR alloc] init];
    return [csr submit:out_error];
}

@end

