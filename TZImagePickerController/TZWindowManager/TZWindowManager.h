//
//  TZWindowManager.h
//  TZImagePickerController
//
//  Created by 刘小白 on 2023/3/7.
//  Copyright © 2023 谭真. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TZWindowManager : NSObject

+ (instancetype)manager NS_SWIFT_NAME(default());

- (UIWindow *)currentWindow;
    
@end

NS_ASSUME_NONNULL_END
