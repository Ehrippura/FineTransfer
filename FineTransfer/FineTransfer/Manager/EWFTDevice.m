//
//  EWFTDevice.m
//  FineTransfer
//
//  Created by Wayne Lin on 2026/2/28.
//

#import "EWFTDevice+Private.h"

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

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ <displayName=%@, manufacturer=%@, modelName=%@>",
            [super description],
            self.displayName ?: @"(null)",
            self.manufacturer ?: @"(null)",
            self.modelName ?: @"(null)"];
}

@end
