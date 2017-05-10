//
//  TZAssetGroupCell.m
//  Pods
//
//  Created by 崔成 on 2016/11/2.
//
//
#define CCSCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width
#define iOS8Later ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f)
#import "TZAssetGroupCell.h"
#import "TZAssetCell.h"
#import "TZAssetModel.h"
#import "TZImageManager.h"
#import "UIView+Layout.h"

@implementation TZAssetGroupCell
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        CGFloat margin = 4;
        self.cellArray = [[NSMutableArray alloc] initWithCapacity:4];
        CGFloat itemWH = (CCSCREEN_WIDTH - 2 * margin - 4) / 4 - margin;
        for (int i = 0 ;i < 4; i++){
            TZAssetCell *cell = [[TZAssetCell alloc] initWithFrame:CGRectMake((itemWH + 6) * (i % 2), (itemWH + 6) * (i / 2), itemWH, itemWH)];
            [self.cellArray addObject:cell];
            cell.tag = 100 + i;
            cell.userInteractionEnabled = YES;
            [self.contentView addSubview:cell];
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTaped:)];
            [cell addGestureRecognizer:tap];
        }
    }
    return self;
}
- (void)setGroupCell:(NSArray *)array{
    _models = array;
    for (int i = 0; i < 4 ; i++){
        TZAssetModel *model = [array objectAtIndex:i];
        if (!model){
            return;
        }
        TZAssetCell *cell = [self.cellArray objectAtIndex:i];
        if (iOS8Later) {
            cell.representedAssetIdentifier = [[TZImageManager manager] getAssetIdentifier:model.asset];
        }
        PHImageRequestID imageRequestID = [[TZImageManager manager] getPhotoWithAsset:model.asset photoWidth:CCSCREEN_WIDTH completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            // Set the cell's thumbnail image if it's still showing the same asset.
            if (!iOS8Later) {
                cell.imageView.image = photo; return;
            }
            if ([cell.representedAssetIdentifier isEqualToString:[[TZImageManager manager] getAssetIdentifier:model.asset]]) {
                cell.imageView.image = photo;
            } else {
                // NSLog(@"this cell is showing other asset");
                [[PHImageManager defaultManager] cancelImageRequest:cell.imageRequestID];
            }
            if (!isDegraded) {
                cell.imageRequestID = 0;
            }
        }];
        if (imageRequestID && cell.imageRequestID && imageRequestID != cell.imageRequestID) {
            [[PHImageManager defaultManager] cancelImageRequest:cell.imageRequestID];
            // NSLog(@"cancelImageRequest %d",self.imageRequestID);
        }
        cell.imageRequestID = imageRequestID;
        cell.selectPhotoButton.selected = model.isSelected;
        cell.selectImageView.image = cell.selectPhotoButton.isSelected ? [UIImage imageNamedFromMyBundle:@"photo_sel_photoPickerVc.png"] : [UIImage imageNamedFromMyBundle:@"photo_def_photoPickerVc.png"];
        cell.type = TZAssetCellTypePhoto;
        if (model.type == TZAssetModelMediaTypeLivePhoto)      cell.type = TZAssetCellTypeLivePhoto;
        else if (model.type == TZAssetModelMediaTypeAudio)     cell.type = TZAssetCellTypeAudio;
        else if (model.type == TZAssetModelMediaTypeVideo) {
            cell.type = TZAssetCellTypeVideo;
            cell.timeLength.text = model.timeLength;
        }
        __weak typeof(cell) weakCell = cell;
        __weak typeof(self) weakSelf = self;
        __weak typeof(self.photoPickerController.numberImageView.layer) weakLayer = self.photoPickerController.numberImageView.layer;
        
        cell.didSelectPhotoBlock = ^(BOOL isSelected) {
            TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)weakSelf.photoPickerController.navigationController;
            // 1. cancel select / 取消选择
            if (isSelected) {
                weakCell.selectPhotoButton.selected = NO;
                model.isSelected = NO;
                NSArray *selectedModels = [NSArray arrayWithArray:tzImagePickerVc.selectedModels];
                for (TZAssetModel *model_item in selectedModels) {
                    if ([[[TZImageManager manager] getAssetIdentifier:model.asset] isEqualToString:[[TZImageManager manager] getAssetIdentifier:model_item.asset]]) {
                        [tzImagePickerVc.selectedModels removeObject:model_item];
                    }
                }
                [weakSelf.photoPickerController refreshBottomToolBarStatus];
            } else {
                // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
                if (tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount) {
                    weakCell.selectPhotoButton.selected = YES;
                    model.isSelected = YES;
                    [tzImagePickerVc.selectedModels addObject:model];
                    [weakSelf.photoPickerController refreshBottomToolBarStatus];
                } else {
                    [tzImagePickerVc showAlertWithTitle:[NSString stringWithFormat:@"你最多只能选择%zd张照片",tzImagePickerVc.maxImagesCount]];
                }
            }
            [UIView showOscillatoryAnimationWithLayer:weakLayer type:TZOscillatoryAnimationToSmaller];
        };

    }
}

- (void)cellTaped:(UITapGestureRecognizer *)tap{
    NSInteger index = tap.view.tag - 100;
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.photoPickerController.navigationController;
//    if (((tzImagePickerVc.sortAscendingByModificationDate && indexPath.row >= _models.count) || (!tzImagePickerVc.sortAscendingByModificationDate && indexPath.row == 0)) && _showTakePhotoBtn)  {
//        [self takePhoto]; return;
//    }
    // preview phote or video / 预览照片或视频
//    NSInteger index = indexPath.row;
//    if (!tzImagePickerVc.sortAscendingByModificationDate && _showTakePhotoBtn) {
//        index = indexPath.row - 1;
//    }
    TZAssetModel *model = _models[index];
    if (model.type == TZAssetModelMediaTypeVideo) {
        if (tzImagePickerVc.selectedModels.count > 0) {
            TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.photoPickerController.navigationController;
            [imagePickerVc showAlertWithTitle:@"选择照片时不能选择视频"];
        } else {
            TZVideoPlayerController *videoPlayerVc = [[TZVideoPlayerController alloc] init];
            videoPlayerVc.model = model;
            [self.photoPickerController.navigationController pushViewController:videoPlayerVc animated:YES];
        }
    } else {
        TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
        photoPreviewVc.currentIndex = index;
        photoPreviewVc.models = _models;
        [self.photoPickerController pushPhotoPrevireViewController:photoPreviewVc];
    }

}

@end
