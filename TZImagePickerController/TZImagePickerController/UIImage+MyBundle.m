//
//  NSObject+UIImage_MyBundle.m
//  TZImagePickerController
//
//  Created by 薛永胜 on 16/4/8.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "UIImage+MyBundle.h"
#import "NSBundle+MyBundle.h"

@implementation UIImage (MyBundle)

+ (UIImage *)imageNamedWithMyBundle: (NSString *)name {
    return [self imageNamed:name inBundle:[NSBundle myBundle] compatibleWithTraitCollection:nil];
}

@end
