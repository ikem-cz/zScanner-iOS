//
//  SeaCatPlugin.m
//  SeaCatClient
//
//  Created by Ales Teska on 26.9.17.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

#import "SeaCatInternals.h"

static NSMutableArray * SeaCatPlugins = nil;

@implementation SeaCatPlugin

- (instancetype)init
{
    self = [super init];
    if (self == nil) return nil;

    if (SeaCatPlugins == nil) SeaCatPlugins = [NSMutableArray new];
    [SeaCatPlugins addObject:self];

    return self;
}

+ (void)commitCharacteristics
{
    NSMutableDictionary * characteristics = [NSMutableDictionary new];

    for(id plugin in SeaCatPlugins)
    {
        if (![plugin isKindOfClass:[SeaCatPlugin class]])
        {
            NSLog(@"%@ is not SeaCatPlugin", plugin);
            continue;
        }
        NSDictionary * pchrs = [plugin getCharacteristics];
        if (pchrs == nil) continue;
        [characteristics addEntriesFromDictionary:pchrs];
    }
    
//TODO:
//    "pln": sys.implementation.name,
//    "pli": sys.api_version,
//    "plv": sys.version,
//    "plb": sys.platform

//    memset(hwS_buf, '\0', sizeof(hwS_buf));
//    seacatcc_macos_ioreg(hwS_buf, CFSTR("serial-number"));
//    memset(hwb_buf, '\0', sizeof(hwb_buf));
//    seacatcc_macos_ioreg(hwb_buf, CFSTR("board-id"));

//    // Add platform characteristics
//    chrs.add(String.format("%s\037%s", "plv", Build.VERSION.RELEASE));
//    chrs.add(String.format("%s\037%s", "pls", Build.VERSION.SDK_INT));
//    chrs.add(String.format("%s\037%s", "pli", Build.VERSION.INCREMENTAL));
//    chrs.add(String.format("%s\037%s", "plB", Build.BRAND));
//    chrs.add(String.format("%s\037%s", "plf", Build.FINGERPRINT));
//    chrs.add(String.format("%s\037%s", "plI", Build.ID));
//    chrs.add(String.format("%s\037%s", "plm", Build.MANUFACTURER));
//    chrs.add(String.format("%s\037%s", "plM", Build.MODEL));
//    chrs.add(String.format("%s\037%s", "plp", Build.PRODUCT));
//    chrs.add(String.format("%s\037%s", "plt", Build.TAGS));
//    chrs.add(String.format("%s\037%s", "plT", Build.TYPE));
//    chrs.add(String.format("%s\037%s", "plU", Secure.getString(context.getContentResolver(), Secure.ANDROID_ID)));
//
//    // Add hardware characteristics
//    chrs.add(String.format("%s\037%s", "hwb", Build.BOARD));
//    chrs.add(String.format("%s\037%s", "hwd", Build.DEVICE));
//    chrs.add(String.format("%s\037%s", "hwS", Build.SERIAL));
//
//    DisplayMetrics dm = Resources.getSystem().getDisplayMetrics();
//    chrs.add(String.format("%s\037%sx%s", "dpr", dm.widthPixels, dm.heightPixels));
//    chrs.add(String.format("%s\037%s", "dpi", dm.densityDpi));
//    chrs.add(String.format("%s\037%s", "dpden", dm.density));
//    chrs.add(String.format("%s\037%s", "dpxdpi", dm.xdpi));
//    chrs.add(String.format("%s\037%s", "dpydpi", dm.ydpi));
//
//    PackageInfo pInfo = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
//    chrs.add(String.format("%s\037%s", "apN", pInfo.versionName));
//    chrs.add(String.format("%s\037%s", "apV", pInfo.versionCode));

    if ([SCDeviceSecurity isSimulator])
    {
        [characteristics setValue:@"simulator" forKey:@"hwd"]; // Simulator
    }
    
    const char * characteristics_c[[characteristics count]+1];
    int i=0;
    for (NSString* key in characteristics)
    {
        characteristics_c[i] = [[NSString stringWithFormat:@"%@\037%@", key, [characteristics objectForKey:key]] UTF8String];
        i += 1;
    }
    characteristics_c[i] = NULL; // Final terminator
    seacatcc_characteristics_store(characteristics_c);
}

@end

