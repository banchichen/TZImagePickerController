//
//  LZImageCropping.h
//  CroppingImage
//
//  Created by 刘志雄 on 2017/12/25.
//  Copyright © 2017年 刘志雄. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LZImageCropping;
@protocol LZImageCroppingDelegate <NSObject>

-(void)lzImageCroppingDidCancle:(LZImageCropping *)cropping;
-(void)lzImageCropping:(LZImageCropping *)cropping didCropImage:(UIImage *)image;

@end

@interface LZImageCropping : UIViewController

@property(nonatomic,weak)id<LZImageCroppingDelegate>delegate;

/**
 裁剪的图片
 */
@property(nonatomic,strong)UIImage *image;

/**
 裁剪区域
 */
@property(nonatomic,assign)CGSize cropSize;

//是否裁剪成圆形
@property(nonatomic,assign)BOOL isRound;

@end
