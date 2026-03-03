//
//  EWFTMTPError.h
//  FineTransfer
//
//  Created by Wayne on 2026/2/28.
//

#import <Foundation/Foundation.h>

extern NSErrorDomain const EWFTMTPErrorDomain;

typedef NS_ERROR_ENUM(EWFTMTPErrorDomain, EWFTMTPError) {
    EWFTMTPErrorNone               = 0,
    EWFTMTPErrorGeneral            = 1,
    EWFTMTPErrorPTPLayer           = 2,
    EWFTMTPErrorUSBLayer           = 3,
    EWFTMTPErrorMemoryAllocation   = 4,
    EWFTMTPErrorNoDeviceAttached   = 5,
    EWFTMTPErrorStorageFull        = 6,
    EWFTMTPErrorConnecting         = 7,
    EWFTMTPErrorCancelled          = 8,
};
