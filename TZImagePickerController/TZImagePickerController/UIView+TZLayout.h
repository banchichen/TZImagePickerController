//
//  UIView+TZLayout.h
//  TZImagePickerController
//
//  Created by 谭真 on 15/2/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    TZOscillatoryAnimationToBigger,
    TZOscillatoryAnimationToSmaller,
} TZOscillatoryAnimationType;

@interface UIView (TZLayout)

@property (nonatomic) CGFloat tz_left;        ///< Shortcut for frame.origin.x.
@property (nonatomic) CGFloat tz_top;         ///< Shortcut for frame.origin.y
@property (nonatomic) CGFloat tz_right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic) CGFloat tz_bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic) CGFloat tz_width;       ///< Shortcut for frame.size.width.
@property (nonatomic) CGFloat tz_height;      ///< Shortcut for frame.size.height.
@property (nonatomic) CGFloat tz_centerX;     ///< Shortcut for center.x
@property (nonatomic) CGFloat tz_centerY;     ///< Shortcut for center.y
@property (nonatomic) CGPoint tz_origin;      ///< Shortcut for frame.origin.
@property (nonatomic) CGSize  tz_size;        ///< Shortcut for frame.size.

+ (void)showOscillatoryAnimationWithLayer:(CALayer *)layer type:(TZOscillatoryAnimationType)type;

@end
