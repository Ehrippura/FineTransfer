//
//  EWFTStorage+Private.h
//  FineTransfer
//

#import <Foundation/Foundation.h>
#import <MTP/MTP.h>
#import "EWFTStorage.h"

@interface EWFTStorage ()

- (instancetype)initWithMTPStorage:(LIBMTP_devicestorage_t *)storage NS_DESIGNATED_INITIALIZER;

@end
