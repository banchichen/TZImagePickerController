//
//  TZVideoPlayerController.h
//  TZImagePickerController
//
//  Created by 谭真 on 16/1/5.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TZAssetModelProtocol.h"


@interface TZVideoPlayerController : UIViewController

@property (nonatomic, strong) id<TZAssetModel> model;

@end
