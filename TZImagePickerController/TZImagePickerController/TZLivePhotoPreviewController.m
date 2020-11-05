//
//  TZLivePhotoPreviewController.m
//  TZImagePickerController
//
//  Created by walker on 2020/11/5.
//  Copyright © 2020 谭真. All rights reserved.
//

#import "TZLivePhotoPreviewController.h"
#import <PhotosUI/PhotosUI.h>
#import "TZImagePickerController.h"
#import "TZAssetModel.h"
#import "UIView+Layout.h"
#import "TZImageManager.h"

API_AVAILABLE(ios(9.1))
@interface TZLivePhotoPreviewController () <PHLivePhotoViewDelegate>{
    UIView *_toolBar;
    UIButton *_doneButton;
    UIProgressView *_progress;
    UIStatusBarStyle _originStatusBarStyle;
}

@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (strong, nonatomic) UIImage *coverImage;
@property (assign, nonatomic) BOOL needShowStatusBar;

@end

@implementation TZLivePhotoPreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.needShowStatusBar = ![UIApplication sharedApplication].statusBarHidden;
    self.view.backgroundColor = [UIColor blackColor];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc) {
        self.navigationItem.title = [NSString stringWithFormat:@"Live Photo %@",tzImagePickerVc.previewBtnTitleStr];
    }
    [self configPreviewView];
    [self configBottomToolBar];
    [self configLivePhoto];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _originStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
    [UIApplication sharedApplication].statusBarStyle = _originStatusBarStyle;
}

- (void)configPreviewView {
    
    if (@available(iOS 9.1, *)) {
        self.livePhotoView = [[PHLivePhotoView alloc] initWithFrame:CGRectZero];
        self.livePhotoView.delegate = self;
        [self.view addSubview:self.livePhotoView];
    }
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(signleTapAction)]];
}

- (void)configLivePhoto {
    
    [[TZImageManager manager] getPhotoWithAsset:self.model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (photo) {
            self.coverImage = photo;
        }
    }];
    
    if (self.livePhotoView) {
        
        if (@available(iOS 9.1, *)) {
            [[TZImageManager manager] getLivePhotoWithAsset:self.model.asset completion:^(PHLivePhoto *livePhoto, NSDictionary *info) {
                if (livePhoto) {
                    self.livePhotoView.livePhoto = livePhoto;
                }
            }];
        }
    }
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc) {
        [_doneButton setTitle:tzImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
        [_doneButton setTitleColor:tzImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    } else {
        [_doneButton setTitle:[NSBundle tz_localizedStringForKey:@"Done"] forState:UIControlStateNormal];
        [_doneButton setTitleColor:[UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:1.0] forState:UIControlStateNormal];
    }
    [_toolBar addSubview:_doneButton];
    
    [self.view addSubview:_toolBar];
    
    if (tzImagePickerVc.gifPreviewPageUIConfigBlock) {
        tzImagePickerVc.gifPreviewPageUIConfigBlock(_toolBar, _doneButton);
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    TZImagePickerController *tzImagePicker = (TZImagePickerController *)self.navigationController;
    if (tzImagePicker && [tzImagePicker isKindOfClass:[TZImagePickerController class]]) {
        return tzImagePicker.statusBarStyle;
    }
    return [super preferredStatusBarStyle];
}

#pragma mark - Live Photo View delegate
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TZ_LIVEPHOTO_BEGIN_PLAY_NOTIFICATION" object:livePhotoView];
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TZ_LIVEPHOTO_END_PLAY_NOTIFICATION" object:livePhotoView];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.livePhotoView.frame = self.view.bounds;
    CGFloat toolBarHeight = 44 + [TZCommonTools tz_safeAreaInsets].bottom;
    _toolBar.frame = CGRectMake(0, self.view.tz_height - toolBarHeight, self.view.tz_width, toolBarHeight);
    _doneButton.frame = CGRectMake(self.view.tz_width - 44 - 12, 0, 44, 44);
    
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc.gifPreviewPageDidLayoutSubviewsBlock) {
        tzImagePickerVc.gifPreviewPageDidLayoutSubviewsBlock(_toolBar, _doneButton);
    }
}

#pragma mark - Click Event

- (void)signleTapAction {
    _toolBar.hidden = !_toolBar.isHidden;
    [self.navigationController setNavigationBarHidden:_toolBar.isHidden];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_toolBar.isHidden) {
        [UIApplication sharedApplication].statusBarHidden = YES;
    } else if (tzImagePickerVc.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
}

- (void)doneButtonClick {
    if (self.navigationController) {
        TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
        if (imagePickerVc.autoDismiss) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [self callDelegateMethod];
            }];
        } else {
            [self callDelegateMethod];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            [self callDelegateMethod];
        }];
    }
}

- (void)callDelegateMethod {
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingLivePhoto:sourceAssets:)]) {
        [imagePickerVc.pickerDelegate imagePickerController:imagePickerVc didFinishPickingLivePhoto:self.coverImage sourceAssets:_model.asset];
    }
    if (imagePickerVc.didFinishPickingLivePhotoHandle) {
        imagePickerVc.didFinishPickingLivePhotoHandle(self.coverImage,_model.asset);
    }
}

#pragma clang diagnostic pop

@end
