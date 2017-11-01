//
//  TZLocationManager.h
//  TZImagePickerController
//
//  Created by 谭真 on 2017/06/03.
//  Copyright © 2017年 谭真. All rights reserved.
//  定位管理类


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface TZLocationManager : NSObject

+ (instancetype)manager;

/// 开始定位
- (void)startLocation;
- (void)startLocationWithSuccessBlock:(void (^)(CLLocation *location,CLLocation *oldLocation))successBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)startLocationWithGeocoderBlock:(void (^)(NSArray *geocoderArray))geocoderBlock;
- (void)startLocationWithSuccessBlock:(void (^)(CLLocation *location,CLLocation *oldLocation))successBlock failureBlock:(void (^)(NSError *error))failureBlock geocoderBlock:(void (^)(NSArray *geocoderArray))geocoderBlock;

@end

