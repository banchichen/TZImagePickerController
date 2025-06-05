//
//  TZCorrectionPickerController.m
//  DivePlusApp
//
//  Created by Dinglong Duan on 2018/10/22.
//  Copyright © 2018 Dive+. All rights reserved.
//

#import "TZCorrectionPickerController.h"
#import "TZImagePickerController.h"
#import "TZPhotoPreviewController.h"
#import "TZAssetCell.h"
#import "TZAssetModel.h"
#import "UIView+TZLayout.h"
#import "TZImageManager.h"
#import "TZVideoPlayerController.h"
#import "TZGifPhotoPreviewController.h"
#import "TZLocationManager.h"
#import "VideoEditViewController.h"
#import "TZImageCorrectionPreviewViewController.h"
#import "PureLayout.h"
#import "Utils.h"
#import "ImageProcessor.h"
#import "UserService.h"
#import "WebViewController.h"
#import "CommunityExploreListViewController.h"
#import <AVOSCloud/AVOSCloud.h>
#import "NewVipViewController.h"
#import "DPThemeConfigure.h"
#import "PHAssetResource+Safe.h"

@interface TZCorrectionPickerController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIAlertViewDelegate> {
    NSMutableArray *_models;
    
    UIView *_bottomToolBar;
    UIImageView *_numberImageView;
    UILabel *_numberLabel;
    UIView *_divideLine;
    
    BOOL _shouldScrollToBottom;
    
    CGFloat _offsetItemCount;
}
@property CGRect previousPreheatRect;
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;
@property (nonatomic, strong) TZCollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UIImagePickerController *imagePickerVc;
@property (strong, nonatomic) CLLocation *location;

// 色彩还原按钮
@property (strong, nonatomic) UIButton* autoColorButton;

// 批量按钮和单张按钮
@property (strong, nonatomic) UIBarButtonItem* batchBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem* singleBarButtonItem;

@end

static CGSize AssetGridThumbnailSize;
static CGFloat itemMargin = 5;

@implementation TZCorrectionPickerController

- (UIBarButtonItem *)batchBarButtonItem
{
    if (!_batchBarButtonItem) {
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        UIButton* batchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        batchButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [batchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [batchButton setTitle:[NSString stringWithFormat:@" %@", tzImagePickerVc.batchBtnTitleStr] forState:UIControlStateNormal];
        [batchButton setImage:[UIImage imageNamed:@"VIP_logo"] forState:UIControlStateNormal];
        [batchButton addTarget:self action:@selector(batchButtonClick) forControlEvents:UIControlEventTouchUpInside];
        
        CGSize titleSize = [batchButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:batchButton.titleLabel.font.fontName size:batchButton.titleLabel.font.pointSize]}];
        CGFloat width = titleSize.width + 20;
        CGFloat height = titleSize.height + 10;
        batchButton.frame = CGRectMake(0, 0, width, height);
        
        _batchBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:batchButton];
    }
    return _batchBarButtonItem;
}

- (UIBarButtonItem *)singleBarButtonItem
{
    if (!_singleBarButtonItem) {
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        UIButton* singleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        singleButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [singleButton setTitleColor:[DPThemeConfigure shareInstance].BrandColor forState:UIControlStateNormal];
        [singleButton setTitle:[NSString stringWithFormat:@"%@", tzImagePickerVc.singleBtnTitleStr] forState:UIControlStateNormal];
        [singleButton addTarget:self action:@selector(batchButtonClick) forControlEvents:UIControlEventTouchUpInside];
        
        CGSize titleSize = [singleButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:singleButton.titleLabel.font.fontName size:singleButton.titleLabel.font.pointSize]}];
        CGFloat width = titleSize.width + 3;
        CGFloat height = titleSize.height + 10;
        singleButton.frame = CGRectMake(0, 0, width, height);
        
        _singleBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:singleButton];
    }
    return _singleBarButtonItem;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (UIImagePickerController *)imagePickerVc {
    if (_imagePickerVc == nil) {
        _imagePickerVc = [[UIImagePickerController alloc] init];
        _imagePickerVc.delegate = self;
        // set appearance / 改变相册选择页的导航栏外观
        _imagePickerVc.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
        _imagePickerVc.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
        UIBarButtonItem *tzBarItem, *BarItem;
        tzBarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[TZImagePickerController class]]];
        BarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
        
        NSDictionary *titleTextAttributes = [tzBarItem titleTextAttributesForState:UIControlStateNormal];
        [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
    return _imagePickerVc;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.isFirstAppear = YES;
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    _isSelectOriginalPhoto = tzImagePickerVc.isSelectOriginalPhoto;
    _shouldScrollToBottom = YES;
    self.view.backgroundColor = [DPThemeConfigure shareInstance].MainBackgroundColor;
    self.navigationItem.title = _model.name;
    if (tzImagePickerVc.allowPickingVideo) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        BOOL isVIP = [UserService sharedInstance].didLogin ? [UserService sharedInstance].currentUser.isVIP : NO;
        self.navigationItem.rightBarButtonItem = (tzImagePickerVc.isBatchMode && isVIP) ? self.singleBarButtonItem : self.batchBarButtonItem;
    }
    
    if (tzImagePickerVc.navLeftBarButtonSettingBlock) {
        UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        leftButton.frame = CGRectMake(0, 0, 44, 44);
        [leftButton addTarget:self action:@selector(navLeftBarButtonClick) forControlEvents:UIControlEventTouchUpInside];
        tzImagePickerVc.navLeftBarButtonSettingBlock(leftButton);
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    }
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)batchButtonClick
{
    NSString* reportKey;
    BOOL isVIP = [UserService sharedInstance].didLogin ? [UserService sharedInstance].currentUser.isVIP : NO;
    if (isVIP) {
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        if (tzImagePickerVc.isBatchMode) {
            for (int i = 0; i < tzImagePickerVc.selectedModels.count; i++) {
                TZAssetModel* model = tzImagePickerVc.selectedModels[i];
                model.isSelected = NO;
            }
            [tzImagePickerVc.selectedModels removeAllObjects];
            [self refreshBottomToolBarStatus];
        }
        tzImagePickerVc.isBatchMode = !tzImagePickerVc.isBatchMode;
        self.navigationItem.rightBarButtonItem = tzImagePickerVc.isBatchMode ? self.singleBarButtonItem : self.batchBarButtonItem;
        tzImagePickerVc.maxImagesCount = tzImagePickerVc.isBatchMode ? ([Utils lessThaniPhone6s] ? 30 : 60) : 1;
        tzImagePickerVc.showSelectBtn = tzImagePickerVc.isBatchMode ? YES : NO;
        [self.collectionView reloadData];
        
        [DPAnalytics event:@"ColorCorrectionBatchButtonClick" label:tzImagePickerVc.isBatchMode?@"VIPBatch":@"VIPSingle"];
    }
    else {
        if ([UserService sharedInstance].didLogin) {
            [NewVipViewController showIn:self type:VipPowerBatchProcess];
            [DPAnalytics event:@"ColorCorrectionBatchButtonClick" label:@"GetVIP"];
        }
        else {
            [[UserService sharedInstance] showLoginPageOnVC:self WithType:LoginFromVIP];
            
            [DPAnalytics event:@"ColorCorrectionBatchButtonClick" label:@"GuestLogin"];
        }
    }
}

- (void)fetchAssetModels {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_isFirstAppear && !_model.models.count) {
        [tzImagePickerVc showProgressHUD];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!tzImagePickerVc.sortAscendingByModificationDate && _isFirstAppear && _model.isCameraRoll) {
            [[TZImageManager manager] getCameraRollAlbum:tzImagePickerVc.allowPickingVideo allowPickingImage:tzImagePickerVc.allowPickingImage needFetchAssets:YES completion:^(TZAlbumModel *model) {
                _model = model;
                _models = [NSMutableArray arrayWithArray:_model.models];
                [self initSubviews];
            }];
        } else {
            if (_isFirstAppear) {
                [[TZImageManager manager] getAssetsFromFetchResult:_model.result completion:^(NSArray<TZAssetModel *> *models) {
                    _models = [NSMutableArray arrayWithArray:models];
                    [self initSubviews];
                }];
            } else {
                _models = [NSMutableArray arrayWithArray:_model.models];
                [self initSubviews];
            }
        }
    });
}

- (void)initSubviews {
    dispatch_async(dispatch_get_main_queue(), ^{
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        [tzImagePickerVc hideProgressHUD];
        
        [self checkSelectedModels];
        [self configCollectionView];
        _collectionView.hidden = YES;
        [self configBottomToolBar];
        
        [self scrollCollectionViewToBottom];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Determine the size of the thumbnails to request from the PHCachingImageManager
    CGFloat scale = 2.0;
    if ([UIScreen mainScreen].bounds.size.width > 600) {
        scale = 1.0;
    }
    CGSize cellSize = ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
    
    if (!_models) {
        [self fetchAssetModels];
    }
    
    [self refreshBottomToolBarStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    tzImagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)configCollectionView {
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[TZCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    _collectionView.backgroundColor = [DPThemeConfigure shareInstance].MainBackgroundColor;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceHorizontal = NO;
    _collectionView.contentInset = UIEdgeInsetsMake(itemMargin, itemMargin, itemMargin, itemMargin);
    
    _collectionView.contentSize = CGSizeMake(self.view.tz_width, ((_model.count + self.columnNumber - 1) / self.columnNumber) * self.view.tz_width);
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[TZAssetCell class] forCellWithReuseIdentifier:@"TZAssetCell"];
    [_collectionView registerClass:[TZAssetCameraCell class] forCellWithReuseIdentifier:@"TZAssetCameraCell"];
}


- (void)configBottomToolBar {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    // 底部工具栏
    _bottomToolBar = [[UIView alloc] initWithFrame:CGRectZero];
    CGFloat rgb = 253 / 255.0;
    _bottomToolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
    
    [self.view addSubview:_bottomToolBar];
    _bottomToolBar.hidden = YES;
    
    // 色彩还原按钮
    self.autoColorButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.autoColorButton configureForAutoLayout];
    self.autoColorButton.backgroundColor = [Utils colorWithHexString:@"1FA0F1"];
    [self.autoColorButton setTitle:[NSString stringWithFormat:@" %@", DPLocal(@"CTAssetsPageViewController_autoColorButton")] forState:UIControlStateNormal];
    [self.autoColorButton.titleLabel setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]];
    [self.autoColorButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.autoColorButton setImage:[UIImage imageNamed:@"iconColorCorrectionAutoColor"] forState:UIControlStateNormal];
    self.autoColorButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.autoColorButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.autoColorButton.layer.cornerRadius = 3;
    self.autoColorButton.layer.masksToBounds = YES;
    
    [self.autoColorButton addTarget:self action:@selector(autoColorButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [_bottomToolBar addSubview:self.autoColorButton];
    
    [self.autoColorButton autoSetDimension:ALDimensionHeight toSize:35];
    [self.autoColorButton autoSetDimension:ALDimensionWidth toSize:180];
    [self.autoColorButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
    [self.autoColorButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    // 选择了多少张图片的视图
    _numberImageView = [[UIImageView alloc] init];
    _numberImageView.layer.cornerRadius = 15;
    _numberImageView.layer.masksToBounds = YES;
    _numberImageView.hidden = tzImagePickerVc.selectedModels.count <= 0;
    _numberImageView.backgroundColor = tzImagePickerVc.iconThemeColor;
    [_bottomToolBar addSubview:_numberImageView];

    _numberLabel = [[UILabel alloc] init];
    _numberLabel.font = [UIFont systemFontOfSize:15];
    _numberLabel.textColor = [UIColor whiteColor];
    _numberLabel.textAlignment = NSTextAlignmentCenter;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",tzImagePickerVc.selectedModels.count];
    _numberLabel.hidden = tzImagePickerVc.selectedModels.count <= 0;
    _numberLabel.backgroundColor = [UIColor clearColor];
    [_bottomToolBar addSubview:_numberLabel];

    // 分割线
    _divideLine = [UIView newAutoLayoutView];
    CGFloat rgb2 = 222 / 255.0;
    _divideLine.backgroundColor = [UIColor colorWithRed:rgb2 green:rgb2 blue:rgb2 alpha:1.0];
    [_bottomToolBar addSubview:_divideLine];
    
    [_divideLine autoSetDimension:ALDimensionHeight toSize:1];
    [_divideLine autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [_divideLine autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_divideLine autoPinEdgeToSuperviewEdge:ALEdgeRight];
}

- (void)autoColorButtonTouchUpInside
{
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    TZImageCorrectionPreviewViewController *photoPreviewVc = [[TZImageCorrectionPreviewViewController alloc] init];
    photoPreviewVc.currentIndex = 0;
    photoPreviewVc.models = tzImagePickerVc.selectedModels;
    
    for (int i = 0; i < photoPreviewVc.models.count; i++) {
        TZAssetModel* model = photoPreviewVc.models[i];
        model.showCorrectedImage = YES;
    }
    
    [self pushPhotoPrevireViewController:photoPreviewVc];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    CGFloat top = 0;
    CGFloat collectionViewHeight = 0;
    CGFloat naviBarHeight = self.navigationController.navigationBar.tz_height;
    BOOL isStatusBarHidden = [UIApplication sharedApplication].isStatusBarHidden;
    CGFloat toolBarHeight = [TZCommonTools tz_isIPhoneX] ? 34 + 55 : 55;
    if (self.navigationController.navigationBar.isTranslucent) {
        top = naviBarHeight;
        if (!isStatusBarHidden) top += [TZCommonTools tz_statusBarHeight];
        collectionViewHeight = (!_bottomToolBar.hidden) ? self.view.tz_height - toolBarHeight - top : self.view.tz_height - top;;
    } else {
        collectionViewHeight = (!_bottomToolBar.hidden) ? self.view.tz_height - toolBarHeight : self.view.tz_height;
    }
    _collectionView.frame = CGRectMake(0, top, self.view.tz_width, collectionViewHeight);
    CGFloat itemWH = (self.view.tz_width - (self.columnNumber + 1) * itemMargin) / self.columnNumber;
    _layout.itemSize = CGSizeMake(itemWH, itemWH);
    _layout.minimumInteritemSpacing = itemMargin;
    _layout.minimumLineSpacing = itemMargin;
    [_collectionView setCollectionViewLayout:_layout];
    if (_offsetItemCount > 0) {
        CGFloat offsetY = _offsetItemCount * (_layout.itemSize.height + _layout.minimumLineSpacing);
        [_collectionView setContentOffset:CGPointMake(0, offsetY)];
    }
    
    CGFloat toolBarTop = 0;
    if (!self.navigationController.navigationBar.isHidden) {
        toolBarTop = self.view.tz_height - toolBarHeight;
    } else {
        CGFloat navigationHeight = naviBarHeight;
        navigationHeight += [TZCommonTools tz_statusBarHeight];
        toolBarTop = self.view.tz_height - toolBarHeight - navigationHeight;
    }
    _bottomToolBar.frame = CGRectMake(0, toolBarTop, self.view.tz_width, toolBarHeight);
    CGFloat previewWidth = [tzImagePickerVc.previewBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} context:nil].size.width + 2;
    if (!tzImagePickerVc.allowPreview) {
        previewWidth = 0.0;
    }

    _numberImageView.frame = CGRectMake(self.view.tz_centerX + 110, 12.5, 30, 30);
    _numberLabel.frame = _numberImageView.frame;
    
    [TZImageManager manager].columnNumber = [TZImageManager manager].columnNumber;
    [self.collectionView reloadData];
//    [self refreshBottomToolBarStatus];
}

#pragma mark - Notification

- (void)didChangeStatusBarOrientationNotification:(NSNotification *)noti {
    _offsetItemCount = _collectionView.contentOffset.y / (_layout.itemSize.height + _layout.minimumLineSpacing);
}

#pragma mark - Click Event
- (void)navLeftBarButtonClick{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doneButtonClick {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    // 1.6.8 判断是否满足最小必选张数的限制
    if (tzImagePickerVc.minImagesCount && tzImagePickerVc.selectedModels.count < tzImagePickerVc.minImagesCount) {
        NSString *title = DPLocalFormat(@"ColorCorrection_MinSelection", [NSString stringWithFormat:@"%zd", tzImagePickerVc.minImagesCount]);
        [tzImagePickerVc showAlertWithTitle:title];
        return;
    }

    [tzImagePickerVc showProgressHUD];
    NSMutableArray *assets = [NSMutableArray array];
    NSMutableArray *photos;
    NSMutableArray *infoArr;
    [self didGetAllPhotos:photos assets:assets infoArr:infoArr];
}

- (void)didGetAllPhotos:(NSArray *)photos assets:(NSArray *)assets infoArr:(NSArray *)infoArr {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    [tzImagePickerVc hideProgressHUD];
    
    if (tzImagePickerVc.autoDismiss) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [self callDelegateMethodWithPhotos:photos assets:assets infoArr:infoArr];
        }];
    } else {
        [self callDelegateMethodWithPhotos:photos assets:assets infoArr:infoArr];
    }
}

- (void)callDelegateMethodWithPhotos:(NSArray *)photos assets:(NSArray *)assets infoArr:(NSArray *)infoArr {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if ([tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:)]) {
        [tzImagePickerVc.pickerDelegate imagePickerController:tzImagePickerVc didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto];
    }
    if ([tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:infos:)]) {
        [tzImagePickerVc.pickerDelegate imagePickerController:tzImagePickerVc didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto infos:infoArr];
    }
    if (tzImagePickerVc.didFinishPickingPhotosHandle) {
        tzImagePickerVc.didFinishPickingPhotosHandle(photos,assets,_isSelectOriginalPhoto);
    }
    if (tzImagePickerVc.didFinishPickingPhotosWithInfosHandle) {
        tzImagePickerVc.didFinishPickingPhotosWithInfosHandle(photos,assets,_isSelectOriginalPhoto,infoArr);
    }
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // the cell lead to take a picture / 去拍照的cell
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    // the cell dipaly photo or video / 展示照片或视频的cell
    TZAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCell" forIndexPath:indexPath];
    cell.allowPickingMultipleVideo = tzImagePickerVc.allowPickingMultipleVideo;
    cell.photoDefImage = tzImagePickerVc.photoDefImage;
    cell.photoSelImage = tzImagePickerVc.photoSelImage;
    TZAssetModel *model;
    model = _models[indexPath.row];
    cell.allowPickingGif = tzImagePickerVc.allowPickingGif;
    cell.model = model;
//    if (model.isSelected && tzImagePickerVc.showSelectedIndex) {
//        cell.index = [tzImagePickerVc.selectedAssetIds indexOfObject:model.asset.localIdentifier] + 1;
//    }
    cell.showSelectBtn = tzImagePickerVc.showSelectBtn;
    cell.allowPreview = tzImagePickerVc.allowPreview;
    
    __weak typeof(cell) weakCell = cell;
    __weak typeof(self) weakSelf = self;
    __weak typeof(_numberImageView.layer) weakLayer = _numberImageView.layer;
    cell.didSelectPhotoBlock = ^(BOOL isSelected) {
        __strong typeof(weakCell) strongCell = weakCell;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakLayer) strongLayer = weakLayer;
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)strongSelf.navigationController;
        // 1. cancel select / 取消选择
        if (isSelected) {
            strongCell.selectPhotoButton.selected = NO;
            model.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:tzImagePickerVc.selectedModels];
            for (TZAssetModel *model_item in selectedModels) {
                if ([model.asset.localIdentifier isEqualToString:model_item.asset.localIdentifier]) {
                    [tzImagePickerVc.selectedModels removeObject:model_item];
                    break;
                }
            }
            [strongSelf refreshBottomToolBarStatus];
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount) {
                strongCell.selectPhotoButton.selected = YES;
                model.isSelected = YES;
                [tzImagePickerVc addSelectedModel:model];
                [strongSelf refreshBottomToolBarStatus];
            } else {
                NSString *title = DPLocalFormat(@"ColorCorrection_MaxSelection", [NSString stringWithFormat:@"%zd", tzImagePickerVc.maxImagesCount]);
                [tzImagePickerVc showAlertWithTitle:title];
            }
        }
        [UIView showOscillatoryAnimationWithLayer:strongLayer type:TZOscillatoryAnimationToSmaller];
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // take a photo / 去拍照
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    // preview phote or video / 预览照片或视频
    NSInteger index = indexPath.row;
    TZAssetModel *model = _models[index];
    if (model.type == TZAssetModelMediaTypePhoto || model.type == TZAssetModelMediaTypeLivePhoto) {
        TZImageCorrectionPreviewViewController *photoPreviewVc = [[TZImageCorrectionPreviewViewController alloc] init];
        photoPreviewVc.currentIndex = index;
        photoPreviewVc.models = _models;
        [self pushPhotoPrevireViewController:photoPreviewVc];
    }
    else if (model.type == TZAssetModelMediaTypeVideo) {
//        NSArray *resourceArray = [PHAssetResource assetResourcesForAsset:model.asset];
//        PHAssetResource *assRes = [resourceArray firstObject];
//        BOOL tmp = [[assRes valueForKey:@"isInCloud"] boolValue];
//        BOOL bIsLocallayAvailable = !tmp && [[assRes valueForKey:@"locallyAvailable"] boolValue];
//        // 加载iCloud视频有问题，改为只能edit本地视频
//        if (bIsLocallayAvailable) {
            [VideoEditViewController showVideoEditViewController:model onVC:self];
//        } else {
//            [AlertShowHUD showText:DPLocal(@"ColorCorrection_iCloud")];
//        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
}

#pragma mark - Private Method

- (void)refreshBottomToolBarStatus {
    
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    if (tzImagePickerVc.selectedModels.count == 0) {
        if (_bottomToolBar.hidden != YES) {
            _bottomToolBar.hidden = YES;
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        }
    }
    else {
        if (_bottomToolBar.hidden != NO) {
            _bottomToolBar.hidden = NO;
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        }
    }

    _numberImageView.hidden = tzImagePickerVc.selectedModels.count <= 0;
    _numberLabel.hidden = tzImagePickerVc.selectedModels.count <= 0;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",tzImagePickerVc.selectedModels.count];
}

- (void)pushPhotoPrevireViewController:(TZImageCorrectionPreviewViewController *)photoPreviewVc {
    __weak typeof(self) weakSelf = self;
    photoPreviewVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    [photoPreviewVc setBackButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        [strongSelf.collectionView reloadData];
        [strongSelf refreshBottomToolBarStatus];
    }];
    [photoPreviewVc setDoneButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        [strongSelf doneButtonClick];
    }];
    [photoPreviewVc setDoneButtonClickBlockCropMode:^(UIImage *cropedImage, id asset) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf didGetAllPhotos:@[cropedImage] assets:@[asset] infoArr:nil];
    }];
    [self.navigationController pushViewController:photoPreviewVc animated:YES];
}

- (void)scrollCollectionViewToBottom {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_shouldScrollToBottom && _models.count > 0) {
        NSInteger item = 0;
        if (tzImagePickerVc.sortAscendingByModificationDate) {
            item = _models.count - 1;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            _shouldScrollToBottom = NO;
            _collectionView.hidden = NO;
        });
    } else {
        _collectionView.hidden = NO;
    }
}

- (void)checkSelectedModels {
    NSMutableArray *selectedAssets = [NSMutableArray array];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    for (TZAssetModel *model in tzImagePickerVc.selectedModels) {
        [selectedAssets addObject:model.asset];
    }
    for (TZAssetModel *model in _models) {
        model.isSelected = NO;
        if ([selectedAssets containsObject:model.asset]) {
            model.isSelected = YES;
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // 去设置界面，开启相机访问权限
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
        [imagePickerVc showProgressHUD];
        UIImage *photo = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (photo) {
            [[TZImageManager manager] savePhotoWithImage:photo location:self.location completion:^(PHAsset *asset, NSError *error) {
                if (!error) {
                    [self reloadPhotoArray];
                }
            }];
            self.location = nil;
        }
    }
}

- (void)reloadPhotoArray {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    [[TZImageManager manager] getCameraRollAlbum:tzImagePickerVc.allowPickingVideo allowPickingImage:tzImagePickerVc.allowPickingImage needFetchAssets:NO completion:^(TZAlbumModel *model) {
        _model = model;
        [[TZImageManager manager] getAssetsFromFetchResult:_model.result completion:^(NSArray<TZAssetModel *> *models) {
            [tzImagePickerVc hideProgressHUD];
            
            TZAssetModel *assetModel;
            if (tzImagePickerVc.sortAscendingByModificationDate) {
                assetModel = [models lastObject];
                [_models addObject:assetModel];
            } else {
                assetModel = [models firstObject];
                [_models insertObject:assetModel atIndex:0];
            }
            
            if (tzImagePickerVc.maxImagesCount <= 1) {
                if (tzImagePickerVc.allowCrop) {
                    TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
                    if (tzImagePickerVc.sortAscendingByModificationDate) {
                        photoPreviewVc.currentIndex = _models.count - 1;
                    } else {
                        photoPreviewVc.currentIndex = 0;
                    }
                    photoPreviewVc.models = _models;
                    [self pushPhotoPrevireViewController:photoPreviewVc];
                } else {
                    [tzImagePickerVc.selectedModels addObject:assetModel];
                    [self doneButtonClick];
                }
                return;
            }
            
            if (tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount) {
                assetModel.isSelected = YES;
                [tzImagePickerVc.selectedModels addObject:assetModel];
                [self refreshBottomToolBarStatus];
            }
            _collectionView.hidden = YES;
            [_collectionView reloadData];
            
            _shouldScrollToBottom = YES;
            [self scrollCollectionViewToBottom];
        }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma clang diagnostic pop

@end
