//
//  EWFTStorage.h
//  FineTransfer
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MTPStorage)
@interface EWFTStorage : NSObject

/// Unique MTP storage ID.
@property (nonatomic, readonly) uint32_t storageID;

/// Human-readable description of the storage (e.g. "Internal storage").
@property (nonatomic, copy, readonly, nullable) NSString *storageDescription;

/// Volume identifier string.
@property (nonatomic, copy, readonly, nullable) NSString *volumeIdentifier;

/// Total capacity of the storage in bytes.
@property (nonatomic, readonly) uint64_t maxCapacity;

/// Free space remaining in the storage in bytes.
@property (nonatomic, readonly) uint64_t freeSpaceInBytes;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
