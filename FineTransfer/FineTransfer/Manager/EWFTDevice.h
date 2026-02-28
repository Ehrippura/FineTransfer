//
//  EWFTDevice.h
//  FineTransfer
//
//  Created by Wayne Lin on 2026/2/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MTPDevice)
@interface EWFTDevice : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *displayName;
@property (nonatomic, copy, readonly, nullable) NSString *manufacturer;
@property (nonatomic, copy, readonly, nullable) NSString *modelName;
@property (nonatomic, copy, readonly, nullable) NSString *serialNumber;

@property (nonatomic, readonly, getter=isConnected) BOOL connected;

- (instancetype)init NS_UNAVAILABLE;

- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
