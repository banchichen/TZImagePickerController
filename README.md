# TZImagePickerController
 A clone of UIImagePickerController, support picking multiple photos、original photo、video, also allow preview photo and video, fitting iOS6789 system.   
 一个支持多选、选原图和视频的图片选择器，同时有预览功能，适配了iOS6789系统。
 
 ![image](https://github.com/banchichen/TZImagePickerController/blob/master/TZImagePickerController/ScreenShots/photoPickerVc.PNG) 
 ![image](https://github.com/banchichen/TZImagePickerController/blob/master/TZImagePickerController/ScreenShots/photoPreviewVc.PNG) 
 ![image](https://github.com/banchichen/TZImagePickerController/blob/master/TZImagePickerController/ScreenShots/videoPlayerVc.PNG) 

## 一. Installation 安装

  * CocoaPods：pod 'TZImagePickerController'
  * 手动导入：将TZImagePickerController文件夹拽入项目中，导入头文件：#import "TZImagePickerController.h"

## 二. Example 例子

    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    
    // You can get the photos by block, the same as by delegate.
    // 你可以通过block或者代理，来得到用户选择的照片.
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets) {
    
    }];
    [self presentViewController:imagePickerVc animated:YES completion:nil];
  
## 三. Requirements 要求
   iOS 6 or later. Requires ARC  
   iOS6及以上系统可使用. ARC环境.
   
   When system version is iOS6 or iOS7,  Using AssetsLibrary.  
   When system version is iOS 8 or later, Using PhotoKit.  
   如果运行在iOS6或7系统上，用的是AssetsLibrary库获取照片资源。  
   如果运行在iOS8及以上系统上，用的是PhotoKit库获取照片资源。
   
## 四. More 更多 

  If you find a bug, please create a issue.  
  Welcome to pull requests.  
  More infomation please view code.  
  如果你发现了bug，请提一个issue。  
  欢迎给我提pull requests。  
  更多信息详见代码，也可查看我的博客: [我的博客](http://www.cnblogs.com/tanzhenblog/ "半尺尘 - 博客园")
  
