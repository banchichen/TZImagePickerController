//
//  TZAssetModelProtocol.h
//  TZImagePickerController
//
//  Created by d jiang on 25/02/17.
//  Copyright © 2017 谭真. All rights reserved.
//

/*
 * 如果使用自定义的数据结构，请将TZ_NAME_OF_ASSETMODELCLASS，改为你的数据结构的名字
 * change “TZ_NAME_OF_ASSETMODELCLASS” to your Class name
 */
#define TZ_NAME_OF_ASSETMODELCLASS @"TZAssetModel"


#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    TZAssetModelMediaTypePhoto = 0,
    TZAssetModelMediaTypeLivePhoto,
    TZAssetModelMediaTypePhotoGif,
    TZAssetModelMediaTypeVideo,
    TZAssetModelMediaTypeAudio
} TZAssetModelMediaType;

@protocol TZAssetModel <NSObject>

@required
@property (nonatomic, strong) id asset;             ///< PHAsset or ALAsset
@property (nonatomic, assign) BOOL isSelected;      ///< The select status of a photo, default is No
@property (nonatomic, assign) TZAssetModelMediaType type;
@property (nonatomic, copy) NSString *timeLength;

- (instancetype)initWithAsset:(id)asset type:(TZAssetModelMediaType)type;
- (instancetype)initWithAsset:(id)asset type:(TZAssetModelMediaType)type timeLength:(NSString *)timeLength;

@end
