//
//  TZPhotoPickerController.h
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TZAlbumModel;
@class TZAlbumPickerController;
@interface TZPhotoPickerController : UIViewController

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) NSInteger columnNumber;
@property (nonatomic, strong) TZAlbumModel *model;

@property (nonatomic, strong) TZAlbumPickerController *albumPicker;

/// 刷新数据
- (void)reloadImageData;

@end


@interface TZCollectionView : UICollectionView

@end
