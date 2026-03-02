//
//  EWFTDeviceManager.h
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

#import <Foundation/Foundation.h>
#import "EWFTDevice.h"
#import "EWFTMTPError.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DeviceManager)
@interface EWFTDeviceManager : NSObject

@property (nonatomic, strong, readonly, class) EWFTDeviceManager *sharedManager;

- (instancetype)init NS_UNAVAILABLE;

- (nullable NSArray<EWFTDevice *> *)detectDevicesWithError:(NSError **)error;

- (void)startMonitoringWithChangeHandler:(void (^)(void))changeHandler;

@end

NS_ASSUME_NONNULL_END
