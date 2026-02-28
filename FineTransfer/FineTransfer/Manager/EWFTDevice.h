//
//  EWFTDevice.h
//  FineTransfer
//
//  Created by Wayne Lin on 2026/2/28.
//

#import <Foundation/Foundation.h>

@class EWFTFileItem;

NS_ASSUME_NONNULL_BEGIN

extern uint32_t const EWFDeviceRootFolderID NS_SWIFT_NAME(EWFTDevice.rootFolderID);

NS_SWIFT_NAME(MTPDevice)
@interface EWFTDevice : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *displayName;
@property (nonatomic, copy, readonly, nullable) NSString *manufacturer;
@property (nonatomic, copy, readonly, nullable) NSString *modelName;
@property (nonatomic, copy, readonly, nullable) NSString *serialNumber;

@property (nonatomic, readonly) uint32_t rootStorageID;

@property (nonatomic, readonly, getter=isConnected) BOOL connected;

- (instancetype)init NS_UNAVAILABLE;

- (void)disconnect;

- (nullable NSArray<EWFTFileItem *> *)contentsOfFolderWithID:(uint32_t)folderID
                                                   storageID:(uint32_t)storageID
                                                       error:(NSError **)error
    NS_SWIFT_NAME(contents(folderID:storageID:));

@end

NS_ASSUME_NONNULL_END
