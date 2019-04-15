//
//  TZAssetCell.h
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

typedef enum : NSUInteger {
    TZAssetCellTypePhoto = 0,
    TZAssetCellTypeLivePhoto,
    TZAssetCellTypePhotoGif,
    TZAssetCellTypeVideo,
    TZAssetCellTypeAudio,
} TZAssetCellType;

@class TZAssetModel;
@interface TZAssetCell : UICollectionViewCell

@property (weak, nonatomic) UIButton *selectPhotoButton;
@property (nonatomic, strong) TZAssetModel *model;
@property (nonatomic, copy) void (^didSelectPhotoBlock)(BOOL);
@property (nonatomic, assign) TZAssetCellType type;
@property (nonatomic, assign) BOOL allowPickingGif;
@property (nonatomic, assign) BOOL allowPickingMultipleVideo;
@property (nonatomic, copy) NSString *representedAssetIdentifier;
@property (nonatomic, assign) int32_t imageRequestID;
/// 选择顺序编号
@property (weak, nonatomic) UILabel *selectedNumberLabel;
/// 是否显示选中编号
@property (assign, nonatomic) BOOL showSelectedNumber;

@property (nonatomic, copy) NSString *photoSelImageName;
@property (nonatomic, copy) NSString *photoDefImageName;

@property (nonatomic, assign) BOOL showSelectBtn;
@property (assign, nonatomic) BOOL allowPreview;
/// 相册图片选中按钮图片
@property (nonatomic, copy) UIImage *selectImage;
@property (nonatomic, strong) UIColor *mainColor;

@end


@class TZAlbumModel;

@interface TZAlbumCell : UITableViewCell

@property (nonatomic, strong) TZAlbumModel *model;
@property (weak, nonatomic) UIButton *selectedCountButton;

@end


@interface TZAssetCameraCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end
