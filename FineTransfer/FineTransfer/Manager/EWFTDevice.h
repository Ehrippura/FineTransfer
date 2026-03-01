//
//  EWFTDevice.h
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
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

/**
 * Returns the contents of a folder on the MTP device.
 *
 * @param folderID   The MTP object ID of the folder to list.
 *                   Use @c EWFDeviceRootFolderID to list the root folder.
 * @param storageID  The MTP storage ID that contains the folder.
 * @param error      On failure, set to an NSError describing the problem.
 * @return An array of file items in the folder, or @c nil if an error occurred.
 */
- (nullable NSArray<EWFTFileItem *> *)contentsOfFolderWithID:(uint32_t)folderID
                                                   storageID:(uint32_t)storageID
                                                       error:(NSError **)error
    NS_SWIFT_NAME(contents(folderID:storageID:));

/**
 * Downloads a file from the MTP device to a local destination.
 *
 * The returned NSProgress allows callers to:
 *   - Observe progress via KVO on fractionCompleted / completedUnitCount
 *   - Cancel the transfer by calling [progress cancel]
 *
 * Progress updates and the completion handler are always delivered on the main queue.
 *
 * @param fileID          The MTP object ID of the file to download.
 * @param destinationURL  A file:// URL for the desired local path.
 * @param completionHandler  Called on the main queue when the transfer finishes.
 *                           error is nil on success; EWFTMTPErrorCancelled on cancellation.
 * @return An NSProgress instance (indeterminate total until first callback fires).
 */
- (NSProgress *)downloadFileWithID:(uint32_t)fileID
                     toDestination:(NSURL *)destinationURL
               completionHandler:(void (^)(NSError * _Nullable error))completionHandler
    NS_SWIFT_NAME(downloadFile(id:to:completion:));

@end

NS_ASSUME_NONNULL_END
