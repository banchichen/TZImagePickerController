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

-(NSTimeInterval)timeLen{
    // self.timeLength -> timeLen "00:06" -> 06
    __block NSTimeInterval len = 0;
    // :分隔，并逆序
    NSArray * strList = [[[self.timeLength componentsSeparatedByString:@":"] reverseObjectEnumerator] allObjects];
    [strList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger time = (NSInteger)((NSString *)obj);
        NSInteger timebase = (60)^(idx);
        len += (NSTimeInterval)(time * timebase);
    }];
    return len;
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
