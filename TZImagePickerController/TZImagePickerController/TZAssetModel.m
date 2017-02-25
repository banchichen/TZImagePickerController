//
//  TZAssetModel.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "TZAssetModel.h"
#import "TZImageManager.h"

@implementation TZAssetModel

+ (instancetype)modelWithAsset:(id)asset type:(TZAssetModelMediaType)type {
    return [[self alloc] initWithAsset:asset type:type];
}

- (instancetype)initWithAsset:(id)asset type:(TZAssetModelMediaType)type {
    self = [super init];
    if (self) {
        _asset = asset;
        _isSelected = NO;
        _type = type;
    }
    return self;
}

+ (instancetype)modelWithAsset:(id)asset type:(TZAssetModelMediaType)type timeLength:(NSString *)timeLength {
    return [[self alloc] initWithAsset:asset type:type timeLength:timeLength];
}

- (instancetype)initWithAsset:(id)asset type:(TZAssetModelMediaType)type timeLength:(NSString *)timeLength {
    self = [super init];
    if (self) {
        _asset = asset;
        _isSelected = NO;
        _type = type;
        _timeLength = timeLength;
    }
    return self;
}


@end

