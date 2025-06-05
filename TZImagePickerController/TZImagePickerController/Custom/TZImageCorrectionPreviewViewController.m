//
//  TZImageCorrectionPreviewViewController.m
//  DivePlusApp
//
//  Created by Dinglong Duan on 2018/10/22.
//  Copyright © 2018 Dive+. All rights reserved.
//

#import "TZImageCorrectionPreviewViewController.h"
#import "TZPhotoPreviewCell.h"
#import "TZAssetModel.h"
#import "UIView+TZLayout.h"
#import "TZImagePickerController.h"
#import "TZImageManager.h"
#import "TZImageCropManager.h"
#import "PureLayout.h"
#import "Utils.h"
#import "ImageProcessor.h"
#import "EditControlColorCorrectionViewController.h"
#import "WatermarkViewController.h"
#import "TZPhotoCollectionViewController.h"
#import "SNShareManager.h"
#import "UserService.h"
#import "DPCommunityManager.h"
#import "DPFileUtil.h"
#import "GuidePageforVIPViewController.h"
#import "Masonry.h"
#import "TZCollectionViewFlipsLayout.h"
#import "CacheTool.h"
#import "NewVipViewController.h"


typedef enum : NSUInteger {
    CorrectionStyleCorrectionButton,
    CorrectionStyleAdjustButton,
    CorrectionStyleAdjustBar,
    CorrectionStyleAfterSave,
} CorrectionStyle;

@interface TZImageCorrectionPreviewViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate, EditControlColorCorrectionDelegate> {
    UICollectionView *_collectionView;
    TZCollectionViewFlipsLayout *_layout;
    NSArray *_photosTemp;
    NSArray *_assetsTemp;
    
    UIView *_naviBar;
    UIButton *_backButton;
    UIButton *_selectButton;
    
    CGFloat _offsetItemCount;
}
@property (nonatomic, assign) BOOL isHideNaviBar;

@property (nonatomic, assign) double progress;
@property (strong, nonatomic) id alertView;

@property (strong, nonatomic) UIButton* saveButton;
@property (strong, nonatomic) UIButton* shareButton;
@property (strong, nonatomic) NSLayoutConstraint* shareButtonTailing;
@property (strong, nonatomic) NSLayoutConstraint* shareButtonWidth;

// 底部工具栏
@property (strong, nonatomic) UIView* upperToolBar;
@property (strong, nonatomic) UIButton* watermarkButton;
@property (strong, nonatomic) UILabel *watermarkLbl;
@property (strong, nonatomic) UIButton* compareButton;
@property (strong, nonatomic) UIView* saveCompareImageView;
@property (strong, nonatomic) UIButton* saveCompareImageButton;
@property (strong, nonatomic) UILabel* toCommunityLabel;

@property (strong, nonatomic) UIView* toolBar;
@property (strong, nonatomic) UIButton* autoColorButton;
@property (strong, nonatomic) UIButton* adjustButton;

@property (strong, nonatomic) UIView* adjustView;
@property (strong, nonatomic) UISlider* adjustSlider;
@property (strong, nonatomic) UIButton* adjustOKButton;
@property (strong, nonatomic) UIButton* adjustBackButton;
@property (assign, nonatomic) float adjustStrenth;

@property (strong, nonatomic) MBProgressHUD* hud;

@property (strong, nonatomic) EditControlColorCorrectionViewController* editControlColorCorrectionVC;

@property (assign, nonatomic) CorrectionStyle currentStyle;

@end

@implementation TZImageCorrectionPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor blackColor];
    self.view.backgroundColor = [DPThemeConfigure shareInstance].MainBackgroundColor;
    
    
    // 判断是否是VIP，如果不是，加水印
    if (![UserService sharedInstance].didLogin || ![UserService sharedInstance].currentUser.isVIP) {
        [[ImageProcessor sharedInstance] setRemoveWatermark:NO];
    }
    
    // 过滤数据源（过滤Gif）
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:self.models.count];
    for (TZAssetModel *model in self.models) {
        if (model.type == TZAssetModelMediaTypePhoto) {
            [tmp addObject:model];
        }
    }
    TZAssetModel *model = [self.models objectAtIndex:self.currentIndex];
    self.currentIndex = [tmp indexOfObject:model];
    self.models = [tmp mutableCopy];
    
    [TZImageManager manager].shouldFixOrientation = YES;
    __weak typeof(self) weakSelf = self;
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)weakSelf.navigationController;
    if (!self.models.count) {
        self.models = [NSMutableArray arrayWithArray:_tzImagePickerVc.selectedModels];
        _assetsTemp = [NSMutableArray arrayWithArray:_tzImagePickerVc.selectedAssets];
    }
    [self configCollectionView];
    [self configCustomNaviBar];
    [self configBottomToolBar];
    
    self.view.clipsToBounds = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    // 添加waterMarkBtn抖动通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shakeWaterMarkBtn) name:@"NOTIFICATIONNAME_SHAKE_WATERMARK_IMAGE" object:nil];
    
    _currentStyle = _tzImagePickerVc.isBatchMode ? CorrectionStyleAdjustButton : CorrectionStyleCorrectionButton;
    [self refreshNaviBarAndBottomBarState];
}

- (void)setPhotos:(NSMutableArray *)photos {
    _photos = photos;
    _photosTemp = [NSArray arrayWithArray:photos];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
//    [UIApplication sharedApplication].statusBarHidden = YES;
    if (_currentIndex) [_collectionView setContentOffset:CGPointMake((self.view.tz_width + 20) * _currentIndex, 0) animated:NO];
    [self refreshNaviBarAndBottomBarState];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
    [TZImageManager manager].shouldFixOrientation = NO;
}

//- (BOOL)prefersStatusBarHidden {
//    return YES;
//}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)configCustomNaviBar {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    _naviBar = [[UIView alloc] initWithFrame:CGRectZero];
//    _naviBar.backgroundColor = [UIColor whiteColor];
//    _naviBar.backgroundColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:1.0];
    _naviBar.backgroundColor = [DPThemeConfigure shareInstance].MainBackgroundColor;
    
    _backButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_backButton setImage:[[UIImage tz_imageNamedFromMyBundle:@"navi_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _backButton.tintColor = [UIColor whiteColor];
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_naviBar addSubview:_backButton];
    
    _selectButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_selectButton setImage:[UIImage tz_imageNamedFromMyBundle:tzImagePickerVc.photoDefImageName] forState:UIControlStateNormal];
    [_selectButton setImage:[UIImage tz_imageNamedFromMyBundle:tzImagePickerVc.photoSelImageName] forState:UIControlStateSelected];
    [_selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
    _selectButton.hidden = !tzImagePickerVc.showSelectBtn;
    
    [self.view addSubview:_selectButton];
    [self.view addSubview:_naviBar];
    
    // 保存
    self.saveButton = [[UIButton alloc] init];
//    [self.saveButton configureForAutoLayout];
//    self.saveButton.backgroundColor = [Utils colorWithHexString:@"1FA0F1"];
//    self.saveButton.backgroundColor = [Utils colorWithHexString:@"1FA0F1" AndAlpha:0.7];
//    self.saveButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
//    [self.saveButton setTitle:DPLocal(@"Common_SaveButton") forState:UIControlStateNormal];
//    [self.saveButton.titleLabel setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]];
//    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    self.saveButton.titleLabel.adjustsFontSizeToFitWidth = YES;
//    self.saveButton.layer.cornerRadius = 3;
//    self.saveButton.layer.masksToBounds = YES;
    [self.saveButton setImage:[UIImage imageNamed:@"icon_correction_save"] forState:UIControlStateNormal];
    self.saveButton.imageView.contentMode = UIViewContentModeCenter;
    [self.saveButton addTarget:self action:@selector(saveButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_naviBar addSubview:self.saveButton];
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self->_backButton);
        make.right.mas_equalTo(-18);
        make.height.mas_equalTo(44);
        make.width.mas_equalTo(44);
    }];
    
    self.saveButton.hidden = YES;
    
    // 分享
    self.shareButton = [[UIButton alloc] init];
//    [self.shareButton configureForAutoLayout];
    //    self.shareButton.backgroundColor = [Utils colorWithHexString:@"1FA0F1"];
//    self.shareButton.backgroundColor = [Utils colorWithHexString:@"1FA0F1" AndAlpha:0.7];
//    self.shareButton.backgroundColor = [UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:0.7];
//    //    self.shareButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
//    [self.shareButton setTitle:DPLocal(@"CTAssetsPageViewController_shareButton") forState:UIControlStateNormal];
//    [self.shareButton.titleLabel setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]];
//    [self.shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    self.shareButton.titleLabel.adjustsFontSizeToFitWidth = YES;
//    self.shareButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
//    self.shareButton.layer.cornerRadius = 3;
//    self.shareButton.layer.masksToBounds = YES;
    [self.shareButton setImage:[UIImage imageNamed:@"icon_new_share"] forState:UIControlStateNormal];
    self.shareButton.imageView.contentMode = UIViewContentModeCenter;
    [self.shareButton addTarget:self action:@selector(shareButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_naviBar addSubview:self.shareButton];
    [self.shareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self->_backButton);
        make.right.equalTo(self.saveButton.mas_left).mas_equalTo(-12);
        make.height.mas_equalTo(44);
        make.width.mas_equalTo(44);
    }];
    
//    [self.shareButton autoSetDimension:ALDimensionHeight toSize:32];
//    self.shareButtonWidth = [self.shareButton autoSetDimension:ALDimensionWidth toSize:60];
//    [self.shareButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:12];
//    self.shareButtonTailing = [self.shareButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:12 + 60 + 12];
    
    self.shareButton.hidden = YES;
}

- (void)configBottomToolBar {
    // 工具栏
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
//    static CGFloat rgb = 34 / 255.0;
//    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    _toolBar.backgroundColor = [DPThemeConfigure shareInstance].MainBackgroundColor;
    [self.view addSubview:_toolBar];
    
    // 还原按钮
    self.autoColorButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.autoColorButton configureForAutoLayout];
//    self.autoColorButton.backgroundColor = [Utils colorWithHexString:@"1FA0F1"];
//    self.autoColorButton.backgroundColor = [Utils colorWithHexString:@"1FA0F1" AndAlpha:0.7];
//    self.autoColorButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
    self.autoColorButton.backgroundColor = DLHexColor(@"#86C1D3");
    [self.autoColorButton setTitle:[NSString stringWithFormat:@" %@", DPLocal(@"CTAssetsPageViewController_autoColorButton")] forState:UIControlStateNormal];
    [self.autoColorButton.titleLabel setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]];
    [self.autoColorButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.autoColorButton setImage:[UIImage imageNamed:@"iconColorCorrectionAutoColor"] forState:UIControlStateNormal];
    self.autoColorButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.autoColorButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.autoColorButton.layer.cornerRadius = 3;
    self.autoColorButton.layer.masksToBounds = YES;
    [self.autoColorButton addTarget:self action:@selector(autoColorButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar addSubview:self.autoColorButton];
    
    [self.autoColorButton autoSetDimension:ALDimensionHeight toSize:35];
    [self.autoColorButton autoSetDimension:ALDimensionWidth toSize:180];
    [self.autoColorButton autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:_toolBar withOffset:10];
    [self.autoColorButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    // 调节按钮
    self.adjustButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.adjustButton configureForAutoLayout];
//    self.adjustButton.backgroundColor = [UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:1.0];
//    self.adjustButton.backgroundColor = [UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:0.7];
//    self.adjustButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
    self.adjustButton.backgroundColor = DLHexColor(@"#86C1D3");
    [self.adjustButton setTitle:[NSString stringWithFormat:@" %@", DPLocal(@"CTAssetsPageViewController_adjustButton")] forState:UIControlStateNormal];
    [self.adjustButton.titleLabel setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]];
    [self.adjustButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.adjustButton setImage:[UIImage imageNamed:@"iconColorCorrectionAutoColor"] forState:UIControlStateNormal];
    self.adjustButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.adjustButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.adjustButton.layer.cornerRadius = 3;
    self.adjustButton.layer.masksToBounds = YES;
    [self.adjustButton addTarget:self action:@selector(adjustButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar addSubview:self.adjustButton];
    
    [self.adjustButton autoSetDimension:ALDimensionHeight toSize:35];
    [self.adjustButton autoSetDimension:ALDimensionWidth toSize:180];
    [self.adjustButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
    [self.adjustButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    // 上工具栏
    self.upperToolBar = [UIView newAutoLayoutView];
    self.upperToolBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    
    [self.view addSubview:self.upperToolBar];
    
    [self.upperToolBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_toolBar];
    [self.upperToolBar autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.upperToolBar autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.upperToolBar autoSetDimension:ALDimensionHeight toSize:60];
    
    // 对比按钮
    self.compareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.compareButton configureForAutoLayout];
    self.compareButton.backgroundColor = [UIColor clearColor];
    [self.compareButton setTitle:nil forState:UIControlStateNormal];
    [self.compareButton setImage:[UIImage imageNamed:@"compare_button"] forState:UIControlStateNormal];
    self.compareButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.compareButton addTarget:self action:@selector(compareButtonDown) forControlEvents:UIControlEventTouchDown];
    [self.compareButton addTarget:self action:@selector(compareButtonUp) forControlEvents:UIControlEventTouchUpInside];
    [self.compareButton addTarget:self action:@selector(compareButtonUp) forControlEvents:UIControlEventTouchUpOutside];
    [self.upperToolBar addSubview:self.compareButton];
    
    [self.compareButton autoSetDimension:ALDimensionWidth toSize:30];
    [self.compareButton autoSetDimension:ALDimensionHeight toSize:30];
    [self.compareButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:12];
    [self.compareButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:17];
//    [self.compareButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_toolBar withOffset:-17];
//    [self.compareButton autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:_toolBar withOffset:-17];
    
    // 水印按钮
    self.watermarkButton = [[UIButton alloc] init];
    self.watermarkButton.contentEdgeInsets = UIEdgeInsetsMake(0, 9, 0, 11);
    self.watermarkButton.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 0);
    self.watermarkButton.titleLabel.font = [UIFont fontWithName:PingFang_Bold size:10];
    [self.watermarkButton setTitle:DPLocal(@"Watermark_Lbl_Text") forState:UIControlStateNormal];
    [self.watermarkButton setImage:[UIImage imageNamed:@"icon_correction_close"] forState:UIControlStateNormal];
    self.watermarkButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.watermarkButton addTarget:self action:@selector(watermarkButtonClick) forControlEvents:UIControlEventTouchUpInside];
    self.watermarkButton.layer.cornerRadius = 11.5;
    self.watermarkButton.layer.masksToBounds = YES;
    self.watermarkButton.backgroundColor = DLHexColor(@"#3B3F60");
    [self.upperToolBar addSubview:self.watermarkButton];
    [self.watermarkButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(23);
        make.left.mas_equalTo(15);
        make.top.mas_equalTo(0);
    }];

    
    // 发布到社区选项
//    self.saveCompareImageView = [UIView newAutoLayoutView];
//    self.saveCompareImageView.backgroundColor = [UIColor clearColor];
//    [self.upperToolBar addSubview:self.saveCompareImageView];
//
//    [self.saveCompareImageView autoSetDimension:ALDimensionHeight toSize:20];
//    [self.saveCompareImageView autoSetDimension:ALDimensionWidth toSize:200];
//    [self.saveCompareImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:20];
//    [self.saveCompareImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
//
    self.saveCompareImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.saveCompareImageButton.contentEdgeInsets = UIEdgeInsetsMake(0, 9, 0, 11);
    self.saveCompareImageButton.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 0);
    self.saveCompareImageButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.saveCompareImageButton.layer.cornerRadius = 11.5;
    self.saveCompareImageButton.layer.masksToBounds = YES;
    self.saveCompareImageButton.backgroundColor = DLHexColor(@"#3B3F60");
    self.saveCompareImageButton.titleLabel.font = [UIFont fontWithName:PingFang_Bold size:10];
    [self.saveCompareImageButton addTarget:self action:@selector(saveCompareImageButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.saveCompareImageButton setTitle:DPLocal(@"CTAssetsPageViewController_save_comparison_photos") forState:UIControlStateNormal];
    [self.saveCompareImageButton setTitle:DPLocal(@"CTAssetsPageViewController_save_comparison_photos") forState:UIControlStateSelected];
    [self.saveCompareImageButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveCompareImageButton setImage:[UIImage imageNamed:@"iconRadioUnselected"] forState:UIControlStateNormal];
    [self.saveCompareImageButton setImage:[UIImage imageNamed:@"iconRadioSelected"] forState:UIControlStateSelected];
    self.saveCompareImageButton.selected = [UserService sharedInstance].saveCompareMedia;
    [self.upperToolBar addSubview:self.saveCompareImageButton];
    [self.saveCompareImageButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.height.equalTo(self.watermarkButton);
        make.top.equalTo(self.watermarkButton.mas_bottom).mas_equalTo(9);
    }];
    
    // 强度调节
    self.adjustView = [UIView newAutoLayoutView];
//    self.adjustView.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1];
    self.adjustView.backgroundColor = [DPThemeConfigure shareInstance].MainBackgroundColor;
    [self.view addSubview:self.adjustView];
    
    [self.adjustView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    [self.adjustView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    [self.adjustView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    [self.adjustView autoSetDimension:ALDimensionHeight toSize:[TZCommonTools tz_isIPhoneX] ? 100 + (83 - 49) : 100];
    
    // 强度调节条
    self.adjustSlider = [UISlider newAutoLayoutView];
    self.adjustSlider.minimumValue = 0.0;
    self.adjustSlider.maximumValue = 1.5;
    self.adjustSlider.value = 1.0;
    self.adjustSlider.minimumTrackTintColor = [UIColor lightGrayColor];
    self.adjustSlider.maximumTrackTintColor = [UIColor lightGrayColor];
    self.adjustSlider.thumbTintColor = [UIColor whiteColor];
    [self.adjustSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.adjustView addSubview:self.adjustSlider];
    
    [self.adjustSlider autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10];
    [self.adjustSlider autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:10];
    [self.adjustSlider autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:45];
    [self.adjustSlider autoSetDimension:ALDimensionHeight toSize:50];
    
    // 强度OK按钮
    self.adjustOKButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.adjustOKButton configureForAutoLayout];
    [self.adjustOKButton setTitle:DPLocal(@"Common_OKButton") forState:UIControlStateNormal];
    self.adjustOKButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.adjustOKButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.adjustOKButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.adjustOKButton addTarget:self action:@selector(adjustOKButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.adjustView addSubview:self.adjustOKButton];
    
    [self.adjustOKButton autoSetDimension:ALDimensionWidth toSize:40];
    [self.adjustOKButton autoSetDimension:ALDimensionHeight toSize:20];
    [self.adjustOKButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
    [self.adjustOKButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:10];
    
    // 强度返回按钮
    self.adjustBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.adjustBackButton configureForAutoLayout];
    [self.adjustBackButton setTitle:DPLocal(@"Common_BackButton") forState:UIControlStateNormal];
    self.adjustBackButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.adjustBackButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.adjustBackButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.adjustBackButton addTarget:self action:@selector(adjustBackButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.adjustView addSubview:self.adjustBackButton];
    
    [self.adjustBackButton autoSetDimension:ALDimensionWidth toSize:40];
    [self.adjustBackButton autoSetDimension:ALDimensionHeight toSize:20];
    [self.adjustBackButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
    [self.adjustBackButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10];
}

- (void)configCollectionView {
    _layout = [[TZCollectionViewFlipsLayout alloc] init];
    _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.pagingEnabled = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.contentOffset = CGPointMake(0, 0);
    _collectionView.contentSize = CGSizeMake(self.models.count * (self.view.tz_width + 20), 0);
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[TZPhotoPreviewCell class] forCellWithReuseIdentifier:@"TZPhotoPreviewCell"];
    [_collectionView registerClass:[TZVideoPreviewCell class] forCellWithReuseIdentifier:@"TZVideoPreviewCell"];
    [_collectionView registerClass:[TZGifPreviewCell class] forCellWithReuseIdentifier:@"TZGifPreviewCell"];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    CGFloat statusBarHeight = [TZCommonTools tz_isIPhoneX] ? 44 : 20;
    CGFloat naviBarHeight = statusBarHeight + 44;
    _naviBar.frame = CGRectMake(0, 0, self.view.tz_width, naviBarHeight);
    _backButton.frame = CGRectMake(10, [TZCommonTools tz_isIPhoneX] ? 24 + 14 : 14, 44, 44);
    _selectButton.frame = CGRectMake(self.view.tz_width - 54, 10 + naviBarHeight, 42, 42);
    
    CGFloat toolBarHeight = [TZCommonTools tz_isIPhoneX] ? 34 + 55 : 55;
    CGFloat toolBarTop = self.view.tz_height - toolBarHeight;
    
    _layout.itemSize = CGSizeMake(self.view.tz_width + 20, self.view.tz_height - naviBarHeight - toolBarHeight);
    _layout.minimumInteritemSpacing = 0;
    _layout.minimumLineSpacing = 0;
    _collectionView.frame = CGRectMake(-10, naviBarHeight, self.view.tz_width + 20, self.view.tz_height - naviBarHeight - toolBarHeight);
    [_collectionView setCollectionViewLayout:_layout];
    if (_offsetItemCount > 0) {
        CGFloat offsetX = _offsetItemCount * _layout.itemSize.width;
        [_collectionView setContentOffset:CGPointMake(offsetX, 0)];
    }
    if (_tzImagePickerVc.allowCrop) {
        [_collectionView reloadData];
    }
    
    _toolBar.frame = CGRectMake(0, toolBarTop, self.view.tz_width, toolBarHeight);
}

#pragma mark - Notification

- (void)didChangeStatusBarOrientationNotification:(NSNotification *)noti {
    _offsetItemCount = _collectionView.contentOffset.x / _layout.itemSize.width;
}

#pragma mark - Click Event

- (void)autoColorButtonClick
{
    // 只有已经登录的用户才会跳出付费
    if ([UserService sharedInstance].didLogin) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults objectForKey:@"isFirstTapColorCorrectionBtn"]) {
            NSLog(@"第一次进入");
            __weak typeof(self)weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (![UserService sharedInstance].didLogin || ![UserService sharedInstance].currentUser.isVIP) {
                    [DPAnalytics event:@"VIP_GuidePage_Exposure_onPhotoColorCorrectionPage"];
                    [GuidePageforVIPViewController showGuidePageforVIPWithSuper:weakSelf];
                }
            });
        }
        else {
            NSLog(@"不是第一次");
        }
    }
    
    
    [self showCorrectedImage:YES];
    
    _currentStyle = CorrectionStyleAdjustButton;
    [self refreshNaviBarAndBottomBarState];
    
    NSString* identifier = nil;
    if ([UserService sharedInstance].didLogin) {
        identifier = [UserService sharedInstance].currentUser.username;
    }
    
    if (!identifier) {
        identifier = [UserService sharedInstance].deviceToken;
    }
    
    // 通知主页的分享按钮加小红点
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[defaults objectForKey:@"have_clicked_color_correction_process_btn"] boolValue]) {
        //NSLog(@"没点过这个按钮");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"have_used_color_correction_more_than_one_time"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"add_red_dot_if_needed_after_color_correction" object:nil];
        
        
        [defaults setBool:YES forKey:@"have_clicked_color_correction_process_btn"];
    }
    
    [DPAnalytics event:@"button_autocolor_process" label:identifier];
}

- (void)adjustButtonClick
{
    TZAssetModel* model = _models[_currentIndex];
    self.adjustSlider.value = model.strenth;
    self.currentStyle = CorrectionStyleAdjustBar;
    [self refreshNaviBarAndBottomBarState];
}

- (void)compareButtonDown
{
    [self showCorrectedImage:NO];
}

- (void)compareButtonUp
{
    [self showCorrectedImage:YES];
}

- (void)watermarkButtonClick
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Image" bundle:nil];
    WatermarkViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"WatermarkViewController"];
//    TZAssetModel* model = _models[_currentIndex];
    __weak typeof (vc) __vc = vc;
    vc.watermarkUpdatedBlock = ^(UIImage * _Nonnull watermarkedImage) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_currentIndex inSection:0];
        TZPhotoPreviewCell *cell = (TZPhotoPreviewCell *)[self->_collectionView cellForItemAtIndexPath:indexPath];
        cell.previewView.correctedImage = nil;
        [cell reloadImageView];
        [__vc.navigationController popViewControllerAnimated:YES];
    };
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_currentIndex inSection:0];
    TZPhotoPreviewCell *cell = (TZPhotoPreviewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    UIImage* originImage = cell.previewView.originImage;
    float strenth = cell.previewView.tempCorrectedStrenth;
    vc.image = originImage ? [ImageProcessor autoColor:originImage strenth:strenth] : [ImageProcessor autoColor:[UIImage imageNamed:@"sample_image6"] strenth:1.0];
    [self.navigationController pushViewController:vc animated:YES];
    
    [DPAnalytics event:@"WatermarkButtonClick" label:@"Photo"];
}

- (void)saveCompareImageButtonClick
{
    // 改为保存对比图
    self.saveCompareImageButton.selected = !self.saveCompareImageButton.isSelected;
    [[UserService sharedInstance] setSaveCompareMedia:self.saveCompareImageButton.selected];
    
//    if ([UserService sharedInstance].didLogin) {
//        self.saveCompareImageButton.selected = !self.saveCompareImageButton.isSelected;
//        [[UserService sharedInstance] setPublicToCommunity:self.saveCompareImageButton.selected];
//    }
//    else { // 请求登录 点击发布到社区按钮
//        [[UserService sharedInstance] showLoginPageOnVC:self WithType:LoginFromPost];
//        self.saveCompareImageButton.selected = NO;
//    }
}

- (void)sliderValueChanged:(id)slider {
    [DPAnalytics event:@"videoCorrectionSliderValueChanged"];
    
    float strenth = self.adjustSlider.value;
    
//    TZAssetModel* model = _models[_currentIndex];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_currentIndex inSection:0];
    TZPhotoPreviewCell *cell = (TZPhotoPreviewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    [cell.previewView setTempCorrectedStrenth:strenth];
    [cell reloadImageView];
}

- (void)adjustOKButtonClick
{
    float strenth = self.adjustSlider.value;
    TZAssetModel* model = _models[_currentIndex];
    model.strenth = strenth;
    self.currentStyle = CorrectionStyleAdjustButton;
    [self refreshNaviBarAndBottomBarState];
}

- (void)adjustBackButtonClick
{
    TZAssetModel* model = _models[_currentIndex];
    self.adjustSlider.value = model.strenth;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_currentIndex inSection:0];
    TZPhotoPreviewCell *cell = (TZPhotoPreviewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    [cell.previewView setTempCorrectedStrenth:model.strenth];
    [cell reloadImageView];
    
    self.currentStyle = CorrectionStyleAdjustButton;
    [self refreshNaviBarAndBottomBarState];
}

- (void)select:(UIButton *)selectButton {
    TZAssetModel *model = _models[_currentIndex];
    model.isSelected = !selectButton.isSelected;
    [self refreshNaviBarAndBottomBarState];
    if (model.isSelected) {
        [UIView showOscillatoryAnimationWithLayer:selectButton.imageView.layer type:TZOscillatoryAnimationToBigger];
    }
}

- (void)backButtonClick {
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_tzImagePickerVc.isBatchMode) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:DPLocal(@"ColorCorrection_SureQuitBatchEdit") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:DPLocal(@"Common_CancelButton") style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:DPLocal(@"Common_OKButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            for (int i = 0; i < _tzImagePickerVc.selectedModels.count; i++) {
                TZAssetModel* model = _tzImagePickerVc.selectedModels[i];
                model.isSelected = NO;
            }
            [_tzImagePickerVc.selectedModels removeAllObjects];
            
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
        if (self.navigationController.childViewControllers.count < 2) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        [self.navigationController popViewControllerAnimated:YES];
        if (self.backButtonClickBlock) {
            self.backButtonClickBlock(_isSelectOriginalPhoto);
        }
    }
}

- (void)saveButtonClick {
    if (![UserService sharedInstance].didLogin) {
        [[UserService sharedInstance] showLoginPageOnVC:self WithType:LoginFromDefault];
        return;
    }
    
    if (![[CacheTool shareInstance] canUseImageCorrection]) {
        [NewVipViewController showIn:self type:VipPowerPhoto];
        return;
    }
    
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    // 如果图片正在从iCloud同步中,提醒用户
    if (_progress > 0 && _progress < 1 && (_selectButton.isSelected || !_tzImagePickerVc.selectedModels.count )) {
        _alertView = [_tzImagePickerVc showAlertWithTitle:DPLocal(@"SelectPhoto_SyncingFromCloud")];
        return;
    }

    // 如果没有选中过照片 点击确定时选中当前预览的照片
    if (_tzImagePickerVc.selectedModels.count == 0 && _tzImagePickerVc.minImagesCount <= 0) {
        TZAssetModel *model = _models[_currentIndex];
        //        [_tzImagePickerVc.selectedModels addObject:model];
        // 单张处理的模式
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode = MBProgressHUDModeIndeterminate;
        self.hud.label.text = DPLocal(@"CTAssetsPageViewController_savingAutoColor");
        __weak typeof (self) __self = self;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:__self.currentIndex inSection:0];
        TZPhotoPreviewCell *cell = (TZPhotoPreviewCell *)[self->_collectionView cellForItemAtIndexPath:indexPath];
        UIImage* originImage = cell.previewView.originImage;
        float strenth = cell.previewView.tempCorrectedStrenth;
        
        [model processAutoColorSaveWithCompletion:^(BOOL success, NSError *error, UIImage* resultImage) {
            // 不再需要上传到社区，改成保存对比图
//            if (success && [UserService sharedInstance].didLogin && [UserService sharedInstance].publicToCommunity) {
//                [[DPCommunityManager sharedInstance] postImage:resultImage];
//            }
            if (success && [UserService sharedInstance].saveCompareMedia) {
                UIImage* afterImage = originImage ? [ImageProcessor autoColor:originImage strenth:strenth] : [ImageProcessor autoColor:[UIImage imageNamed:@"sample_image6"] strenth:1.0];
                UIImage* doubleImage = [ImageProcessor getCompareImageWithOrigin:originImage AndCorrection:afterImage];
                doubleImage = [[ImageProcessor sharedInstance] tryAddWatermarkToImage:doubleImage];
                if (doubleImage) {
                    [[TZImageManager manager] savePhotoWithImage:doubleImage completion:^(PHAsset *asset, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // 成功了
                            dispatch_async(dispatch_get_main_queue(), ^{
                                __self.hud.mode = MBProgressHUDModeText;
                                __self.hud.label.text = DPLocal(@"ColorCorrection_SavedSuccessfully");
                                __self.currentStyle = CorrectionStyleAfterSave;
                                [__self refreshNaviBarAndBottomBarState];
                                [__self.hud hideAnimated:YES afterDelay:1];
                            });
                        });
                    }];
                   
                }
                else {
                    // 成功了
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __self.hud.mode = MBProgressHUDModeText;
                        __self.hud.label.text = DPLocal(@"ColorCorrection_SavedSuccessfully");
                        __self.currentStyle = CorrectionStyleAfterSave;
                        [__self refreshNaviBarAndBottomBarState];
                        [__self.hud hideAnimated:YES afterDelay:1];
                    });
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        __self.hud.mode = MBProgressHUDModeText;
                        __self.hud.label.text = DPLocal(@"ColorCorrection_SavedSuccessfully");
                        __self.currentStyle = CorrectionStyleAfterSave;
                        [__self refreshNaviBarAndBottomBarState];
                    }
                    else {
                        __self.hud.mode = MBProgressHUDModeText;
                        __self.hud.label.text = [NSString stringWithFormat:@"%@, (code:%ld, description:%@)", DPLocal(@"ColorCorrection_SavedFailed"), error.code, error.description];
                    }
                    [__self.hud hideAnimated:YES afterDelay:1];
                });
            }
            
            
        }];
        
        [DPAnalytics event:@"button_autocolor_save"];
//        NSString* label = [UserService sharedInstance].publicToCommunity ? @"isPublic" : nil;
        NSString* label = [UserService sharedInstance].saveCompareMedia ? @"saveCompareMedia" : nil;
        [DPAnalytics event:@"autocolor_save_with_options" label:label];
    }
    else {
        [DPAnalytics event:@"button_autocolor_save_batch" label:[NSString stringWithFormat:@"%lu", _tzImagePickerVc.selectedModels.count]];
        
        NSString* cacheFolderPath = [DPFileUtil recreateDocumentCacheFolder:COLOR_CORRECTION_SAVE_CACHE_FOLDER];
        
        // 多张处理的模式
        NSMutableArray* selectedModels = [NSMutableArray new];
        for (int i = 0; i < _tzImagePickerVc.selectedModels.count; i++) {
            TZAssetModel* model = _tzImagePickerVc.selectedModels[i];
            if (model.isSelected) {
                [selectedModels addObject:model];
            }
        }
        
        NSMutableArray<TZImageModel*>* results = [NSMutableArray array];
        for (NSInteger i = 0; i < selectedModels.count; i++) {
//            TZImageModel* model = [TZImageModel modelWithImage:nil failed:NO];
            TZImageModel* model = [TZImageModel modelWithImagePath:nil failed:NO];
            [results addObject:model];
        }
        
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
        self.hud.label.text = DPLocal(@"CTAssetsPageViewController_savingAutoColor");
        self.hud.progress = 0;
        
        dispatch_queue_t queue_batch_save_corrected_image = dispatch_queue_create("queue_batch_save_corrected_image", DISPATCH_QUEUE_SERIAL);
        dispatch_async(queue_batch_save_corrected_image, ^{
            for (NSInteger i = 0; i < selectedModels.count; i++) {
                TZAssetModel* model = selectedModels[i];
                
                dispatch_semaphore_t t = dispatch_semaphore_create(0);
                
                [[TZImageManager manager] getOriginalPhotoDataWithAsset:model.asset completion:^(NSData *data, NSDictionary *info, BOOL isDegraded) {
                    @autoreleasepool {
                        if (!data) {
                            dispatch_semaphore_signal(t);
                            return;
                        }
                        
                        UIImage *originImage = [UIImage imageWithData:data];
                        
                        NSDate *creationDate = [model.asset isKindOfClass:[PHAsset class]] ? ((PHAsset*)(model.asset)).creationDate : nil;
                        
                        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
                        NSDictionary *imageInfo = (__bridge NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
                        CFRelease(imageSource);
                        
                        if (!originImage) {
                            
                        }
                        
                        [ImageProcessor saveCorrectedImage:originImage metaData:imageInfo strenth:model.strenth creationDate:creationDate forceFixOrientation:YES completionHandler:^(BOOL success, NSError *error, NSString *localIdentifier, UIImage *resultImage) {
                            
                            BOOL writeFileRet = NO;
                            NSString* imagePath = [cacheFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]]];
                            if (success && resultImage) {
                                UIImage* smallImage = [ImageProcessor scaleImage:resultImage WithMaxLength:1600];
                                NSData* compressImageData = UIImageJPEGRepresentation(smallImage, 0.6);
                                writeFileRet = [compressImageData writeToFile:imagePath atomically:YES];
                            }
                            
                            if (writeFileRet) {
                                results[i].imagePath = imagePath;
                                results[i].image = nil;
                                results[i].isFailed = NO;
                            }
                            else {
                                results[i].image = originImage ? originImage : [UIImage imageNamed:@"general_default_view"];
                                results[i].imagePath = nil;
                                results[i].isFailed = YES;
                            }
                            
                            dispatch_semaphore_signal(t);
                        }];
                    }
                }];
                
                dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.hud.progress = ((float)(i + 1)) / ((float)(_tzImagePickerVc.selectedModels.count));
                });
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.hud.label.text = DPLocal(@"ColorCorrection_SavedSuccessfully");
                [self.hud hideAnimated:YES];
                
                TZPhotoCollectionViewController* collectionViewController = [TZPhotoCollectionViewController new];
                collectionViewController.columnNumber = 4;
                collectionViewController.models = [results copy];
                
                [self.navigationController pushViewController:collectionViewController animated:YES];
            });
        });
    }
}

- (void)shareButtonClick {
    NSString* label = nil;
    ShareFromSource source = ShareFromUnknown;
    if (_currentStyle == CorrectionStyleAdjustBar) {
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        if (tzImagePickerVc.isBatchMode) {
            label = @"BottomViewAutoColor_BatchMode";
        }
        else {
            label = @"BottomViewAutoColor";
        }
        source = ShareFromClickBeforeSave;
    }
    else if (_currentStyle == CorrectionStyleAfterSave) {
        label = @"BottomViewSave";
        source = ShareFromClickAfterSave;
        
    }
    [DPAnalytics event:@"autocolor_share_click" label:label];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_currentIndex inSection:0];
    TZPhotoPreviewCell *cell = (TZPhotoPreviewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    UIImage* originImage = cell.previewView.originImage;
    float strenth = cell.previewView.tempCorrectedStrenth;
    UIImage* afterImage = originImage ? [ImageProcessor autoColor:originImage strenth:strenth] : [ImageProcessor autoColor:[UIImage imageNamed:@"sample_image6"] strenth:1.0];
    
    [[SNShareManager sharedInstance] shareWithOrigin:originImage AndAfter:afterImage AndVC:self From:source];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offSetWidth = scrollView.contentOffset.x;
    offSetWidth = offSetWidth +  ((self.view.tz_width + 20) * 0.5);
    
    NSInteger currentIndex = offSetWidth / (self.view.tz_width + 20);
    
    // 滑动到下一张
    if (currentIndex < _models.count && _currentIndex != currentIndex) {
        TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        
        if (_tzImagePickerVc.isBatchMode) {
            [self showCorrectedImage:YES];
            _currentStyle = CorrectionStyleAdjustButton;
        }
        else {
            TZAssetModel* model = _models[_currentIndex];
            model.strenth = 1.0;
            [self showCorrectedImage:NO];
            _currentStyle = CorrectionStyleCorrectionButton;
        }
        
        _currentIndex = currentIndex;

        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_currentIndex inSection:0];
        TZPhotoPreviewCell *cell = (TZPhotoPreviewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
        cell.model = _models[_currentIndex];
        
        [self refreshNaviBarAndBottomBarState];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"photoPreviewCollectionViewDidScroll" object:nil];
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TZImagePickerController *_tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    TZAssetModel *model = _models[indexPath.row];
    
    TZAssetPreviewCell *cell;
    __weak typeof(self) weakSelf = self;
    if (_tzImagePickerVc.allowPickingMultipleVideo && model.type == TZAssetModelMediaTypeVideo) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZVideoPreviewCell" forIndexPath:indexPath];
    } else if (_tzImagePickerVc.allowPickingMultipleVideo && model.type == TZAssetModelMediaTypePhotoGif && _tzImagePickerVc.allowPickingGif) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZGifPreviewCell" forIndexPath:indexPath];
        TZGifPreviewCell *currentCell = (TZGifPreviewCell *)cell;
        currentCell.previewView.iCloudSyncFailedHandle = ^(id asset, BOOL isSyncFailed) {
            model.iCloudFailed = isSyncFailed;
            [weakSelf.models replaceObjectAtIndex:indexPath.item withObject:model];
        };
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZPhotoPreviewCell" forIndexPath:indexPath];
        TZPhotoPreviewCell *photoPreviewCell = (TZPhotoPreviewCell *)cell;
        photoPreviewCell.cropRect = _tzImagePickerVc.cropRect;
        photoPreviewCell.allowCrop = _tzImagePickerVc.allowCrop;
        __weak typeof(_tzImagePickerVc) weakTzImagePickerVc = _tzImagePickerVc;
        __weak typeof(_collectionView) weakCollectionView = _collectionView;
        __weak typeof(photoPreviewCell) weakCell = photoPreviewCell;
        [photoPreviewCell setImageProgressUpdateBlock:^(double progress) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakTzImagePickerVc) strongTzImagePickerVc = weakTzImagePickerVc;
            __strong typeof(weakCollectionView) strongCollectionView = weakCollectionView;
            __strong typeof(weakCell) strongCell = weakCell;
            strongSelf.progress = progress;
            if (progress >= 1) {
                if (strongSelf.alertView && [strongCollectionView.visibleCells containsObject:strongCell]) {
                    [strongTzImagePickerVc hideAlertView:strongSelf.alertView];
                    strongSelf.alertView = nil;
                }
            }
        }];
    }
    
    cell.model = model;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[TZPhotoPreviewCell class]]) {
        TZPhotoPreviewCell *photoCell = (TZPhotoPreviewCell *)cell;
        [photoCell recoverSubviews];
        [photoCell.previewView setTempCorrectedStrenth:self.adjustSlider.value];
        [photoCell reloadImageView];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[TZPhotoPreviewCell class]]) {
        [(TZPhotoPreviewCell *)cell recoverSubviews];
    } else if ([cell isKindOfClass:[TZVideoPreviewCell class]]) {
        [(TZVideoPreviewCell *)cell pausePlayerAndShowNaviBar];
    }
}

#pragma mark - Private Method

- (void)showCorrectedImage:(BOOL)isCorrected
{
    TZAssetModel* model = _models[_currentIndex];
    model.showCorrectedImage = isCorrected;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_currentIndex inSection:0];
    TZPhotoPreviewCell *cell = (TZPhotoPreviewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    cell.model.showCorrectedImage = isCorrected;
    [cell reloadImageView];
}

- (void)refreshNaviBarAndBottomBarState {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    switch (_currentStyle) {
        case CorrectionStyleCorrectionButton: {
            self.saveButton.hidden = YES;
            self.shareButton.hidden = YES;
            _toolBar.hidden = NO;
            
            self.autoColorButton.hidden = NO;
            self.adjustButton.hidden = YES;
            self.adjustView.hidden = YES;
            
            self.upperToolBar.hidden = YES;
//            self.watermarkButton.hidden = YES;
//            self.compareButton.hidden = YES;
//            self.saveCompareImageView.hidden = YES;
        }
            break;
        case CorrectionStyleAdjustButton: {
            self.shareButtonWidth.constant = 60;
            self.shareButtonTailing.constant = -12 - 60 - 12;
            self.saveButton.hidden = NO;
            self.shareButton.hidden = NO;
            
            _toolBar.hidden = NO;
            self.autoColorButton.hidden = YES;
            self.adjustButton.hidden = NO;
            self.adjustView.hidden = YES;
            
            self.upperToolBar.hidden = NO;
//            self.watermarkButton.hidden = NO;
//            self.compareButton.hidden = NO;
            self.saveCompareImageView.hidden = tzImagePickerVc.isBatchMode;
        }
            break;
        case CorrectionStyleAdjustBar: {
            self.saveButton.hidden = YES;
            self.shareButton.hidden = YES;
            
            _toolBar.hidden = YES;
            self.autoColorButton.hidden = YES;
            self.adjustButton.hidden = YES;
            self.adjustView.hidden = NO;
            
            self.upperToolBar.hidden = YES;
//            self.watermarkButton.hidden = YES;
//            self.compareButton.hidden = YES;
//            self.saveCompareImageView.hidden = YES;
        }
            break;
        case CorrectionStyleAfterSave:
        default: {
            self.shareButtonWidth.constant = 60 + 12 + 60;
            self.shareButtonTailing.constant = -12;
            self.saveButton.hidden = YES;
            self.shareButton.hidden = tzImagePickerVc.isBatchMode;
            
            _toolBar.hidden = YES;
            self.autoColorButton.hidden = YES;
            self.adjustButton.hidden = YES;
            self.adjustView.hidden = YES;
            
            self.upperToolBar.hidden = YES;
        }
            break;
    }
    
    if (_currentStyle == CorrectionStyleAdjustBar) {
        _selectButton.hidden = YES;
        _collectionView.scrollEnabled = NO;
    }
    else {
        _selectButton.hidden = !tzImagePickerVc.showSelectBtn;
        _collectionView.scrollEnabled = YES;
    }
    TZAssetModel* model = _models[_currentIndex];
    _selectButton.selected = model.isSelected;
}

// 抖动放大waterMarkBtn
- (void)shakeWaterMarkBtn {
    
    [UIView showOscillatoryAnimationWithLayer:self.watermarkButton.layer type:TZOscillatoryAnimationToBigger];
    [UIView showOscillatoryAnimationWithLayer:self.watermarkLbl.layer type:TZOscillatoryAnimationToBigger];
    
}

@end
