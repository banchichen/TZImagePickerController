//
//  TZImageCropManager.m
//  TZImagePickerController
//
//  Created by 谭真 on 2016/12/5.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "TZImageCropManager.h"
#import "UIView+Layout.h"

@implementation TZImageCropManager

/// 裁剪框背景的处理
+ (void)overlayClippingWithView:(UIView *)view cropRect:(CGRect)cropRect containerView:(UIView *)containerView {
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef path = CGPathCreateMutable();
    
    // Left side of _cropBgView
    CGPathAddRect(path, nil, CGRectMake(0, 0, cropRect.origin.x, containerView.tz_height));
    // Right side of _cropBgView
    CGPathAddRect(path, nil, CGRectMake(CGRectGetMaxX(cropRect), 0, view.tz_width - cropRect.origin.x - cropRect.size.width, containerView.tz_height));
    // Top side of _cropBgView
    CGPathAddRect(path, nil, CGRectMake(0, 0, view.tz_width, cropRect.origin.y));
    // Bottom side _cropBgView
    CGPathAddRect(path, nil, CGRectMake(0, CGRectGetMaxY(cropRect), view.tz_width, containerView.tz_height - cropRect.origin.y + cropRect.size.height));
    
    maskLayer.path = path;
    view.layer.mask = maskLayer;
    CGPathRelease(path);
}

/// 获得裁剪后的图片
+ (UIImage *)cropImageView:(UIImageView *)imageView toRect:(CGRect)rect zoomScale:(double)zoomScale containerView:(UIView *)containerView {
    CGAffineTransform transform = CGAffineTransformIdentity;
    // 平移的处理
    CGRect imageViewRect = [imageView convertRect:imageView.bounds toView:containerView];
    CGPoint point = CGPointMake(imageViewRect.origin.x + imageViewRect.size.width / 2, imageViewRect.origin.y + imageViewRect.size.height / 2);
    CGFloat xMargin = containerView.tz_width - CGRectGetMaxX(rect) - rect.origin.x;
    CGPoint zeroPoint = CGPointMake((CGRectGetWidth(containerView.frame) - xMargin) / 2, containerView.center.y);
    CGPoint translation = CGPointMake(point.x - zeroPoint.x, point.y - zeroPoint.y);
    transform = CGAffineTransformTranslate(transform, translation.x, translation.y);
    // 缩放的处理
    transform = CGAffineTransformScale(transform, zoomScale, zoomScale);
    
    CGImageRef imageRef = [self newTransformedImage:transform
                                        sourceImage:imageView.image.CGImage
                                         sourceSize:imageView.image.size
                                        outputWidth:imageView.image.size.width
                                           cropSize:rect.size
                                      imageViewSize:imageView.frame.size];
    UIImage *cropedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return cropedImage;
}

+ (CGImageRef)newTransformedImage:(CGAffineTransform)transform sourceImage:(CGImageRef)sourceImage sourceSize:(CGSize)sourceSize  outputWidth:(CGFloat)outputWidth cropSize:(CGSize)cropSize imageViewSize:(CGSize)imageViewSize {
    CGImageRef source = [self newScaledImage:sourceImage toSize:sourceSize];
    
    CGFloat aspect = cropSize.height/cropSize.width;
    CGSize outputSize = CGSizeMake(outputWidth, outputWidth*aspect);
    
    CGContextRef context = CGBitmapContextCreate(NULL, outputSize.width, outputSize.height, CGImageGetBitsPerComponent(source), 0, CGImageGetColorSpace(source), CGImageGetBitmapInfo(source));
    CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, outputSize.width, outputSize.height));
    
    CGAffineTransform uiCoords = CGAffineTransformMakeScale(outputSize.width / cropSize.width, outputSize.height / cropSize.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, cropSize.width/2.0, cropSize.height / 2.0);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);
    CGContextConcatCTM(context, uiCoords);
    
    CGContextConcatCTM(context, transform);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(-imageViewSize.width/2, -imageViewSize.height/2.0, imageViewSize.width, imageViewSize.height), source);
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGImageRelease(source);
    return resultRef;
}

+ (CGImageRef)newScaledImage:(CGImageRef)source toSize:(CGSize)size {
    CGSize srcSize = size;
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, rgbColorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(rgbColorSpace);
    
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextTranslateCTM(context, size.width/2, size.height/2);
    
    CGContextDrawImage(context, CGRectMake(-srcSize.width/2, -srcSize.height/2, srcSize.width, srcSize.height), source);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return resultRef;
}

@end
