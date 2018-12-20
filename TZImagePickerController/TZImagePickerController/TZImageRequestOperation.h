//
//  TZImageRequestOperation.h
//  TZImagePickerControllerFramework
//
//  Created by 谭真 on 2018/12/20.
//  Copyright © 2018 谭真. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface TZImageRequestOperation : NSOperation

typedef void(^TZImageRequestCompletedBlock)(UIImage *photo, NSDictionary *info, BOOL isDegraded);
typedef void(^TZImageRequestProgressBlock)(double progress, NSError *error, BOOL *stop, NSDictionary *info);

- (instancetype)initWithAsset:(PHAsset *)asset completion:(TZImageRequestCompletedBlock)completionBlock progressHandler:(TZImageRequestProgressBlock)progressHandler;
@end

NS_ASSUME_NONNULL_END
