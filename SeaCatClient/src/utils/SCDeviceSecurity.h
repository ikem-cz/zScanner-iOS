//
//  SCDeviceSecurity.h
//  SeaCatiOSClient
//
//

#import <Foundation/Foundation.h>

@interface SCDeviceSecurity : NSObject

+ (bool) isSimulator;
+ (bool) hasBiometrics;
+ (bool) hasSecureEnclave;

@end
