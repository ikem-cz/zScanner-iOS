//
//  Errors.m
//  SeaCatClient
//
//  Created by Ales Teska on 30/11/15.
//  Copyright © 2015 TeskaLabs. All rights reserved.
//

// Good reading is here: http://nshipster.com/nserror/

#import "SeaCatInternals.h"

NSString * SeaCatErrorDomain = @"SeaCatErrorDomain";
NSString * SeaCatErrorMessagesTableName = @"SeaCatErrorMessages";

NSError * SeaCatCheckRC(int rc, NSString * message)
{
	if (rc == SEACATCC_RC_OK) return NULL; // No error

    return [NSError
		errorWithDomain: SeaCatErrorDomain
		code: rc
		userInfo: @{
			NSLocalizedDescriptionKey: NSLocalizedString(message, SeaCatErrorMessagesTableName),
			NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"SeaCat C-Core client was not successful.", nil),
		}
	];
}


NSError * SeaCatError(enum SeaCat_ErrorCodes error_code, NSString * message)
{
    return [NSError
        errorWithDomain: SeaCatErrorDomain
        code: error_code
        userInfo: @{
            NSLocalizedDescriptionKey: NSLocalizedString(message, SeaCatErrorMessagesTableName),
        }
    ];
}
