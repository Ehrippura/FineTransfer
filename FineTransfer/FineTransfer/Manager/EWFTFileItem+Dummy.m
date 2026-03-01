//
//  EWFTFileItem+Dummy.m
//  FineTransfer
//

#import "EWFTFileItem+Dummy.h"
#import "EWFTFileItem+Private.h"
#import <MTP/MTP.h>

@implementation EWFTFileItem (Dummy)

+ (instancetype)dummyFileWithName:(NSString *)filename filesize:(uint64_t)filesize {
    LIBMTP_file_t file = {0};
    file.filename = (char *)filename.UTF8String;
    file.filesize = filesize;
    file.filetype = LIBMTP_FILETYPE_UNKNOWN;
    return [[self alloc] initWithMTPFile:&file];
}

+ (instancetype)dummyFolderWithName:(NSString *)name {
    LIBMTP_file_t file = {0};
    file.filename = (char *)name.UTF8String;
    file.filesize = 0;
    file.filetype = LIBMTP_FILETYPE_FOLDER;
    return [[self alloc] initWithMTPFile:&file];
}

@end
