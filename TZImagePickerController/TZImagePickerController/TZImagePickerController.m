//
//  TZImagePickerController.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "TZImagePickerController.h"
#import "TZPhotoPickerController.h"
#import "TZPhotoPreviewController.h"
#import "TZAssetModel.h"
#import "TZAssetCell.h"
#import "UIView+Layout.h"
#import "TZImageManager.h"

@interface TZImagePickerController () {
    NSTimer *_timer;
    UILabel *_tipLable;
    BOOL _pushToPhotoPickerVc;
    
    UIButton *_progressHUD;
    UIView *_HUDContainer;
    UIActivityIndicatorView *_HUDIndicatorView;
    UILabel *_HUDLable;
}
@end

@implementation TZImagePickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationBar.translucent = YES;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    // Default appearance, you can reset these after this method
    // 默认的外观，你可以在这个方法后重置
    self.oKButtonTitleColorNormal   = [UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:1.0];
    self.oKButtonTitleColorDisabled = [UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:0.5];
    
    if (iOS7Later) {
        self.navigationBar.barTintColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:1.0];
        self.navigationBar.tintColor = [UIColor whiteColor];
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
        
    UIBarButtonItem *barItem;
    if (iOS9Later) {
        barItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[TZImagePickerController class]]];
    } else {
        barItem = [UIBarButtonItem appearanceWhenContainedIn:[TZImagePickerController class], nil];
    }
    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
    textAttrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
    textAttrs[NSFontAttributeName] = [UIFont systemFontOfSize:15];
    [barItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
}

- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount delegate:(id<TZImagePickerControllerDelegate>)delegate {
    TZAlbumPickerController *albumPickerVc = [[TZAlbumPickerController alloc] init];
    self = [super initWithRootViewController:albumPickerVc];
    if (self) {
        self.maxImagesCount = maxImagesCount > 0 ? maxImagesCount : 9; // Default is 9 / 默认最大可选9张图片
        self.pickerDelegate = delegate;
        // Allow user picking original photo and video, you also can set No after this method
        // 默认准许用户选择原图和视频, 你也可以在这个方法后置为NO
        _allowPickingOriginalPhoto = YES;
        _allowPickingVideo = YES;
        
        if (![[TZImageManager manager] authorizationStatusAuthorized]) {
            _tipLable = [[UILabel alloc] init];
            _tipLable.frame = CGRectMake(8, 0, self.view.tz_width - 16, 300);
            _tipLable.textAlignment = NSTextAlignmentCenter;
            _tipLable.numberOfLines = 0;
            _tipLable.font = [UIFont systemFontOfSize:16];
            _tipLable.textColor = [UIColor blackColor];
            NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
            if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
            _tipLable.text = [NSString stringWithFormat:@"请在%@的\"设置-隐私-照片\"选项中，\r允许%@访问你的手机相册。",[UIDevice currentDevice].model,appName];
            [self.view addSubview:_tipLable];
            
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange) userInfo:nil repeats:YES];
        } else {
            [self pushToPhotoPickerVc];
        }
    }
    return self;
}

- (void)observeAuthrizationStatusChange {
    if ([[TZImageManager manager] authorizationStatusAuthorized]) {
        [self pushToPhotoPickerVc];
        [_tipLable removeFromSuperview];
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)pushToPhotoPickerVc {
    _pushToPhotoPickerVc = YES;
    if (_pushToPhotoPickerVc) {
        TZPhotoPickerController *photoPickerVc = [[TZPhotoPickerController alloc] init];
        [[TZImageManager manager] getCameraRollAlbum:self.allowPickingVideo completion:^(TZAlbumModel *model) {
            photoPickerVc.model = model;
            [self pushViewController:photoPickerVc animated:YES];
            _pushToPhotoPickerVc = NO;
        }];
    }
}

- (void)showAlertWithTitle:(NSString *)title {
    if (iOS8Later) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [[[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil, nil] show];
    }
}

- (void)showProgressHUD {
    if (!_progressHUD) {
        _progressHUD = [UIButton buttonWithType:UIButtonTypeCustom];
        [_progressHUD setBackgroundColor:[UIColor clearColor]];

        _HUDContainer = [[UIView alloc] init];
        _HUDContainer.frame = CGRectMake((self.view.tz_width - 120) / 2, (self.view.tz_height - 90) / 2, 120, 90);
        _HUDContainer.layer.cornerRadius = 8;
        _HUDContainer.clipsToBounds = YES;
        _HUDContainer.backgroundColor = [UIColor darkGrayColor];
        _HUDContainer.alpha = 0.7;
        
        _HUDIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _HUDIndicatorView.frame = CGRectMake(45, 15, 30, 30);
        
        _HUDLable = [[UILabel alloc] init];
        _HUDLable.frame = CGRectMake(0,40, 120, 50);
        _HUDLable.textAlignment = NSTextAlignmentCenter;
        _HUDLable.text = @"正在处理...";
        _HUDLable.font = [UIFont systemFontOfSize:15];
        _HUDLable.textColor = [UIColor whiteColor];
        
        [_HUDContainer addSubview:_HUDLable];
        [_HUDContainer addSubview:_HUDIndicatorView];
        [_progressHUD addSubview:_HUDContainer];
    }
    [_HUDIndicatorView startAnimating];
    [[UIApplication sharedApplication].keyWindow addSubview:_progressHUD];
}

- (void)hideProgressHUD {
    if (_progressHUD) {
        [_HUDIndicatorView stopAnimating];
        [_progressHUD removeFromSuperview];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (iOS7Later) viewController.automaticallyAdjustsScrollViewInsets = NO;
    if (_timer) { [_timer invalidate]; _timer = nil;}
    
    if (self.childViewControllers.count > 0) {
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(3, 0, 44, 44)];
        [backButton setImage:[UIImage imageNamed:@"navi_back"] forState:UIControlStateNormal];
        backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 0);
        [backButton setTitle:@"返回" forState:UIControlStateNormal];
        backButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [backButton addTarget:self action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    [super pushViewController:viewController animated:animated];
}

@end


@interface TZAlbumPickerController ()<UITableViewDataSource,UITableViewDelegate> {
    UITableView *_tableView;
    NSMutableArray *_albumArr;
}

@end

@implementation TZAlbumPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"照片";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    [self configTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_albumArr) return;
    [self configTableView];
}

- (void)configTableView {
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    [[TZImageManager manager] getAllAlbums:imagePickerVc.allowPickingVideo completion:^(NSArray<TZAlbumModel *> *models) {
        _albumArr = [NSMutableArray arrayWithArray:models];
        
        CGFloat top = 44;
        if (iOS7Later) top += 20;
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, top, self.view.tz_width, self.view.tz_height - top) style:UITableViewStylePlain];
        _tableView.rowHeight = 70;
        _tableView.tableFooterView = [[UIView alloc] init];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerNib:[UINib nibWithNibName:@"TZAlbumCell" bundle:nil] forCellReuseIdentifier:@"TZAlbumCell"];
        [self.view addSubview:_tableView];
    }];
}

#pragma mark - Click Event

- (void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
        [imagePickerVc.pickerDelegate imagePickerControllerDidCancel:imagePickerVc];
    }
    if (imagePickerVc.imagePickerControllerDidCancelHandle) {
        imagePickerVc.imagePickerControllerDidCancelHandle();
    }
}

#pragma mark - UITableViewDataSource && Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albumArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TZAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TZAlbumCell"];
    cell.model = _albumArr[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TZPhotoPickerController *photoPickerVc = [[TZPhotoPickerController alloc] init];
    photoPickerVc.model = _albumArr[indexPath.row];
    [self.navigationController pushViewController:photoPickerVc animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
