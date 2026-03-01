//
//  EWFTDevice+Private.h
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//


#import <Foundation/Foundation.h>
#import <MTP/MTP.h>
#import "EWFTDevice.h"

@interface EWFTDevice()

- (instancetype)initWithDevice:(LIBMTP_mtpdevice_t *)device NS_DESIGNATED_INITIALIZER;

@end
