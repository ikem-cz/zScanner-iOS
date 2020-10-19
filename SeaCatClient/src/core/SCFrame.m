//
//  SCFrame.m
//  SeaCatClient
//
//  Created by Ales Teska on 30/11/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import "SeaCatInternals.h"
#import "SCFrame.h"
#include "spdy.h"

///

@interface SCFrame ()

// Redeclare publicly read-only properties
@property (readwrite) uint8_t * bytes;
@property (readwrite) uint16_t capacity;
@property (readwrite) uint16_t position;
@property (readwrite) uint16_t length;

@end

///

@implementation SCFrame
{
    NSMutableData * data;
}

@synthesize bytes;
@synthesize capacity;
@synthesize position;
@synthesize length;

-(SCFrame *)initWithCapacity:(const uint16_t)in_capacity
{
    self = [super init];
    if (!self) return self;

    data = [NSMutableData dataWithCapacity:in_capacity];
    bytes = (uint8_t *)[data bytes];
	capacity = in_capacity;

	[self clear];

    return self;
}


-(void)clear
{
	position = 0;
	length = capacity;
}

-(void)flip
{
	length = position;
	position = 0;
}

-(void)flip:(const uint16_t)in_length
{
	length = in_length;
	position = 0;
}


-(void)advance:(uint16_t)delta_position
{
    assert((position+delta_position) <= length);
    position += delta_position;
}


-(void)store8:(const uint8_t)value
{
	assert((position+sizeof(value)) <= length);
	
	bytes[position++] = value;
}


-(void)store16:(const uint16_t)value
{
	assert((position+sizeof(value)) <= length);

	bytes[position++] = 0xFF & (value >> 8);
	bytes[position++] = 0xFF & value;
}

-(void)store24:(const uint32_t)value
{
	assert((position+sizeof(value)-1) <= length);
	
	bytes[position++] = 0xFF & (value >> 16);
	bytes[position++] = 0xFF & (value >> 8);
	bytes[position++] = 0xFF & value;
}

-(void)store32:(const uint32_t)value
{
	assert((position+sizeof(value)) <= length);

	bytes[position++] = 0xFF & (value >> 24);
	bytes[position++] = 0xFF & (value >> 16);
	bytes[position++] = 0xFF & (value >> 8);
	bytes[position++] = 0xFF & value;
}


-(void)store24at:(uint16_t)at_position value:(const uint32_t)value
{
    assert((at_position+sizeof(value)-1) <= length);

    bytes[at_position++] = 0xFF & (value >> 16);
    bytes[at_position++] = 0xFF & (value >> 8);
    bytes[at_position++] = 0xFF & value;
}

-(void)store32at:(uint16_t)at_position value:(const uint32_t)value
{
    assert((at_position+sizeof(value)) <= length);
    
    bytes[at_position++] = 0xFF & (value >> 24);
    bytes[at_position++] = 0xFF & (value >> 16);
    bytes[at_position++] = 0xFF & (value >> 8);
    bytes[at_position++] = 0xFF & value;
}

-(void)storevle:(NSString *)value
{
    NSUInteger len = [value lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    assert(len <= 0xFFFF);

    assert((position+3+len) <= length);
    
    if (len >= 0xFA)
    {
        [self store8:0xFF];
        [self store16:len];
    } else {
        [self store8:len];
    }

    NSRange range = NSMakeRange(0, [value length]);
    [value getBytes:(bytes + position)
           maxLength:len usedLength:NULL
           encoding:NSUTF8StringEncoding
           options:NSStringEncodingConversionAllowLossy
           range:range
           remainingRange:NULL
    ];

    position += len;
}

-(uint8_t)load8
{
    assert((position+sizeof(uint8_t)) <= length);
    return bytes[position++];
}

-(uint32_t)load16
{
    uint32_t ret = 0;
    assert((position+sizeof(uint32_t)) <= length);
    
    ret |= bytes[position++];
    ret <<= 8;
    ret |= bytes[position++];

    return ret;
}

-(uint32_t)load32
{
	uint32_t ret = 0;
	assert((position+sizeof(uint32_t)) <= length);
	
	ret |= bytes[position++];
	ret <<= 8;
	ret |= bytes[position++];
	ret <<= 8;
	ret |= bytes[position++];
	ret <<= 8;
	ret |= bytes[position++];

	return ret;
}

-(NSString *)loadvle
{
    int length;

    uint8_t length8 = [self load8];
    if (length8 == 0xFF)
    {
        length = [self load16];
    } else {
        length = length8;
        
    }

    NSString * ret = [[NSString alloc] initWithBytes:(bytes+position) length:length encoding:NSUTF8StringEncoding];
    position += length;
    
    return ret;
}


-(uint8_t)get8at:(const uint8_t)in_position
{
	assert(in_position <= length);
	return bytes[in_position];
}


- (void)buildSPD3Ping:(const int32_t)pingId
{
	// It is SPDY v3 control frame
	[self store16:(0x8000 | SEACATCC_SPDY_CNTL_FRAME_VERSION_SPD3)];
	
	// Type
	[self store16:SEACATCC_SPDY_CNTL_TYPE_PING];
	
	// Flags
	[self store8:0];
	
	// Length
	[self store24:4];
	
	// Ping ID
	[self store32:pingId];
}


-(void)buildALX1_SYN_STREAM:(NSURLRequest *)request streamId:(const int32_t)streamId fin_flag:(bool)in_fin_flag priority:(uint8_t)priority
{

    // It is SPDY v3 control frame
    [self store16:(0x8000 | SEACATCC_SPDY_CNTL_FRAME_VERSION_ALX1)];
    
    // Type
    [self store16:SEACATCC_SPDY_CNTL_TYPE_SYN_STREAM];
    
    // Flags
    [self store8:in_fin_flag ? SEACATCC_SPDY_FLAG_FIN : 0x00];
    
    // Length
    uint16_t length_position = position;
    [self store24:0xF1F2F3]; // Temporary placeholder -> ALX1_SYN_STREAM_setStreamId

    
    // Stream-ID
    [self store32:streamId];

    // Associated-To-Stream-ID - not used
    [self store32:0];

    
    // Priority
    [self store8:(priority & 0x07)<<5];

    
    // Slot (reserved)
    [self store8:0];

    
    // Path
    NSURL * url = [request URL];
    if ([[url host] hasSuffix:SeaCatHostSuffix])
    {
        [self storevle:[[url host] stringByDeletingPathExtension]];
    }
    else
    {
        [self storevle:[url host]];
    }
    
    
    // Method
    [self storevle:[request HTTPMethod]];

    
    // Path
    NSString * path = nil;
    NSString * url_res_spec = [url resourceSpecifier];
    NSRange r = [url_res_spec rangeOfString:@"/" options:NSLiteralSearch range:NSMakeRange(3, [url_res_spec length]-3)];
    if (r.location == NSNotFound)
    {
        SCLOG_WARN(@"Falling back to old URL handling method - please contact support and send them this message (resourceSpecifier: '%@')", url);
        NSMutableString * ms_path = [NSMutableString stringWithString:[[url relativePath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if ([url parameterString] != nil) [ms_path appendFormat:@";%@", [url parameterString]];
        if ([url query] != nil) [ms_path appendFormat:@"?%@", [url query]];
        path = [NSString stringWithString:ms_path];
    }
    else
    {
        path = [url_res_spec substringFromIndex:r.location];
        //TODO: Consider encoding of spaces into %20 etc.
    }
    [self storevle:path];
    
    //Adding X-Seacat-Client HTTP header
    [self storevle:@"X-SC-SDK"];
    [self storevle:@"ios"];
    
    __block bool content_length_found = false;
    __block bool content_type_found = false;
    
    // Add cookies
    if (request.HTTPShouldHandleCookies)
    {
        NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
        if (cookies != nil)
        {
            NSDictionary * cookieDict = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
            
            [cookieDict enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSString * value, BOOL *stop)
             {
                 [self storevle:key];
                 [self storevle:value];
             }];
        }
    }
    
    // Name/Value headers
    [[request allHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSString * value, BOOL *stop)
     {
         if ([key caseInsensitiveCompare:@"Content-Type"] == NSOrderedSame) content_type_found = true;
         if ([key caseInsensitiveCompare:@"Content-Length"] == NSOrderedSame) content_length_found = true;
         if (([key caseInsensitiveCompare:@"Cookies"] == NSOrderedSame) && (request.HTTPShouldHandleCookies)) return; // Skip cookies added into header directly
         
         // TODO: Filter out some keys - e.g. 'Host'
         [self storevle:key];
         [self storevle:value];
     }];
    
    // If Content-Length is not found and there is a HTTPBody, add that to a header
    if ((!content_length_found) && ([request HTTPBody] != nil))
    {
        [self storevle:@"Content-Length"];
        [self storevle:[NSString stringWithFormat:@"%lu", (unsigned long)[[request HTTPBody] length]]];
    }
    
    // POST method requires Content-Type to be set
    //TODO: Find where this requirement is specified
    if (([[request HTTPMethod] isEqualToString:@"POST"]) && (content_type_found == false))
    {
        [self storevle:@"Content-Type"];
        [self storevle:@"application/x-www-form-urlencoded"];
    }

    [self store24at:length_position value:(position - SEACATCC_SPDY_HEADER_SIZE)];
}


@end
