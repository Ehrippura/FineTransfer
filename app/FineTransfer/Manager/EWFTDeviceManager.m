//
//  EWFTDeviceManager.m
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

#import "EWFTDeviceManager.h"
#import "EWFTDevice+Private.h"
#import <MTP/MTP.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/usb/IOUSBLib.h>

@interface EWFTDeviceManager()
- (instancetype)_init NS_DESIGNATED_INITIALIZER;
@property (nonatomic, copy) void (^changeHandler)(void);
@property (nonatomic, assign) IONotificationPortRef notificationPort;
@property (nonatomic, assign) io_iterator_t addedIterator;
@property (nonatomic, assign) io_iterator_t removedIterator;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, EWFTDevice *> *openDevices;
@end

static void deviceAdded(void *refCon, io_iterator_t iterator) {
    EWFTDeviceManager *manager = (__bridge EWFTDeviceManager *)refCon;
    io_object_t obj;
    while ((obj = IOIteratorNext(iterator))) {
        IOObjectRelease(obj);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (manager.changeHandler) {
            manager.changeHandler();
        }
    });
}

static void deviceRemoved(void *refCon, io_iterator_t iterator) {
    EWFTDeviceManager *manager = (__bridge EWFTDeviceManager *)refCon;
    io_object_t obj;
    while ((obj = IOIteratorNext(iterator))) {
        IOObjectRelease(obj);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (manager.changeHandler) {
            manager.changeHandler();
        }
    });
}

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
        _openDevices = [NSMutableDictionary dictionary];
    }
    return self;
}

- (nullable NSArray<EWFTDevice *> *)detectDevicesWithError:(NSError **)error {
    LIBMTP_raw_device_t *deviceRaw = NULL;
    int deviceCount = 0;

    LIBMTP_error_number_t err = LIBMTP_Detect_Raw_Devices(&deviceRaw, &deviceCount);

    if (err == LIBMTP_ERROR_NO_DEVICE_ATTACHED) {
        [self.openDevices removeAllObjects];
        return @[];
    }

    if (err != LIBMTP_ERROR_NONE) {
        if (error) {
            NSString *msg = EWFTLocalizedDescription((EWFTMTPError)err)
                ?: NSLocalizedString(@"Couldn't detect connected devices. Please check the USB connection and try again.", @"Device detection error fallback");
            *error = [NSError errorWithDomain:EWFTMTPErrorDomain
                                         code:(NSInteger)err
                                     userInfo:@{NSLocalizedDescriptionKey: msg}];
        }
        return nil;
    }

    NSMutableSet<NSNumber *> *detectedLocations = [NSMutableSet set];
    NSMutableArray<EWFTDevice *> *devices = [NSMutableArray arrayWithCapacity:deviceCount];

    for (int i = 0; i < deviceCount; i++) {
        LIBMTP_raw_device_t *raw = &deviceRaw[i];
        NSNumber *key = @(raw->bus_location);
        [detectedLocations addObject:key];

        EWFTDevice *cached = self.openDevices[key];
        if (cached) {
            [devices addObject:cached];
            continue;
        }

        LIBMTP_mtpdevice_t *handle = LIBMTP_Open_Raw_Device_Uncached(raw);
        if (!handle) {
            continue;
        }

        EWFTDevice *d = [[EWFTDevice alloc] initWithDevice:handle busLocation:raw->bus_location];
        self.openDevices[key] = d;
        [devices addObject:d];
    }

    NSMutableSet *staleKeys = [NSMutableSet setWithArray:self.openDevices.allKeys];
    [staleKeys minusSet:detectedLocations];
    [self.openDevices removeObjectsForKeys:staleKeys.allObjects];

    free(deviceRaw);
    return [devices copy];
}

- (void)startMonitoringWithChangeHandler:(void (^)(void))changeHandler {
    self.changeHandler = changeHandler;
    self.notificationPort = IONotificationPortCreate(kIOMainPortDefault);
    CFRunLoopAddSource(CFRunLoopGetMain(),
                       IONotificationPortGetRunLoopSource(self.notificationPort),
                       kCFRunLoopDefaultMode);

    CFMutableDictionaryRef matchAdded = IOServiceMatching(kIOUSBDeviceClassName);
    CFMutableDictionaryRef matchRemoved = IOServiceMatching(kIOUSBDeviceClassName);

    IOServiceAddMatchingNotification(self.notificationPort, kIOFirstMatchNotification,
        matchAdded, deviceAdded, (__bridge void *)self, &_addedIterator);
    io_object_t obj;
    while ((obj = IOIteratorNext(_addedIterator))) {
        IOObjectRelease(obj);
    }

    IOServiceAddMatchingNotification(self.notificationPort, kIOTerminatedNotification,
        matchRemoved, deviceRemoved, (__bridge void *)self, &_removedIterator);
    while ((obj = IOIteratorNext(_removedIterator))) {
        IOObjectRelease(obj);
    }
}

@end
