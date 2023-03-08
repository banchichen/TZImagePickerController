//
//  TZWindowManager.m
//  TZImagePickerController
//
//  Created by 刘小白 on 2023/3/7.
//  Copyright © 2023 谭真. All rights reserved.
//

#import "TZWindowManager.h"

@implementation TZWindowManager

+ (instancetype)manager {
    static TZWindowManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (UIWindow *)currentWindow {
    if (@available(iOS 15, *)) {
       __block UIScene * _Nonnull tmpSc;
        [[[UIApplication sharedApplication] connectedScenes] enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.activationState == UISceneActivationStateForegroundActive || obj.activationState == UISceneActivationStateForegroundInactive) {
                tmpSc = obj;
                *stop = YES;
            }
        }];
        UIWindowScene *curWinSc = (UIWindowScene *)tmpSc;
        return curWinSc.keyWindow;
    } else {
        return [[[UIApplication sharedApplication] windows] objectAtIndex:0];
    }
}

@end
