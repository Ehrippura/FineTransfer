//
//  EWFTDevice.h
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

#import <Foundation/Foundation.h>

@class EWFTFileItem;
@class EWFTStorage;

NS_ASSUME_NONNULL_BEGIN

extern uint32_t const EWFDeviceRootFolderID NS_SWIFT_NAME(EWFTDevice.rootFolderID);

NS_SWIFT_NAME(MTPDevice)
@interface EWFTDevice : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *displayName;
@property (nonatomic, copy, readonly, nullable) NSString *manufacturer;
@property (nonatomic, copy, readonly, nullable) NSString *modelName;
@property (nonatomic, copy, readonly, nullable) NSString *serialNumber;

@property (nonatomic, readonly) uint32_t busLocation;

/** All storages available on the device, in the order reported by the device. */
@property (nonatomic, copy, readonly) NSArray<EWFTStorage *> *storages;

@property (nonatomic, readonly, getter=isConnected) BOOL connected;

- (instancetype)init NS_UNAVAILABLE;

- (void)disconnect;

/**
 * Asynchronously returns the contents of a folder on the MTP device.
 *
 * Executes on the device's internal serial MTP queue and delivers the result
 * on the main queue via completionHandler.
 *
 * @param folderID           The MTP object ID of the folder to list.
 *                           Use @c EWFDeviceRootFolderID to list the root folder.
 * @param storageID          The MTP storage ID that contains the folder.
 * @param completionHandler  Called on the main queue with the items array (empty if folder
 *                           is empty, nil on error) and an NSError on failure.
 */
- (void)contentsOfFolderWithID:(uint32_t)folderID
                     storageID:(uint32_t)storageID
             completionHandler:(void (^)(NSArray<EWFTFileItem *> * _Nullable items,
                                         NSError * _Nullable error))completionHandler
    NS_SWIFT_ASYNC_NAME(contents(folderID:storageID:));

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
 *
 * ```swift
 * // start download
 * let progress = device.downloadFile(id: fileID, to: destinationURL) { error in
 *   if let error {
 *     // EWFTMTPErrorCancelled represented to cancelled by user
 *     print("failed:", error)
 *   } else {
 *     print("complete")
 *   }
 * }
 *
 * // monitoring progress using combine
 * progressCancellable = progress.publisher(for: \.fractionCompleted)
 *   .receive(on: RunLoop.main)
 *   .assign(to: \.downloadProgress, on: self)
 *
 * // cancel
 * progress.cancel()
 * ```
 */
- (NSProgress *)downloadFileWithID:(uint32_t)fileID
                     toDestination:(NSURL *)destinationURL
                 completionHandler:(void (^)(NSError * _Nullable error))completionHandler
    NS_SWIFT_NAME(downloadFile(id:to:completionHandler:));

/**
 * Uploads a local file to the MTP device.
 *
 * The returned NSProgress allows callers to observe progress and cancel the transfer.
 * Progress updates and the completion handler are always delivered on the main queue.
 *
 * @param sourceURL          A file:// URL of the local file to upload.
 * @param folderID           The MTP object ID of the destination folder.
 *                           Use @c EWFDeviceRootFolderID to upload to the root folder.
 * @param storageID          The MTP storage ID of the destination storage.
 * @param completionHandler  Called on the main queue when the transfer finishes.
 *                           error is nil on success; EWFTMTPErrorCancelled on cancellation.
 * @return An NSProgress instance (indeterminate total until first callback fires).
 */
- (NSProgress *)uploadFileFromSource:(NSURL *)sourceURL
                          toFolderID:(uint32_t)folderID
                           storageID:(uint32_t)storageID
                   completionHandler:(void (^)(NSError * _Nullable error))completionHandler
    NS_SWIFT_NAME(uploadFile(from:toFolderID:storageID:completionHandler:));

/**
 * Deletes an object (file or folder) from the MTP device.
 *
 * Executes on the device's internal serial MTP queue and delivers the result
 * on the main queue via completionHandler.
 *
 * @param objectID           The MTP object ID of the item to delete.
 * @param completionHandler  Called on the main queue when the operation finishes.
 *                           error is nil on success.
 */
- (void)deleteObjectWithID:(uint32_t)objectID
         completionHandler:(void (^)(NSError * _Nullable error))completionHandler
    NS_SWIFT_ASYNC_NAME(deleteObject(id:));

@end

NS_ASSUME_NONNULL_END
