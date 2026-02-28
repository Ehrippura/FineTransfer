//
//  EWFTFileItem.m
//  FineTransfer
//

#import "EWFTFileItem+Private.h"

@implementation EWFTFileItem

- (instancetype)initWithMTPFile:(LIBMTP_file_t *)file {
    self = [super init];
    if (self) {
        _itemID    = file->item_id;
        _parentID  = file->parent_id;
        _storageID = file->storage_id;
        _filename  = file->filename ? [NSString stringWithUTF8String:file->filename] : nil;
        _filesize  = file->filesize;
        _folder    = (file->filetype == LIBMTP_FILETYPE_FOLDER);
        _modificationDate = (file->modificationdate != 0)
            ? [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)file->modificationdate]
            : nil;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ <itemID=%u, filename=%@, folder=%@, filesize=%llu>",
            [super description],
            _itemID,
            _filename ?: @"(null)",
            _folder ? @"YES" : @"NO",
            _filesize];
}

@end
