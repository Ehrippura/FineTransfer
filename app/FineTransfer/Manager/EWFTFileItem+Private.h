//
//  EWFTFileItem+Private.h
//  FineTransfer
//

#import <Foundation/Foundation.h>
#import <MTP/MTP.h>
#import "EWFTFileItem.h"

@interface EWFTFileItem ()

- (instancetype)initWithMTPFile:(LIBMTP_file_t *)file NS_DESIGNATED_INITIALIZER;

@end
