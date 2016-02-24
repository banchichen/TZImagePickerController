//
//  TZImageManager.m
//  TZImagePickerController
//
//  Created by 谭真 on 16/1/4.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "TZImageManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "TZAssetModel.h"
#import "TZImagePickerController.h"

@interface TZImageManager ()
@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;
@end

@implementation TZImageManager

+ (instancetype)manager {
    static TZImageManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.cachingImageManager = [[PHCachingImageManager alloc] init];
    });
    return manager;
}

- (ALAssetsLibrary *)assetLibrary {
    if (_assetLibrary == nil) _assetLibrary = [[ALAssetsLibrary alloc] init];
    return _assetLibrary;
}

/// Return YES if Authorized 返回YES如果得到了授权
- (BOOL)authorizationStatusAuthorized {
    if (iOS8Later) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) return YES;
    } else {
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) return YES;
    }
    return NO;
}

#pragma mark - Get Album

/// Get Album 获得相册/相册数组
- (void)getCameraRollAlbum:(BOOL)allowPickingVideo completion:(void (^)(TZAlbumModel *))completion{
    __block TZAlbumModel *model;
    if (iOS8Later) {
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        for (PHAssetCollection *collection in smartAlbums) {
            if ([collection.localizedTitle isEqualToString:@"Camera Roll"] || [collection.localizedTitle isEqualToString:@"相机胶卷"]) {
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
                model = [self modelWithResult:fetchResult name:collection.localizedTitle];
                if (completion) completion(model);
                break;
            }
        }
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if ([group numberOfAssets] < 1) return;
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"]) {
                model = [self modelWithResult:group name:name];
                if (completion) completion(model);
                *stop = YES;
            }
        } failureBlock:nil];
    }
}

- (void)getAllAlbums:(BOOL)allowPickingVideo completion:(void (^)(NSArray<TZAlbumModel *> *))completion{
    NSMutableArray *albumArr = [NSMutableArray array];
    if (iOS8Later) {
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        PHAssetCollectionSubtype smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumVideos;
        // For iOS 9, We need to show ScreenShots Album && SelfPortraits Album
        if (iOS9Later) {
            smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumScreenshots | PHAssetCollectionSubtypeSmartAlbumSelfPortraits | PHAssetCollectionSubtypeSmartAlbumVideos;
        }
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:smartAlbumSubtype options:nil];
        for (PHAssetCollection *collection in smartAlbums) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1) continue;
            if ([collection.localizedTitle containsString:@"Deleted"] || [collection.localizedTitle isEqualToString:@"最近删除"]) continue;
            if ([collection.localizedTitle isEqualToString:@"Camera Roll"] || [collection.localizedTitle isEqualToString:@"相机胶卷"]) {
                [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle] atIndex:0];
            } else {
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle]];
            }
        }
        
        PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular | PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        for (PHAssetCollection *collection in albums) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1) continue;
            if ([collection.localizedTitle isEqualToString:@"My Photo Stream"] || [collection.localizedTitle isEqualToString:@"我的照片流"]) {
                [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle] atIndex:1];
            } else {
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle]];
            }
        }
        if (completion && albumArr.count > 0) completion(albumArr);
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group == nil) {
                if (completion && albumArr.count > 0) completion(albumArr);
            }
            if ([group numberOfAssets] < 1) return;
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"]) {
                [albumArr insertObject:[self modelWithResult:group name:name] atIndex:0];
            } else if ([name isEqualToString:@"My Photo Stream"] || [name isEqualToString:@"我的照片流"]) {
                [albumArr insertObject:[self modelWithResult:group name:name] atIndex:1];
            } else {
                [albumArr addObject:[self modelWithResult:group name:name]];
            }
        } failureBlock:nil];
    }
}

#pragma mark - Get Assets

/// Get Assets 获得照片数组
- (void)getAssetsFromFetchResult:(id)result allowPickingVideo:(BOOL)allowPickingVideo completion:(void (^)(NSArray<TZAssetModel *> *))completion {
    NSMutableArray *photoArr = [NSMutableArray array];
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            PHAsset *asset = (PHAsset *)obj;
            TZAssetModelMediaType type = TZAssetModelMediaTypePhoto;
            if (asset.mediaType == PHAssetMediaTypeVideo)      type = TZAssetModelMediaTypeVideo;
            else if (asset.mediaType == PHAssetMediaTypeAudio) type = TZAssetModelMediaTypeAudio;
            else if (asset.mediaType == PHAssetMediaTypeImage) {
                if (iOS9_1Later) {
                    // if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = TZAssetModelMediaTypeLivePhoto;
                }
            }
            if (!allowPickingVideo && type == TZAssetModelMediaTypeVideo) return;
            NSString *timeLength = type == TZAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
            timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
            [photoArr addObject:[TZAssetModel modelWithAsset:asset type:type timeLength:timeLength]];
        }];
        if (completion) completion(photoArr);
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *gruop = (ALAssetsGroup *)result;
        if (!allowPickingVideo) [gruop setAssetsFilter:[ALAssetsFilter allPhotos]];
        [gruop enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result == nil) {
                if (completion) completion(photoArr);
            }
            TZAssetModelMediaType type = TZAssetModelMediaTypePhoto;
            if (!allowPickingVideo){
                [photoArr addObject:[TZAssetModel modelWithAsset:result type:type]];
                return;
            }
            /// Allow picking video
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                type = TZAssetModelMediaTypeVideo;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                NSString *timeLength = [NSString stringWithFormat:@"%0.0f",duration];
                timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
                [photoArr addObject:[TZAssetModel modelWithAsset:result type:type timeLength:timeLength]];
            } else {
                [photoArr addObject:[TZAssetModel modelWithAsset:result type:type]];
            }
        }];
    }
}

///  Get asset at index 获得下标为index的单个照片
- (void)getAssetFromFetchResult:(id)result atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo completion:(void (^)(TZAssetModel *))completion {
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        PHAsset *asset = fetchResult[index];
        
        TZAssetModelMediaType type = TZAssetModelMediaTypePhoto;
        if (asset.mediaType == PHAssetMediaTypeVideo)      type = TZAssetModelMediaTypeVideo;
        else if (asset.mediaType == PHAssetMediaTypeAudio) type = TZAssetModelMediaTypeAudio;
        else if (asset.mediaType == PHAssetMediaTypeImage) {
            if (iOS9_1Later) {
                // if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = TZAssetModelMediaTypeLivePhoto;
            }
        }
        NSString *timeLength = type == TZAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
        timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
        TZAssetModel *model = [TZAssetModel modelWithAsset:asset type:type timeLength:timeLength];
        if (completion) completion(model);
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *gruop = (ALAssetsGroup *)result;
        if (!allowPickingVideo) [gruop setAssetsFilter:[ALAssetsFilter allPhotos]];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        [gruop enumerateAssetsAtIndexes:indexSet options:NSEnumerationConcurrent usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            TZAssetModel *model;
            TZAssetModelMediaType type = TZAssetModelMediaTypePhoto;
            if (!allowPickingVideo){
                model = [TZAssetModel modelWithAsset:result type:type];
                if (completion) completion(model);
                return;
            }
            /// Allow picking video
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                type = TZAssetModelMediaTypeVideo;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                NSString *timeLength = [NSString stringWithFormat:@"%0.0f",duration];
                timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
                model = [TZAssetModel modelWithAsset:result type:type timeLength:timeLength];
            } else {
                model = [TZAssetModel modelWithAsset:result type:type];
            }
            if (completion) completion(model);
        }];
    }
}

- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"0:0%zd",duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"0:%zd",duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}

/// Get photo bytes 获得一组照片的大小
- (void)getPhotosBytesWithArray:(NSArray *)photos completion:(void (^)(NSString *totalBytes))completion {
    __block NSInteger dataLength = 0;
    for (NSInteger i = 0; i < photos.count; i++) {
        TZAssetModel *model = photos[i];
        if ([model.asset isKindOfClass:[PHAsset class]]) {
            [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                if (model.type != TZAssetModelMediaTypeVideo) dataLength += imageData.length;
                if (i >= photos.count - 1) {
                    NSString *bytes = [self getBytesFromDataLength:dataLength];
                    if (completion) completion(bytes);
                }
            }];
        } else if ([model.asset isKindOfClass:[ALAsset class]]) {
            ALAssetRepresentation *representation = [model.asset defaultRepresentation];
            if (model.type != TZAssetModelMediaTypeVideo) dataLength += (NSInteger)representation.size;
            if (i >= photos.count - 1) {
                NSString *bytes = [self getBytesFromDataLength:dataLength];
                if (completion) completion(bytes);
            }
        }
    }
}

- (NSString *)getBytesFromDataLength:(NSInteger)dataLength {
    NSString *bytes;
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%0.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB",dataLength];
    }
    return bytes;
}

#pragma mark - Get Photo

/// Get photo 获得照片本身
- (void)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    [self getPhotoWithAsset:asset photoWidth:[UIScreen mainScreen].bounds.size.width completion:completion];
}

- (void)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    if (photoWidth > 600) photoWidth = 600.0;
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat multiple = [UIScreen mainScreen].scale;
        CGFloat pixelWidth = photoWidth * multiple;
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(pixelWidth, pixelHeight) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && result) {
                if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            }
            // Download image from iCloud / 从iCloud下载图片
            if ([info objectForKey:PHImageResultIsInCloudKey] && !result) {
                PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
                option.networkAccessAllowed = YES;
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    UIImage *resultImage = [UIImage imageWithData:imageData scale:0.1];
                    resultImage = [self scaleImage:resultImage toSize:CGSizeMake(pixelWidth, pixelHeight)];
                    if (resultImage) {
                        if (completion) completion(resultImage,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    }
                }];
            }
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        CGImageRef thumbnailImageRef = alAsset.aspectRatioThumbnail;
        UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef scale:1.0 orientation:UIImageOrientationUp];
        if (completion) completion(thumbnailImage,nil,YES);
        
        if (photoWidth == [UIScreen mainScreen].bounds.size.width) {
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                CGImageRef fullScrennImageRef = [assetRep fullScreenImage];
                UIImage *fullScrennImage = [UIImage imageWithCGImage:fullScrennImageRef scale:1.0 orientation:UIImageOrientationUp];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(fullScrennImage,nil,NO);
                });
            });
        }
    }
}

- (void)getPostImageWithAlbumModel:(TZAlbumModel *)model completion:(void (^)(UIImage *))completion {
    if (iOS8Later) {
        [[TZImageManager manager] getPhotoWithAsset:[model.result lastObject] photoWidth:80 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (completion) completion(photo);
        }];
    } else {
        ALAssetsGroup *gruop = model.result;
        UIImage *postImage = [UIImage imageWithCGImage:gruop.posterImage];
        if (completion) completion(postImage);
    }
}

/// Get Original Photo / 获取原图
- (void)getOriginalPhotoWithAsset:(id)asset completion:(void (^)(UIImage *photo,NSDictionary *info))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
        option.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && result) {
                if (completion) completion(result,info);
            }
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            CGImageRef originalImageRef = [assetRep fullResolutionImage];
            UIImage *originalImage = [UIImage imageWithCGImage:originalImageRef scale:1.0 orientation:UIImageOrientationUp];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(originalImage,nil);
            });
        });
    }
}

#pragma mark - Get Video

- (void)getVideoWithAsset:(id)asset completion:(void (^)(AVPlayerItem * _Nullable, NSDictionary * _Nullable))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            if (completion) completion(playerItem,info);
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *defaultRepresentation = [alAsset defaultRepresentation];
        NSString *uti = [defaultRepresentation UTI];
        NSURL *videoURL = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
        if (completion && playerItem) completion(playerItem,nil);
    }
}

#pragma mark - Private Method

- (TZAlbumModel *)modelWithResult:(id)result name:(NSString *)name{
    TZAlbumModel *model = [[TZAlbumModel alloc] init];
    model.result = result;
    model.name = [self getNewAlbumName:name];
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        model.count = fetchResult.count;
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *gruop = (ALAssetsGroup *)result;
        model.count = [gruop numberOfAssets];
    }
    return model;
}

- (NSString *)getNewAlbumName:(NSString *)name {
    if (iOS8Later) {
        NSString *newName;
        if ([name containsString:@"Roll"])         newName = @"相机胶卷";
        else if ([name containsString:@"Stream"])  newName = @"我的照片流";
        else if ([name containsString:@"Added"])   newName = @"最近添加";
        else if ([name containsString:@"Selfies"]) newName = @"自拍";
        else if ([name containsString:@"shots"])   newName = @"截屏";
        else if ([name containsString:@"Videos"])  newName = @"视频";
        else newName = name;
        return newName;
    } else {
        return name;
    }
}

- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
