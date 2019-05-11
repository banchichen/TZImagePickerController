//
//  PHAsset+TSExtInfo.m
//  TZImagePickerController
//
//  Created by IMAC on 2019/5/11.
//  Copyright © 2019年 谭真. All rights reserved.
//

#import "PHAsset+TSExtInfo.h"
#import <objc/runtime.h>

@implementation PHAsset (TSExtInfo)

static void *selectedNumberKey = @"selectedNumberKey";

- (void)setSelectedNumber:(NSInteger)selectedNumber {
    objc_setAssociatedObject(self, selectedNumberKey, @(selectedNumber), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSInteger)selectedNumber {
    return [objc_getAssociatedObject(self, selectedNumberKey) integerValue];
}

@end
