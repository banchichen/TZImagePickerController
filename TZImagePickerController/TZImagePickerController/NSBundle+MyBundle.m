//
//  NSBundle+.m
//  TZImagePickerController
//
//  Created by 薛永胜 on 16/4/8.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TZImagePickerController.h"
#import "NSBundle+MyBundle.h"

@implementation NSBundle (MyBundle)

+ (NSBundle *)myBundle {
    return [self bundleWithPath:[self myBundlePath]];
}


+ (NSString *)myBundlePath {
    NSBundle *bundle = [NSBundle bundleForClass:[TZImagePickerController class]];
    return [bundle pathForResource:@"TZImagePickerController" ofType:@"bundle"];
}

@end