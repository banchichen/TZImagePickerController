//
//  TZAssetGroupCell.h
//  Pods
//
//  Created by 崔成 on 2016/11/2.
//
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "TZImagePickerController.h"
#import "TZPhotoPickerController.h"
#import "TZVideoPlayerController.h"
#import "TZPhotoPreviewController.h"
@interface TZAssetGroupCell : UICollectionViewCell
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) NSMutableArray *models;
- (void)setGroupCell:(NSArray *)array;
@property (nonatomic, strong) TZPhotoPickerController *photoPickerController;
@end
