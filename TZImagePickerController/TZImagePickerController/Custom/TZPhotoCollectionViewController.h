//
//  TZPhotoCollectionViewController.h
//  DivePlusApp
//
//  Created by Dinglong Duan on 2018/11/7.
//  Copyright © 2018 Dive+. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TZImagePickerController.h"

@interface TZPhotoCollectionViewController : UIViewController

@property (nonatomic, assign) NSInteger columnNumber;
@property (nonatomic, strong) NSArray<TZImageModel*>* models;

@end
