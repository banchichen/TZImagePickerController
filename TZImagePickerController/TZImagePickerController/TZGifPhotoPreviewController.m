//
//  TZGifPhotoPreviewController.m
//  TZImagePickerController
//
//  Created by ttouch on 2016/12/13.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "TZGifPhotoPreviewController.h"
#import "TZImagePickerController.h"
#import "TZAssetModel.h"
#import "UIView+TZLayout.h"
#import "TZPhotoPreviewCell.h"
#import "TZImageManager.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface TZGifPhotoPreviewController () {
    UIView *_toolBar;
    UIButton *_doneButton;
    UIProgressView *_progress;
    
    TZPhotoPreviewView *_previewView;
    
    UIStatusBarStyle _originStatusBarStyle;
}
@property (assign, nonatomic) BOOL needShowStatusBar;
@end

@implementation TZGifPhotoPreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.needShowStatusBar = ![UIApplication sharedApplication].statusBarHidden;
    self.view.backgroundColor = [UIColor blackColor];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc) {
        self.navigationItem.title = [NSString stringWithFormat:@"GIF %@",tzImagePickerVc.previewBtnTitleStr];
    }
    [self configPreviewView];
    [self configBottomToolBar];
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
    _previewView = [[TZPhotoPreviewView alloc] initWithFrame:CGRectZero];
    _previewView.model = self.model;
    __weak typeof(self) weakSelf = self;
    [_previewView setSingleTapGestureBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf signleTapAction];
    }];
    [self.view addSubview:_previewView];
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] init];
    _toolBar.translatesAutoresizingMaskIntoConstraints = NO;
    CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc) {
        [_doneButton setTitle:tzImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
        [_doneButton setTitleColor:tzImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
        _doneButton.titleLabel.font = tzImagePickerVc.doneBtnTitleFont;
    } else {
        [_doneButton setTitle:[NSBundle tz_localizedStringForKey:@"Done"] forState:UIControlStateNormal];
        [_doneButton setTitleColor:[UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:1.0] forState:UIControlStateNormal];
        _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    }
    [_toolBar addSubview:_doneButton];
    
    UILabel *byteLabel = [[UILabel alloc] init];
    byteLabel.textColor = [UIColor whiteColor];
    byteLabel.textAlignment = NSTextAlignmentNatural;
    byteLabel.font = [UIFont systemFontOfSize:13];
    byteLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [[TZImageManager manager] getPhotosBytesWithArray:@[_model] completion:^(NSString *totalBytes) {
        byteLabel.text = totalBytes;
    }];
    [_toolBar addSubview:byteLabel];
    
    [self.view addSubview:_toolBar];
    
    if (tzImagePickerVc.gifPreviewPageUIConfigBlock) {
        tzImagePickerVc.gifPreviewPageUIConfigBlock(_toolBar, _doneButton);
    }
    
    CGFloat toolBarHeight = [TZCommonTools tz_isIPhoneX] ? 44 + (83 - 49) : 44;
    
    NSLayoutConstraint *toolBar_left = [NSLayoutConstraint constraintWithItem:_toolBar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0];
    NSLayoutConstraint *toolBar_right = [NSLayoutConstraint constraintWithItem:_toolBar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0];
    NSLayoutConstraint *toolBar_bottom = [NSLayoutConstraint constraintWithItem:_toolBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *toolBar_height = [NSLayoutConstraint constraintWithItem:_toolBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:toolBarHeight];
    [self.view addConstraints:@[toolBar_left,toolBar_right,toolBar_bottom]];
    [_toolBar addConstraints:@[toolBar_height]];
    
    NSLayoutConstraint *doneButton_right = [NSLayoutConstraint constraintWithItem:_doneButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_toolBar attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-12];
    NSLayoutConstraint *doneButton_top = [NSLayoutConstraint constraintWithItem:_doneButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_toolBar attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    NSLayoutConstraint *doneButton_height = [NSLayoutConstraint constraintWithItem:_doneButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44];
    [_toolBar addConstraints:@[doneButton_right,doneButton_top]];
    [_doneButton addConstraint:doneButton_height];
    
    NSLayoutConstraint *byteLabel_left = [NSLayoutConstraint constraintWithItem:byteLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_toolBar attribute:NSLayoutAttributeLeading multiplier:1.0 constant:10];
    NSLayoutConstraint *byteLabel_top = [NSLayoutConstraint constraintWithItem:byteLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_toolBar attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    NSLayoutConstraint *byteLabel_height = [NSLayoutConstraint constraintWithItem:byteLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44];
    [_toolBar addConstraints:@[byteLabel_left,byteLabel_top]];
    [byteLabel addConstraints:@[byteLabel_height]];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    TZImagePickerController *tzImagePicker = (TZImagePickerController *)self.navigationController;
    if (tzImagePicker && [tzImagePicker isKindOfClass:[TZImagePickerController class]]) {
        return tzImagePicker.statusBarStyle;
    }
    return [super preferredStatusBarStyle];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    _previewView.frame = self.view.bounds;
    _previewView.scrollView.frame = self.view.bounds;
//    CGFloat toolBarHeight = 44 + [TZCommonTools tz_safeAreaInsets].bottom;
//    _toolBar.frame = CGRectMake(0, self.view.tz_height - toolBarHeight, self.view.tz_width, toolBarHeight);
//    [_doneButton sizeToFit];
//    _doneButton.frame = CGRectMake(self.view.tz_width - _doneButton.tz_width - 12, 0, MAX(44, _doneButton.tz_width), 44);
    
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
    UIImage *animatedImage = _previewView.imageView.image;
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingGifImage:sourceAssets:)]) {
        [imagePickerVc.pickerDelegate imagePickerController:imagePickerVc didFinishPickingGifImage:animatedImage sourceAssets:_model.asset];
    }
    if (imagePickerVc.didFinishPickingGifImageHandle) {
        imagePickerVc.didFinishPickingGifImageHandle(animatedImage,_model.asset);
    }
}

#pragma clang diagnostic pop

@end
