//
//  EWFTMTPError.m
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//


#import "EWFTMTPError.h"

NSErrorDomain const EWFTMTPErrorDomain = @"EWFTMTPErrorDomain";

static NSString *EWFTLocalizedDescriptionForErrorCode(EWFTMTPError code) {
    switch (code) {
        case EWFTMTPErrorNone:
            return nil;
        case EWFTMTPErrorGeneral:
            return NSLocalizedString(@"Something went wrong while communicating with the device. Please try again.", @"General MTP error");
        case EWFTMTPErrorPTPLayer:
            return NSLocalizedString(@"The device responded with an unexpected error. Try disconnecting and reconnecting it.", @"PTP layer error");
        case EWFTMTPErrorUSBLayer:
            return NSLocalizedString(@"There was a problem with the USB connection. Make sure the cable is securely connected and try again.", @"USB layer error");
        case EWFTMTPErrorMemoryAllocation:
            return NSLocalizedString(@"The app ran out of memory. Try closing other apps and try again.", @"Memory allocation error");
        case EWFTMTPErrorNoDeviceAttached:
            return NSLocalizedString(@"No device found. Please connect your device via USB and make sure it's set to file transfer mode.", @"No device attached error");
        case EWFTMTPErrorStorageFull:
            return NSLocalizedString(@"The device storage is full. Free up some space on the device and try again.", @"Storage full error");
        case EWFTMTPErrorConnecting:
            return NSLocalizedString(@"Couldn't connect to the device. Make sure it's unlocked and set to file transfer mode, then try again.", @"Connecting error");
        case EWFTMTPErrorCancelled:
            return NSLocalizedString(@"The operation was cancelled.", @"Cancelled error");
    }
    return NSLocalizedString(@"An unexpected error occurred. Please try again.", @"Unknown MTP error");
}

NSString *EWFTLocalizedDescription(EWFTMTPError code) {
    return EWFTLocalizedDescriptionForErrorCode(code);
}
