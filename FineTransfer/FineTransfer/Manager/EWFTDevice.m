//
//  EWFTDevice.m
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

#import "EWFTDevice+Private.h"
#import "EWFTFileItem+Private.h"
#import "EWFTStorage+Private.h"
#import "EWFTMTPError.h"
#import <MTP/MTP.h>

uint32_t const EWFDeviceRootFolderID = LIBMTP_FILES_AND_FOLDERS_ROOT;

@interface EWFTDevice() {
    LIBMTP_mtpdevice_t *_mtp_device_handle;
    dispatch_queue_t _mtpQueue;
}
@end

// C callback invoked by libmtp during file transfers — runs on _mtpQueue.
// Returns 1 to abort the transfer when the caller cancels the NSProgress object.
static int EWFTTransferProgressCallback(uint64_t sent, uint64_t total, void const * const data) {
    NSProgress *progress = (__bridge NSProgress *)data;
    progress.totalUnitCount = (int64_t)total;
    progress.completedUnitCount = (int64_t)sent;
    return progress.isCancelled ? 1 : 0;
}

@implementation EWFTDevice

- (instancetype)initWithDevice:(LIBMTP_mtpdevice_t *)device {
    self = [super init];
    if (self) {
        _mtp_device_handle = device;
        _mtpQueue = dispatch_queue_create("tw.eternalwind.device.mtp", DISPATCH_QUEUE_SERIAL);

        NSMutableArray<EWFTStorage *> *result = [NSMutableArray array];
        LIBMTP_devicestorage_t *current = _mtp_device_handle->storage;
        while (current != NULL) {
            [result addObject:[[EWFTStorage alloc] initWithMTPStorage:current]];
            current = current->next;
        }
        
        _storages = [result copy];
    }
    return self;
}

- (void)dealloc {
    if (_mtp_device_handle) {
        LIBMTP_Release_Device(_mtp_device_handle);
        _mtp_device_handle = NULL;
    }
}

- (void)disconnect {
    if (_mtp_device_handle) {
        LIBMTP_Release_Device(_mtp_device_handle);
        _mtp_device_handle = NULL;
    }
}

- (BOOL)isConnected {
    return _mtp_device_handle != NULL;
}

 - (NSString *)displayName {
    char *friendlyName = LIBMTP_Get_Friendlyname(_mtp_device_handle);
    NSString *result = friendlyName ? [NSString stringWithUTF8String:friendlyName] : nil;
    free(friendlyName);
    return result;
 }

- (NSString *)manufacturer {
    char *manufacturer = LIBMTP_Get_Manufacturername(_mtp_device_handle);
    NSString *result = manufacturer ? [NSString stringWithUTF8String:manufacturer] : nil;
    free(manufacturer);
    return result;
}

- (NSString *)modelName {
    char *modelName = LIBMTP_Get_Modelname(_mtp_device_handle);
    NSString *result = modelName ? [NSString stringWithUTF8String:modelName] : nil;
    free(modelName);
    return result;
}

- (NSString *)serialNumber {
    char *serialNumber = LIBMTP_Get_Serialnumber(_mtp_device_handle);
    NSString *result = serialNumber ? [NSString stringWithUTF8String:serialNumber] : nil;
    free(serialNumber);
    return result;
}

- (uint32_t)rootStorageID {
    return _mtp_device_handle->storage->id;
}

- (void)contentsOfFolderWithID:(uint32_t)folderID
                     storageID:(uint32_t)storageID
             completionHandler:(void (^)(NSArray<EWFTFileItem *> * _Nullable, NSError * _Nullable))completionHandler {
    dispatch_async(_mtpQueue, ^{
        if (!self->_mtp_device_handle) {
            NSError *error = [NSError errorWithDomain:EWFTMTPErrorDomain
                                                 code:EWFTMTPErrorGeneral
                                             userInfo:@{NSLocalizedDescriptionKey: @"Device is not connected."}];
            completionHandler(nil, error);
            return;
        }

        LIBMTP_Clear_Errorstack(self->_mtp_device_handle);

        LIBMTP_file_t *fileList = LIBMTP_Get_Files_And_Folders(self->_mtp_device_handle, storageID, folderID);

        if (fileList == NULL) {
            LIBMTP_error_t *errstack = LIBMTP_Get_Errorstack(self->_mtp_device_handle);
            if (errstack != NULL) {
                NSString *msg = errstack->error_text
                    ? [NSString stringWithUTF8String:errstack->error_text]
                    : @"Failed to list folder contents.";
                NSError *error = [NSError errorWithDomain:EWFTMTPErrorDomain
                                                     code:errstack->errornumber
                                                 userInfo:@{NSLocalizedDescriptionKey: msg}];
                LIBMTP_Clear_Errorstack(self->_mtp_device_handle);
                completionHandler(nil, error);
            } else {
                completionHandler(@[], nil);
            }
            return;
        }

        NSMutableArray<EWFTFileItem *> *items = [NSMutableArray array];
        LIBMTP_file_t *current = fileList;
        while (current != NULL) {
            [items addObject:[[EWFTFileItem alloc] initWithMTPFile:current]];
            LIBMTP_file_t *next = current->next;
            LIBMTP_destroy_file_t(current);
            current = next;
        }

        NSArray<EWFTFileItem *> *result = [items copy];
        completionHandler(result, nil);
    });
}

- (NSProgress *)downloadFileWithID:(uint32_t)fileID
                     toDestination:(NSURL *)destinationURL
                 completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:-1];

    dispatch_async(_mtpQueue, ^{
        if (!self->_mtp_device_handle) {
            NSError *error = [NSError errorWithDomain:EWFTMTPErrorDomain
                                                 code:EWFTMTPErrorGeneral
                                             userInfo:@{NSLocalizedDescriptionKey: @"Device is not connected."}];
            completionHandler(error);
            return;
        }

        LIBMTP_Clear_Errorstack(self->_mtp_device_handle);

        int result = LIBMTP_Get_File_To_File(self->_mtp_device_handle,
                                             fileID,
                                             destinationURL.fileSystemRepresentation,
                                             EWFTTransferProgressCallback,
                                             (__bridge void *)progress);

        NSError *completionError = nil;
        if (result != 0) {
            if (progress.isCancelled) {
                completionError = [NSError errorWithDomain:EWFTMTPErrorDomain
                                                      code:EWFTMTPErrorCancelled
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Download was cancelled."}];
                [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
            } else {
                LIBMTP_error_t *errstack = LIBMTP_Get_Errorstack(self->_mtp_device_handle);
                NSString *msg = (errstack && errstack->error_text)
                    ? [NSString stringWithUTF8String:errstack->error_text]
                    : @"Failed to download file.";
                completionError = [NSError errorWithDomain:EWFTMTPErrorDomain
                                                      code:errstack->errornumber
                                                  userInfo:@{NSLocalizedDescriptionKey: msg}];
                LIBMTP_Clear_Errorstack(self->_mtp_device_handle);
            }
        }

        completionHandler(completionError);
    });

    return progress;
}

- (NSProgress *)uploadFileFromSource:(NSURL *)sourceURL
                          toFolderID:(uint32_t)folderID
                           storageID:(uint32_t)storageID
                   completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:-1];

    dispatch_async(_mtpQueue, ^{
        if (!self->_mtp_device_handle) {
            NSError *error = [NSError errorWithDomain:EWFTMTPErrorDomain
                                                 code:EWFTMTPErrorGeneral
                                             userInfo:@{NSLocalizedDescriptionKey: @"Device is not connected."}];
            completionHandler(error);
            return;
        }

        NSError *attributeError = nil;
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:sourceURL.path
                                                                               error:&attributeError];
        if (!attrs) {
            completionHandler(attributeError);
            return;
        }

        LIBMTP_file_t *fileInfo = LIBMTP_new_file_t();
        fileInfo->filename = strdup(sourceURL.lastPathComponent.UTF8String);
        fileInfo->filesize = [attrs[NSFileSize] unsignedLongLongValue];
        fileInfo->parent_id = folderID;
        fileInfo->storage_id = storageID;
        fileInfo->filetype = LIBMTP_FILETYPE_UNKNOWN;

        LIBMTP_Clear_Errorstack(self->_mtp_device_handle);

        int result = LIBMTP_Send_File_From_File(self->_mtp_device_handle,
                                                sourceURL.fileSystemRepresentation,
                                                fileInfo,
                                                EWFTTransferProgressCallback,
                                                (__bridge void *)progress);
        LIBMTP_destroy_file_t(fileInfo);

        NSError *completionError = nil;
        if (result != 0) {
            if (progress.isCancelled) {
                completionError = [NSError errorWithDomain:EWFTMTPErrorDomain
                                                      code:EWFTMTPErrorCancelled
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Upload was cancelled."}];
            } else {
                LIBMTP_error_t *errstack = LIBMTP_Get_Errorstack(self->_mtp_device_handle);
                NSString *msg = (errstack && errstack->error_text)
                    ? [NSString stringWithUTF8String:errstack->error_text]
                    : @"Failed to upload file.";
                completionError = [NSError errorWithDomain:EWFTMTPErrorDomain
                                                      code:errstack ? (EWFTMTPError)errstack->errornumber : EWFTMTPErrorGeneral
                                                  userInfo:@{NSLocalizedDescriptionKey: msg}];
                LIBMTP_Clear_Errorstack(self->_mtp_device_handle);
            }
        }

        completionHandler(completionError);
    });

    return progress;
}

- (void)deleteObjectWithID:(uint32_t)objectID
         completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    dispatch_async(_mtpQueue, ^{
        if (!self->_mtp_device_handle) {
            NSError *error = [NSError errorWithDomain:EWFTMTPErrorDomain
                                                 code:EWFTMTPErrorGeneral
                                             userInfo:@{NSLocalizedDescriptionKey: @"Device is not connected."}];
            completionHandler(error);
            return;
        }

        LIBMTP_Clear_Errorstack(self->_mtp_device_handle);

        int result = LIBMTP_Delete_Object(self->_mtp_device_handle, objectID);

        NSError *completionError = nil;
        if (result != 0) {
            LIBMTP_error_t *errstack = LIBMTP_Get_Errorstack(self->_mtp_device_handle);
            NSString *msg = (errstack && errstack->error_text)
                ? [NSString stringWithUTF8String:errstack->error_text]
                : @"Failed to delete object.";
            completionError = [NSError errorWithDomain:EWFTMTPErrorDomain
                                                  code:errstack ? (EWFTMTPError)errstack->errornumber : EWFTMTPErrorGeneral
                                              userInfo:@{NSLocalizedDescriptionKey: msg}];
            LIBMTP_Clear_Errorstack(self->_mtp_device_handle);
        }

        completionHandler(completionError);
    });
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ <displayName=%@, manufacturer=%@, modelName=%@>",
            [super description],
            self.displayName ?: @"(null)",
            self.manufacturer ?: @"(null)",
            self.modelName ?: @"(null)"];
}

@end
