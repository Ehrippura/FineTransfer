//
//  EWFTFileItem.h
//  FineTransfer
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MTPFileItem)
NS_SWIFT_SENDABLE
@interface EWFTFileItem : NSObject

@property (nonatomic, readonly) uint32_t itemID;
@property (nonatomic, readonly) uint32_t parentID;
@property (nonatomic, readonly) uint32_t storageID;
@property (nonatomic, copy, readonly, nullable) NSString *filename;
@property (nonatomic, readonly) uint64_t filesize;
@property (nonatomic, copy, readonly, nullable) NSDate *modificationDate;
@property (nonatomic, readonly, getter=isFolder) BOOL folder;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
