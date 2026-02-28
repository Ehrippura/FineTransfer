//
//  EWFTDeviceManager.h
//  FineTransfer
//
//  Created by Wayne Lin on 2026/2/28.
//

#import <Foundation/Foundation.h>
#import "EWFTDevice.h"

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const EWFTDeviceManagerMTPErrorDomain;

typedef NS_ERROR_ENUM(EWFTDeviceManagerMTPErrorDomain, EWFTDeviceManagerMTPError) {
    EWFTDeviceManagerMTPErrorNone               = 0,
    EWFTDeviceManagerMTPErrorGeneral            = 1,
    EWFTDeviceManagerMTPErrorPTPLayer           = 2,
    EWFTDeviceManagerMTPErrorUSBLayer           = 3,
    EWFTDeviceManagerMTPErrorMemoryAllocation   = 4,
    EWFTDeviceManagerMTPErrorNoDeviceAttached   = 5,
    EWFTDeviceManagerMTPErrorStorageFull        = 6,
    EWFTDeviceManagerMTPErrorConnecting         = 7,
    EWFTDeviceManagerMTPErrorCancelled          = 8,
};

NS_SWIFT_NAME(DeviceManager)
@interface EWFTDeviceManager : NSObject

@property (nonatomic, strong, readonly, class) EWFTDeviceManager *sharedManager;

- (instancetype)init NS_UNAVAILABLE;

- (nullable NSArray<EWFTDevice *> *)detectDevicesWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
