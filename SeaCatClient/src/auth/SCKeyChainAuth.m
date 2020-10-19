//
//  KeyChainAuth.m
//  SeaCatiOSClient
//
//  Copyright © 2018 TeskaLabs. All rights reserved.
//

#import "SeaCatInternals.h"
#include <CommonCrypto/CommonDigest.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <UIKit/UIKit.h>
#include <libkern/OSAtomic.h>

NSString * SCAuthLocalizedReason = nil;

@implementation SCKeyChainAuth
{
    NSData* tag;
    id requireUserAuth;
    int32_t authSemaphore;
}

- (instancetype)init
{
    if (self = [super init])
    {   
        tag = [@"com.teskalabs.seacat.masterkey" dataUsingEncoding:NSUTF8StringEncoding];

        NSBundle *bundle = [NSBundle mainBundle];
        NSDictionary *info = [bundle infoDictionary];
        requireUserAuth = [info objectForKey:@"seacat.require_user_auth"];
        if ((requireUserAuth) && (![SCDeviceSecurity hasBiometrics]))
            requireUserAuth = FALSE;
        
        authSemaphore = 0;
    }
    return self;
}

-(void)startAuth:(SCReactor *)reactor
{
    CFErrorRef error;

    int32_t counter = OSAtomicIncrement32(&self->authSemaphore);
    if (counter > 1)
    {
        // Something already uses auth
        OSAtomicDecrement32(&self->authSemaphore);
        return;
    }
    
    NSDictionary *getquery = @{
        (id)kSecClass: (id)kSecClassKey,
        (id)kSecAttrApplicationTag: tag,
        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
        (id)kSecReturnRef: @YES,
    };
    
    SecKeyRef key = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)getquery, (CFTypeRef *)&key);
    if (status == errSecItemNotFound)
    {
        NSDictionary* attributes = nil;
        
        if ([SCDeviceSecurity hasSecureEnclave])
        {
            // Variant with Secure Enclave
            SecAccessControlRef access = SecAccessControlCreateWithFlags(
                 kCFAllocatorDefault,
                 kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                 kSecAccessControlPrivateKeyUsage, //touchIDAny ?
                 NULL
            );

            attributes = @{
                (id)kSecAttrKeyType:             (id)kSecAttrKeyTypeECSECPrimeRandom,
                (id)kSecAttrKeySizeInBits:       @256,
                (id)kSecAttrTokenID:             (id)kSecAttrTokenIDSecureEnclave,
                (id)kSecPrivateKeyAttrs: @{
                    (id)kSecAttrIsPermanent:     @YES,
                    (id)kSecAttrApplicationTag:  tag,
                    (id)kSecAttrAccessControl:   (__bridge id)access,
                },
            };
        } else {
            SCLOG_WARN(@"No secure enclave detected, the security of the master private key is limmited.");
            // Variant with no Secure Enclave
            SecAccessControlRef access = SecAccessControlCreateWithFlags(
                 kCFAllocatorDefault,
                 kSecAttrAccessibleAlwaysThisDeviceOnly,
                 0,
                 NULL
             );

            attributes = @{
                (id)kSecAttrKeyType:             (id)kSecAttrKeyTypeEC,
                (id)kSecAttrKeySizeInBits:       @256,
                (id)kSecPrivateKeyAttrs: @{
                    (id)kSecAttrIsPermanent:     @YES,
                    (id)kSecAttrApplicationTag:  tag,
                    (id)kSecAttrAccessControl:   (__bridge id)access,
                },
            };
            
        }
        
        SCLOG_DEBUG(@"Generating master key ...");
        
        error = NULL;
        SecKeyRef privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, &error);
        if (!privateKey)
        {
            NSError *err = CFBridgingRelease(error);  // ARC takes ownership
            SCLOG_ERROR(@"Error when generating a master key in the secure enclave: %@", err);
            if (privateKey) { CFRelease(privateKey); }
            OSAtomicDecrement32(&self->authSemaphore);
            return;
        }
        
        SecKeyRef publicKey = SecKeyCopyPublicKey(privateKey);

        NSMutableData * plainText = [NSMutableData dataWithLength:SEACATCC_SECRET_KEY_LENGTH];
        status = SecRandomCopyBytes(kSecRandomDefault, SEACATCC_SECRET_KEY_LENGTH, plainText.mutableBytes);
        assert(status == 0);
        
        error = NULL;
        NSData * cypherText = CFBridgingRelease(
            SecKeyCreateEncryptedData(publicKey, kSecKeyAlgorithmECIESEncryptionStandardX963SHA256AESGCM, (CFDataRef)[NSData dataWithData:plainText], &error)
        );
        if (cypherText == nil)
        {
            NSError *err = CFBridgingRelease(error);  // ARC takes ownership
            SCLOG_ERROR(@"Error when encrypting a master key in the secure enclave: %@", err);
            if (privateKey) { CFRelease(privateKey); }
            if (publicKey) { CFRelease(privateKey); }
            OSAtomicDecrement32(&self->authSemaphore);
            return;
        }
        
        // Destroy the plain text
        [plainText resetBytesInRange:NSMakeRange(0, SEACATCC_SECRET_KEY_LENGTH)];
        
        if (publicKey) { CFRelease(publicKey); }
        if (privateKey) { CFRelease(privateKey); }

        // Store encrypted key in the keychain
        NSMutableDictionary *keychainData = [self _baseQuery];
        keychainData[(__bridge id)kSecAttrAccount] = tag;
        keychainData[(__bridge id)kSecValueData] = cypherText;
        
        SecItemDelete((__bridge CFDictionaryRef)keychainData);
        status = SecItemAdd((__bridge CFDictionaryRef)keychainData, NULL);
        assert(status == 0);
        
        // Retrieve a key from a secure enclave
        status = SecItemCopyMatching((__bridge CFDictionaryRef)getquery, (CFTypeRef *)&key);
        assert(status == 0);
    }
    
    NSString * state = [SeaCatClient getState];
    if ([state characterAtIndex:3] == 'Y')
    {
        // Already authotized;
        OSAtomicDecrement32(&self->authSemaphore);
        return;
    }
    
    if (requireUserAuth)
    {
        NSError *authError = nil;
        LAContext *myContext = [[LAContext alloc] init];
        
        LAPolicy policy = LAPolicyDeviceOwnerAuthentication;
    
        if (SCAuthLocalizedReason == nil)
            SCAuthLocalizedReason = @"Authorization needed.";
        
        if ([myContext canEvaluatePolicy:policy error:&authError]) {
            [myContext evaluatePolicy:policy
                localizedReason:SCAuthLocalizedReason
                reply:^(BOOL success, NSError *error) {
                    if (success) {
                        [self issueKey:key];
                        OSAtomicDecrement32(&self->authSemaphore);
                    } else {
                        switch (error.code) {
                            case LAErrorUserCancel:
                            case LAErrorSystemCancel:
                                OSAtomicDecrement32(&self->authSemaphore);
                                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                                    [SeaCatClient startAuth];
                                });
                                break;

                            case LAErrorTouchIDNotAvailable:
                            case LAErrorUserFallback:
                                SCLOG_WARN(@"Fallback from biometrics to a user authorization.");
                                OSAtomicDecrement32(&self->authSemaphore);
                                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                                    [SeaCatClient startAuth];
                                });
                                break;

                            default:
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                        message:error.description
                                        delegate:self
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil, nil];
                                    [alertView show];
                                });
                        }
                    }
                }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                    message:authError.description
                    delegate:self
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil, nil];
                [alertView show];
            });
        }
    }
    else {
        [self issueKey:key];
        OSAtomicDecrement32(&self->authSemaphore);
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    OSAtomicDecrement32(&self->authSemaphore);
    
    // Handle errors from a auth dialog by restarting the auth.
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [SeaCatClient startAuth];
    });
}

-(void)deauth:(SCReactor *)reactor
{
    seacatcc_secret_key_worker(NULL);
}


- (void) issueKey:(SecKeyRef)key
{
    OSStatus status;
    CFErrorRef error;
    
    assert(key != NULL);
    
    // Obtain encrypted key
    
    NSMutableDictionary *query = [self _baseQuery];
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    query[(__bridge id)kSecReturnAttributes] = @YES;
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecReturnRef] = @NO;
    query[(__bridge id)kSecReturnPersistentRef] = @NO;
    query[(__bridge id)kSecAttrAccount] = tag;
    
    CFTypeRef dataTypeRef = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataTypeRef);
    //TODO: What to do if encrypted secret key is not found?
    
    NSDictionary * keychainData = (__bridge NSDictionary *)dataTypeRef;
    NSData * cypherText = [keychainData objectForKey:(id)kSecValueData];
    
    error = NULL;
    NSData * plainText = CFBridgingRelease(
        SecKeyCreateDecryptedData(key, kSecKeyAlgorithmECIESEncryptionStandardX963SHA256AESGCM, (CFDataRef)cypherText, &error)
    );
    if (plainText == nil)
    {
        NSError *err = CFBridgingRelease(error);  // ARC takes ownership
        SCLOG_ERROR(@"Error when decrypting a master key: %@", err);
        return;
    }
    
    seacatcc_secret_key_worker([plainText bytes]);
}

- (NSMutableDictionary *)_baseQuery;
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    query[(__bridge id)kSecAttrService] =  @"com_teskalabs_seacat_keychain_sec_items";;
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    
    return query;
}

@end
