//
//  EWFTFileItem+Dummy.h
//  FineTransfer
//

#import "EWFTFileItem.h"

NS_ASSUME_NONNULL_BEGIN

/// Factory methods for creating dummy MTPFileItem instances in Swift Previews and tests.
@interface EWFTFileItem (Dummy)

+ (instancetype)dummyFileWithName:(NSString *)filename
                         filesize:(uint64_t)filesize
    NS_SWIFT_NAME(dummy(filename:filesize:));

+ (instancetype)dummyFolderWithName:(NSString *)name
    NS_SWIFT_NAME(dummyFolder(name:));

@end

NS_ASSUME_NONNULL_END
