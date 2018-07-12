//
//  LZImageBrowser.h
//  CroppingImage
//
//  Created by 刘志雄 on 2017/12/25.
//  Copyright © 2017年 刘志雄. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LZImageBrowser;
@protocol LZImageBrowserDelegate <NSObject>
@optional
-(void)lzImageBrowser:(LZImageBrowser *)imageBrowser didSelectedItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface LZImageBrowser : UIViewController

@property(nonatomic,assign)BOOL isShowPlaceHolder;//是否显示占位图
@property(nonatomic,strong)NSArray<NSString *> *imagesUrlArray;
@property(nonatomic,weak)id<LZImageBrowserDelegate>delegate;

@end
