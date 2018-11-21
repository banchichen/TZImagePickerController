//
//  ZLEditVideoController.h
//  ZLPhotoBrowser
//
//  Created by long on 2017/9/15.
//  Copyright © 2017年 long. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface ZLEditVideoController : UIViewController

@property (nonatomic, strong) PHAsset *asset;
/// 整个项目主题色
@property (nonatomic, copy) UIColor *mainColor;
/// 整个项目的返回按钮图片
@property(nonatomic,strong)UIImage *backImage;
///封面回调
@property (nonatomic, copy) void (^coverImageBlock)(UIImage *coverImage, NSURL *videoPath);

@end
