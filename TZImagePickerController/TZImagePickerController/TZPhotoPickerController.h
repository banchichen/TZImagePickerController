//
//  TZPhotoPickerController.h
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TZAlbumModel;
@interface TZPhotoPickerController : UIViewController

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) NSInteger columnNumber;
@property (nonatomic, strong) TZAlbumModel *model;

- (void)updateAlbum;
@end


@interface TZCollectionView : UICollectionView

@end

@interface TZPhotoPickerTitleView : UIView
@property (assign, nonatomic) BOOL isShowAlbum;
@property (strong, nonatomic) NSString *selectAlbumName;
- (CGSize)getSize;
@end

@interface TZAlbumView : UIView
@property (assign, nonatomic) BOOL isFirstAppear;
@property (weak, nonatomic) UIViewController *photoPickerController;

- (void)configTableView;
@end
