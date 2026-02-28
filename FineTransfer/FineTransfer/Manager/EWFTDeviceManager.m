//
//  EWFTDeviceManager.m
//  FineTransfer
//
//  Created by Wayne Lin on 2026/2/28.
//

#import "EWFTDeviceManager.h"
#import "EWFTDevice+Private.h"
#import <MTP/MTP.h>

NSErrorDomain const EWFTDeviceManagerMTPErrorDomain = @"EWFTDeviceManagerMTPErrorDomain";

@interface EWFTDeviceManager()
- (instancetype)_init NS_DESIGNATED_INITIALIZER;
@end

@implementation EWFTDeviceManager

+ (EWFTDeviceManager *)sharedManager {
    static EWFTDeviceManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWFTDeviceManager alloc] _init];
    });
    return manager;
}

- (instancetype)_init {
    self = [super init];
    if (self) {
        LIBMTP_Init();
    }
    return self;
}

- (nullable NSArray<EWFTDevice *> *)detectDevicesWithError:(NSError **)error {
    LIBMTP_raw_device_t *deviceRaw = NULL;
    int deviceCount = 0;

    LIBMTP_error_number_t err = LIBMTP_Detect_Raw_Devices(&deviceRaw, &deviceCount);

    if (err == LIBMTP_ERROR_NO_DEVICE_ATTACHED) {
        return @[];
    }

    if (err != LIBMTP_ERROR_NONE) {
        if (error) {
            *error = [NSError errorWithDomain:EWFTDeviceManagerMTPErrorDomain
                                         code:(NSInteger)err
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to detect MTP devices."}];
        }
        return nil;
    }

    NSMutableArray<EWFTDevice *> *devices = [NSMutableArray arrayWithCapacity:deviceCount];

    for (int i = 0; i < deviceCount; i++) {
        LIBMTP_mtpdevice_t *device = LIBMTP_Open_Raw_Device_Uncached(&deviceRaw[i]);
        if (!device) {
            continue;
        }

        EWFTDevice *d = [[EWFTDevice alloc] initWithDevice:device];
        [devices addObject:d];
    }

    free(deviceRaw);
    return [devices copy];
}

@end
