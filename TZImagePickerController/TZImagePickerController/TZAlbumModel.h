//
//  TZAlbumModel.h
//  TZImagePickerController
//
//  Created by d jiang on 25/02/17.
//  Copyright © 2017 谭真. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TZAssetModelProtocol.h"
@class PHFetchResult;


@interface TZAlbumModel : NSObject

@property (nonatomic, strong) NSString *name;        ///< The album name
@property (nonatomic, assign) NSInteger count;       ///< Count of photos the album contain
@property (nonatomic, strong) id result;             ///< PHFetchResult<PHAsset> or ALAssetsGroup<ALAsset>

@property (nonatomic, strong) NSArray *models;
@property (nonatomic, strong) NSArray *selectedModels;
@property (nonatomic, assign) NSUInteger selectedCount;

@end
