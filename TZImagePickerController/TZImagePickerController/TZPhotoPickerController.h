//
//  TZPhotoPickerController.h
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TZPhotoPreviewController.h"
@class TZAlbumModel;
@interface TZPhotoPickerController : UIViewController

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) TZAlbumModel *model;

@property (nonatomic, copy) void (^backButtonClickHandle)(TZAlbumModel *model);
@property (nonatomic, strong) UIImageView *numberImageView;
@property (nonatomic, strong) UILabel *numberLable;
- (void)refreshBottomToolBarStatus;
- (void)pushPhotoPrevireViewController:(TZPhotoPreviewController *)photoPreviewVc;
@end
