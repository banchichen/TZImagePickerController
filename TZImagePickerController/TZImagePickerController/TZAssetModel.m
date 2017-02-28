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

+ (instancetype)modelWithAsset:(id)tzAsset type:(TZAssetModelMediaType)tzType {
    return [[self alloc] initWithAsset:tzAsset type:tzType];
}

+ (instancetype)modelWithAsset:(id)tzAsset type:(TZAssetModelMediaType)tzType timeLength:(NSString *)tzTimeLength {
    return [[self alloc] initWithAsset:tzAsset type:tzType timeLength:tzTimeLength];
}

- (instancetype)initWithAsset:(id)tzAsset type:(TZAssetModelMediaType)tzType {
    self = [super init];
    if (self) {
        _tzAsset = tzAsset;
        _tzSelected = NO;
        _tzType = tzType;
    }
    return self;
}
- (instancetype)initWithAsset:(id)tzAsset type:(TZAssetModelMediaType)tzType timeLength:(NSString *)tzTimeLength {
    self = [super init];
    if (self) {
        _tzAsset = tzAsset;
        _tzSelected = NO;
        _tzType = tzType;
        _tzTimeLength = tzTimeLength;
    }
    return self;
}

@end

