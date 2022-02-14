//
//  TZPhotoCollectionViewController.m
//  DivePlusApp
//
//  Created by Dinglong Duan on 2018/11/7.
//  Copyright © 2018 Dive+. All rights reserved.
//

#import "TZPhotoCollectionViewController.h"
#import "TZPhotoPickerController.h"
#import "TZAssetCell.h"
#import "TZAssetModel.h"
#import "UIView+TZLayout.h"
#import "TZImageManager.h"
#import "PureLayout.h"
#import "Utils.h"
#import "CreatePostTextViewController.h"
#import "NavigationUtils.h"
#import "DPThemeConfigure.h"

@interface TZPhotoCollectionViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    CGFloat _offsetItemCount;
    int _maxCount;
}

@property (nonatomic, strong) NSMutableArray<TZImageModel*>* selectedModels;

@property (nonatomic, strong) TZCollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *layout;

@property (strong, nonatomic) UIView* bottomToolBar;
@property (strong, nonatomic) UIView* divideLine;
@property (strong, nonatomic) UIButton* postButton;
@property (strong, nonatomic) UIButton* cancelButton;
@property (strong, nonatomic) UILabel* descLabel;

@property (strong, nonatomic) UIView* navView;
@property (strong, nonatomic) UILabel* navLabel;

@property (strong, nonatomic) VideoTestViewController* createPostVC;

@end

static CGFloat itemMargin = 5;

@implementation TZPhotoCollectionViewController

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)viewDidLoad {
    [super viewDidLoad];
    _maxCount = 9;
    
    self.view.backgroundColor = [DPThemeConfigure shareInstance].MainBackgroundColor;
    [self configCollectionView];
    [self configBottomToolBar];
    [self configNavBar];
    [DPAnalytics event:Labs_PhotoCorrection_Success];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIApplication sharedApplication].statusBarHidden = YES;
    
//    [self.collectionView reloadData];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)configCollectionView {
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[TZCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    _collectionView.backgroundColor = [DPThemeConfigure shareInstance].MainBackgroundColor;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceHorizontal = NO;
    _collectionView.contentInset = UIEdgeInsetsMake(itemMargin, itemMargin, itemMargin, itemMargin);
    
    _collectionView.contentSize = CGSizeMake(self.view.tz_width, ((self.models.count + self.columnNumber - 1) / self.columnNumber) * self.view.tz_width);
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[TZImageCell class] forCellWithReuseIdentifier:@"TZImageCell"];
}

- (void)configNavBar
{
    self.navView = [UIView newAutoLayoutView];
    self.navView.backgroundColor = [Utils colorWithHexString:@"1FA0F1"];
    [self.view addSubview:self.navView];
    
    [self.navView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.navView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.navView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.navView autoSetDimension:ALDimensionHeight toSize:[TZCommonTools tz_isIPhoneX] ? 34 + 40 : 40];
    
    self.navLabel = [UILabel newAutoLayoutView];
    self.navLabel.text = DPLocal(@"ColorCorrection_SavedSuccessfully");
    self.navLabel.font = [UIFont systemFontOfSize:14];
    self.navLabel.textColor = [UIColor whiteColor];
    self.navLabel.textAlignment = NSTextAlignmentCenter;
    [self.navView addSubview:self.navLabel];
    
    [self.navLabel autoSetDimension:ALDimensionHeight toSize:20];
    [self.navLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10];
    [self.navLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [self.navLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20];
}

- (void)configBottomToolBar
{
    // Bottom容器
    self.bottomToolBar = [UIView newAutoLayoutView];
    self.bottomToolBar.backgroundColor = [UIColor colorWithRed:253 / 255.0 green:253 / 255.0 blue:253 / 255.0 alpha:1.0];
    [self.view addSubview:self.bottomToolBar];
    
    [self.bottomToolBar autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.bottomToolBar autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.bottomToolBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.bottomToolBar autoSetDimension:ALDimensionHeight toSize:[TZCommonTools tz_isIPhoneX] ? 34 + 180 : 180];
    
    // 分割线
    self.divideLine = [UIView newAutoLayoutView];
    self.divideLine.backgroundColor = [UIColor colorWithRed:222 / 255.0 green:222 / 255.0 blue:222 / 255.0 alpha:1.0];
    [self.bottomToolBar addSubview:self.divideLine];
    
    [_divideLine autoSetDimension:ALDimensionHeight toSize:1];
    [_divideLine autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [_divideLine autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_divideLine autoPinEdgeToSuperviewEdge:ALEdgeRight];
    
    // 描述Label
    self.descLabel = [UILabel newAutoLayoutView];
    self.descLabel.backgroundColor = [UIColor clearColor];
    self.descLabel.text = DPLocal(@"VideoEditDoneViewController_SelectionTips");
    self.descLabel.textColor = [UIColor grayColor];
    self.descLabel.font = [UIFont systemFontOfSize:12];
    self.descLabel.textAlignment = NSTextAlignmentCenter;
    [self.bottomToolBar addSubview:self.descLabel];
    
    [self.descLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
    [self.descLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [self.descLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20];
    [self.descLabel autoSetDimension:ALDimensionHeight toSize:20];
    
    // 发布按钮
    self.postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.postButton configureForAutoLayout];
    self.postButton.layer.cornerRadius = 3;
    self.postButton.layer.masksToBounds = YES;
    self.postButton.backgroundColor = [Utils colorWithHexString:@"1FA0F1"];
    [self.postButton setTitle:DPLocal(@"VideoEditDoneViewController_postToCommunityButton") forState:UIControlStateNormal];
    [self.postButton.titleLabel setFont:[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]];
    self.postButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.postButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.postButton addTarget:self action:@selector(postButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolBar addSubview:self.postButton];
    
    [self.postButton autoSetDimension:ALDimensionHeight toSize:50];
    [self.postButton autoSetDimension:ALDimensionWidth toSize:200];
    [self.postButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.postButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.descLabel withOffset:10];
    
    // 取消按钮
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton configureForAutoLayout];
    self.cancelButton.backgroundColor = [UIColor clearColor];
    [self.cancelButton setTitle:DPLocal(@"Common_CancelButton") forState:UIControlStateNormal];
    [self.cancelButton.titleLabel setFont:[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]];
    self.cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolBar addSubview:self.cancelButton];
    
    [self.cancelButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.postButton];
    [self.cancelButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.cancelButton autoSetDimensionsToSize:CGSizeMake(100, 50)];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat top = 0;
    CGFloat collectionViewHeight = 0;
    CGFloat naviBarHeight = [TZCommonTools tz_isIPhoneX] ? 34 + 40 : 40;
    BOOL isStatusBarHidden = [UIApplication sharedApplication].isStatusBarHidden;
    CGFloat toolBarHeight = [TZCommonTools tz_isIPhoneX] ? 34 + 180 : 180;
    
    top = naviBarHeight;
    if (!isStatusBarHidden) top += [TZCommonTools tz_statusBarHeight];
    collectionViewHeight = (!_bottomToolBar.hidden) ? self.view.tz_height - toolBarHeight - top : self.view.tz_height - top;;
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
    
    [self.collectionView reloadData];
}

#pragma mark - Notification

- (void)didChangeStatusBarOrientationNotification:(NSNotification *)noti {
    _offsetItemCount = _collectionView.contentOffset.y / (_layout.itemSize.height + _layout.minimumLineSpacing);
}

#pragma mark - Click Event

- (void)postButtonClick {
    [DPAnalytics event:@"PostButtonClickAfterBatchSave"];
    
    if (_selectedModels.count > 0 && _selectedModels.count <= _maxCount) {
        // 这里不能加HUD不然会出很奇怪的问题
//        MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        hud.mode = MBProgressHUDModeIndeterminate;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSMutableArray* photos = [NSMutableArray new];
            for (int i = 0; i < _selectedModels.count; i++) {
                TZImageModel* model = _selectedModels[i];
                UIImage* image = model.imagePath && model.imagePath.length > 0 ? [UIImage imageWithContentsOfFile:model.imagePath] : nil;
                if (image) {
                    [photos addObject:image];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
//                [hud hideAnimated:NO];
                __weak typeof (self) __self = self;
                [DPAnalytics event:Labs_PhotoCorrection_Create_Post];
                _createPostVC = [CreatePostTextViewController showWithPhotos:[photos copy] AfterPostBlock:^{
                    [__self.createPostVC dismissViewControllerAnimated:YES completion:^{
                        [__self.navigationController dismissViewControllerAnimated:YES completion:^{
                            [[NavigationUtils sharedInstance] showCommunity:COMMUNITY_NAV_TAB_EXPLORE];
                        }];
                    }];
                } AfterCancelBlock:^{
                    [__self.navigationController dismissViewControllerAnimated:YES completion:nil];
                } onVC:self];
            });
        });
    }
    else {
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        // 1.6.8 判断是否满足最小必选张数的限制
        NSString *title = DPLocalFormat(@"ColorCorrection_MinSelection", [NSString stringWithFormat:@"%d", 1]);
        [tzImagePickerVc showAlertWithTitle:title];
    }
}

- (void)cancelButtonClick
{
    [DPAnalytics event:@"CancelButtonClickAfterBatchSave"];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // the cell lead to take a picture / 去拍照的cell
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    // the cell dipaly photo or video / 展示照片或视频的cell
    TZImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZImageCell" forIndexPath:indexPath];
    TZImageModel* model = self.models[indexPath.row];
    if (model.image) {
        [cell setImage:model.image];
    }
    else if (model.imagePath && model.imagePath.length > 0){
        @autoreleasepool {
            [cell setImage:[UIImage imageWithContentsOfFile:model.imagePath]];
        }
    }
    else {
        [cell setImage:[UIImage imageNamed:@"general_default_view"]];
    }
    cell.isSelected = model.isSelected;
    cell.isFailed = model.isFailed;
//    cell.image = model.image;
    
    __weak typeof(cell) weakCell = cell;
    __weak typeof(self) weakSelf = self;
    cell.didSelectPhotoBlock = ^(BOOL isSelected) {
        __strong typeof(weakCell) strongCell = weakCell;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        // 1. cancel select / 取消选择
        if (isSelected) {
            strongCell.isSelected = NO;
            model.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:_selectedModels];
            for (TZImageModel *model_item in selectedModels) {
                if (model == model_item) {
                    [_selectedModels removeObject:model_item];
                    break;
                }
            }
            [strongSelf refreshBottomToolBarStatus];
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (_selectedModels.count < _maxCount) {
                strongCell.isSelected = YES;
                model.isSelected = YES;
                if (!_selectedModels) {
                    _selectedModels = [NSMutableArray new];
                }
                [_selectedModels addObject:model];
                [strongSelf refreshBottomToolBarStatus];
            } else {
                NSString *title = DPLocalFormat(@"ColorCorrection_MaxSelection", [NSString stringWithFormat:@"%d", _maxCount]);
                [tzImagePickerVc showAlertWithTitle:title];
            }
        }
//        [UIView showOscillatoryAnimationWithLayer:strongLayer type:TZOscillatoryAnimationToSmaller];
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 点击选择
//    NSInteger index = indexPath.row;
    
}

#pragma mark - Private Method

- (void)refreshBottomToolBarStatus {
    
//    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
}

#pragma clang diagnostic pop

@end
