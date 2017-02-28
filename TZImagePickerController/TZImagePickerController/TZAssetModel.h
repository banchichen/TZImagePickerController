//
//  TZAssetModel.h
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TZAssetModelProtocol.h"
@class PHAsset;


@interface TZAssetModel : NSObject<TZAssetModel>

@property (nonatomic, strong) id tzAsset;             ///< PHAsset or ALAsset
@property (nonatomic, assign, getter=isTZSelected) BOOL tzSelected;      ///< The select status of a photo, default is No
@property (nonatomic, assign) TZAssetModelMediaType tzType;
@property (nonatomic, copy) NSString *tzTimeLength;

/// Init a photo dataModel With a asset
/// 用一个PHAsset/ALAsset实例，初始化一个照片模型
+ (instancetype)modelWithAsset:(id)tzAsset type:(TZAssetModelMediaType)tzType;
+ (instancetype)modelWithAsset:(id)tzAsset type:(TZAssetModelMediaType)tzType timeLength:(NSString *)tzTimeLength;
- (instancetype)initWithAsset:(id)tzAsset type:(TZAssetModelMediaType)tzType;
- (instancetype)initWithAsset:(id)tzAsset type:(TZAssetModelMediaType)tzType timeLength:(NSString *)tzTimeLength;

@end