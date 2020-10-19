//
//  SCDeviceSecurity.m
//  SeaCatiOSClient
//
//

#import "SeaCatInternals.h"
#import <LocalAuthentication/LocalAuthentication.h>

@implementation SCDeviceSecurity

+ (bool) hasSecureEnclave
{
    return ![self isSimulator] && [self hasBiometrics];
}

+ (bool) isSimulator
{
    return TARGET_OS_SIMULATOR == 1;
}

+ (bool) hasBiometrics
{
    LAContext * localAuthContext = [[LAContext alloc] init];
    NSError *authError = nil;
    
    if ([localAuthContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError])
    {
        return true;
    }
    
    if (@available(iOS 11.0, *)) {
        if (authError.code != LAErrorBiometryNotAvailable) {
            return true;
        }
    }
    
    if (authError.code != LAErrorTouchIDNotAvailable) {
        return true;
    }
    
    return false;
}



@end
