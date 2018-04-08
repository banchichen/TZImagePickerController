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

+ (instancetype)modelWithAsset:(id)asset type:(TZAssetModelMediaType)type{
    TZAssetModel *model = [[TZAssetModel alloc] init];
    model.asset = asset;
    model.isSelected = NO;
    model.type = type;
    return model;
}

+ (instancetype)modelWithAsset:(id)asset type:(TZAssetModelMediaType)type timeLength:(NSString *)timeLength {
    TZAssetModel *model = [self modelWithAsset:asset type:type];
    model.timeLength = timeLength;
    return model;
}

- (UIImage *)getFullImageSynchronous {
    __block UIImage *resultImage = nil;
    if (!self.asset) {
        return nil;
    }
    if ([self.asset isKindOfClass:[PHAsset class]]) {
        PHImageRequestOptions *phImageRequestOptions = [[PHImageRequestOptions alloc] init];
        phImageRequestOptions.synchronous = YES;
        [[PHImageManager defaultManager] requestImageForAsset:self.asset
                                                   targetSize:PHImageManagerMaximumSize
                                                  contentMode:PHImageContentModeDefault
                                                      options:phImageRequestOptions
                                                resultHandler:^(UIImage *result, NSDictionary *info) {
                                                    resultImage = result;
                                                }];
        return resultImage;
    }
    else {
        ALAsset *alAsset = (ALAsset *)self.asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        CGImageRef originalImageRef = [assetRep fullResolutionImage];
        UIImage *originalImage = [UIImage imageWithCGImage:originalImageRef scale:1.0 orientation:UIImageOrientationUp];
        return originalImage;
    }
}

@end



@implementation TZAlbumModel

- (void)setResult:(id)result {
    _result = result;
    BOOL allowPickingImage = [[[NSUserDefaults standardUserDefaults] objectForKey:@"tz_allowPickingImage"] isEqualToString:@"1"];
    BOOL allowPickingVideo = [[[NSUserDefaults standardUserDefaults] objectForKey:@"tz_allowPickingVideo"] isEqualToString:@"1"];
    [[TZImageManager manager] getAssetsFromFetchResult:result allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage completion:^(NSArray<TZAssetModel *> *models) {
        _models = models;
        if (_selectedModels) {
            [self checkSelectedModels];
        }
    }];
}

- (void)setSelectedModels:(NSArray *)selectedModels {
    _selectedModels = selectedModels;
    if (_models) {
        [self checkSelectedModels];
    }
}

- (void)checkSelectedModels {
    self.selectedCount = 0;
    NSMutableArray *selectedAssets = [NSMutableArray array];
    for (TZAssetModel *model in _selectedModels) {
        [selectedAssets addObject:model.asset];
    }
    for (TZAssetModel *model in _models) {
        if ([[TZImageManager manager] isAssetsArray:selectedAssets containAsset:model.asset]) {
            self.selectedCount ++;
        }
    }
}

- (NSString *)name {
    if (_name) {
        return _name;
    }
    return @"";
}

@end
