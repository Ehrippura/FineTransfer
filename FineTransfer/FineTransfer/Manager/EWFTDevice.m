//
//  EWFTDevice.m
//  FineTransfer
//
//  Created by Wayne Lin on 2026/2/28.
//

#import "EWFTDevice+Private.h"
#import "EWFTFileItem+Private.h"
#import "EWFTMTPError.h"
#import <MTP/MTP.h>

uint32_t const EWFDeviceRootFolderID = LIBMTP_FILES_AND_FOLDERS_ROOT;

@interface EWFTDevice() {
    LIBMTP_mtpdevice_t *_mtp_device_handle;
}
@end

@implementation EWFTDevice

- (instancetype)initWithDevice:(LIBMTP_mtpdevice_t *)device {
    self = [super init];
    if (self) {
        _mtp_device_handle = device;
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

- (nullable NSArray<EWFTFileItem *> *)contentsOfFolderWithID:(uint32_t)folderID
                                                   storageID:(uint32_t)storageID
                                                       error:(NSError **)error {
    if (!_mtp_device_handle) {
        if (error) {
            *error = [NSError errorWithDomain:EWFTMTPErrorDomain
                                         code:EWFTMTPErrorGeneral
                                     userInfo:@{NSLocalizedDescriptionKey: @"Device is not connected."}];
        }
        return nil;
    }

    LIBMTP_Clear_Errorstack(_mtp_device_handle);

    LIBMTP_file_t *fileList = LIBMTP_Get_Files_And_Folders(_mtp_device_handle, storageID, folderID);

    if (fileList == NULL) {
        LIBMTP_error_t *errstack = LIBMTP_Get_Errorstack(_mtp_device_handle);
        if (errstack != NULL) {
            NSString *msg = errstack->error_text
                ? [NSString stringWithUTF8String:errstack->error_text]
                : @"Failed to list folder contents.";
            if (error) {
                *error = [NSError errorWithDomain:EWFTMTPErrorDomain
                                             code:errstack->errornumber
                                         userInfo:@{NSLocalizedDescriptionKey: msg}];
            }
            LIBMTP_Clear_Errorstack(_mtp_device_handle);
            return nil;
        }
        return @[];
    }

    NSMutableArray<EWFTFileItem *> *result = [NSMutableArray array];
    LIBMTP_file_t *current = fileList;
    while (current != NULL) {
        EWFTFileItem *item = [[EWFTFileItem alloc] initWithMTPFile:current];
        [result addObject:item];
        LIBMTP_file_t *next = current->next;
        LIBMTP_destroy_file_t(current);
        current = next;
    }

    return [result copy];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ <displayName=%@, manufacturer=%@, modelName=%@>",
            [super description],
            self.displayName ?: @"(null)",
            self.manufacturer ?: @"(null)",
            self.modelName ?: @"(null)"];
}

@end
