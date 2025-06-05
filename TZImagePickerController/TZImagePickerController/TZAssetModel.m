//
//  TZAssetModel.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "TZAssetModel.h"
#import "TZImageManager.h"
#import "ImageProcessor.h"
#import "Utils.h"

@implementation TZImageModel

+ (instancetype)modelWithImage:(UIImage*)image failed:(BOOL)isFailed
{
    TZImageModel* model = [TZImageModel new];
    model.image = image;
    model.isFailed = isFailed;
    model.isSelected = NO;
    return model;
}

+ (instancetype)modelWithImagePath:(NSString*)path failed:(BOOL)isFailed
{
    TZImageModel* model = [TZImageModel new];
    model.imagePath = path;
    model.isFailed = isFailed;
    model.isSelected = NO;
    return model;
}

@end

@implementation TZAssetModel

+ (instancetype)modelWithAsset:(PHAsset *)asset type:(TZAssetModelMediaType)type{
    TZAssetModel *model = [[TZAssetModel alloc] init];
    model.asset = asset;
    model.isSelected = NO;
    model.type = type;
    return model;
}

+ (instancetype)modelWithAsset:(PHAsset *)asset type:(TZAssetModelMediaType)type timeLength:(NSString *)timeLength {
    TZAssetModel *model = [self modelWithAsset:asset type:type];
    model.timeLength = timeLength;
    return model;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _strenth = 1.0;
    }
    return self;
}

- (void)processAutoColorSaveWithCompletion:(void(^)(BOOL success, NSError* error, UIImage* resultImage))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (self->_asset) {
            [[TZImageManager manager] getOriginalPhotoDataWithAsset:self->_asset completion:^(NSData *data, NSDictionary *info, BOOL isDegraded) {
                if (isDegraded) {
                    return;
                }
                if (!data) {
                    NSError* error = [Utils error:@"ColorCorrection" desc:@"Original image data should not be null." code:-4];
                    completion(NO, error, nil);
                }
                UIImage *originImage = [UIImage imageWithData:data];
                NSDate *creationDate = [self->_asset isKindOfClass:[PHAsset class]] ? ((PHAsset*)self->_asset).creationDate : nil;
                
                CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
                NSDictionary *imageInfo = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
                CFRelease(imageSource);
                
                [ImageProcessor saveCorrectedImage:originImage metaData:imageInfo strenth:self->_strenth creationDate:creationDate forceFixOrientation:YES completionHandler:^(BOOL success, NSError *error, NSString *localIdentifier, UIImage *resultImage) {
                    completion(success, error, resultImage);
                }];
            }];
        }
        else {
            NSError* error = [Utils error:@"ColorCorrection" desc:@"Selected asset should not be null." code:-1];
            completion(NO, error, nil);
        }
    });
}

@end



@implementation TZAlbumModel

- (void)setResult:(PHFetchResult *)result needFetchAssets:(BOOL)needFetchAssets {
    _result = result;
    if (needFetchAssets) {
        [[TZImageManager manager] getAssetsFromFetchResult:result completion:^(NSArray<TZAssetModel *> *models) {
            self->_models = models;
            if (self->_selectedModels) {
                [self checkSelectedModels];
            }
        }];
    }
}

- (void)refreshFetchResult {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:self.collection options:self.options];
    self.count = fetchResult.count;
    [self setResult:fetchResult];
}

- (void)setSelectedModels:(NSArray *)selectedModels {
    _selectedModels = selectedModels;
    if (_models) {
        [self checkSelectedModels];
    }
}

- (void)checkSelectedModels {
    self.selectedCount = 0;
    NSMutableSet *selectedAssets = [NSMutableSet setWithCapacity:_selectedModels.count];
    for (TZAssetModel *model in _selectedModels) {
        [selectedAssets addObject:model.asset];
    }
    for (TZAssetModel *model in _models) {
        if ([selectedAssets containsObject:model.asset]) {
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
