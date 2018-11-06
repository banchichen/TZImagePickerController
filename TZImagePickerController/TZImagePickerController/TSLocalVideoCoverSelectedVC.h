//
//  TSLocalVideoCoverSelectedVC.h
//  ThinkSNSPlus
//
//  Created by SmellOfTime on 2018/7/20.
//  Copyright © 2018年 ZhiYiCX. All rights reserved.

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface TSLocalVideoCoverSelectedVC : UIViewController
///本地视频路径
@property (nonatomic, strong) NSURL *videoPath;
/// 整个项目主题色
@property (nonatomic, copy) UIColor *mainColor;
/// 整个项目的返回按钮图片
@property(nonatomic,strong)UIImage *backImage;
/// 整个项目的视频封面选择框
@property(nonatomic,strong)UIImage *picCoverImage;
///封面回调
@property (nonatomic, copy) void (^coverImageBlock)(UIImage *coverImage, NSURL *videoPath);

@end
