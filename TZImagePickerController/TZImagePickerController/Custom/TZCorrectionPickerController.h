//
//  TZCorrectionPickerController.h
//  DivePlusApp
//
//  Created by Dinglong Duan on 2018/10/22.
//  Copyright © 2018 Dive+. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TZPhotoPickerController.h"

@class TZAlbumModel;
@interface TZCorrectionPickerController : UIViewController

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) NSInteger columnNumber;
@property (nonatomic, strong) TZAlbumModel *model;

- (void)checkSelectedModels;
- (void)refreshBottomToolBarStatus;

@end
