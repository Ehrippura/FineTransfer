//
//  EWFTStorage.m
//  FineTransfer
//

#import "EWFTStorage+Private.h"

@implementation EWFTStorage

- (instancetype)initWithMTPStorage:(LIBMTP_devicestorage_t *)storage {
    self = [super init];
    if (self) {
        _storageID          = storage->id;
        _maxCapacity        = storage->MaxCapacity;
        _freeSpaceInBytes   = storage->FreeSpaceInBytes;
        _storageDescription = storage->StorageDescription
            ? [NSString stringWithUTF8String:storage->StorageDescription]
            : nil;
        _volumeIdentifier   = storage->VolumeIdentifier
            ? [NSString stringWithUTF8String:storage->VolumeIdentifier]
            : nil;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ <storageID=%u, storageDescription=%@, maxCapacity=%llu, freeSpaceInBytes=%llu>",
            [super description],
            _storageID,
            _storageDescription ?: @"(null)",
            _maxCapacity,
            _freeSpaceInBytes];
}

@end
