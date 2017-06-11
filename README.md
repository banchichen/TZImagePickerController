# TZImagePickerController
 A clone of UIImagePickerController, support picking multiple photos、original photo、video, also allow preview photo and video, fitting iOS6789 system.   
 一个支持多选、选原图和视频的图片选择器，同时有预览功能，适配了iOS6789系统。
 
 关于升级iOS10和Xcdoe8的提示:
 在Xcode8环境下将项目运行在iOS10的设备/模拟器中，访问相册和相机需要额外配置info.plist文件。分别是Privacy - Photo Library Usage Description和Privacy - Camera Usage Description字段，详见Demo中info.plist中的设置。
 
 1. 当前最新版本1.8.0. 修复了若干bug，优化了一些细节，提升了流畅度。
 2. 如果发现pod search TZImagePickerController 搜索出来的不是最新版本，需要在终端执行cd转换文件路径命令退回到Desktop，然后执行pod setup命令更新本地spec缓存（可能需要几分钟）,然后再搜索就可以了.
 3. 如果发现了bug请提一个issue，请尽可能详细地描述系统版本、手机型号和复现步骤等信息，当然最好能先更新到最新版再测试一下，许多旧版本存在的一些问题在新版本上已经解决了~
 
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
  

2016.5.23更新：
刚刚更新了代码，现在版本更新到了1.4.5，新增了一些新功能，比如：在照片列表页新增了拍照按钮，可以全局记录哪个相册已选中了多少张图片，预览控制器可以在外界打开。同时Demo页面也做了一些优化，可以直接删除选中的照片、可以对照片进行长按排序等。当然期间也修复了许多小bug，表现更加好了。

最值得一提的是，1.4.5版本的性能大幅提升了，在我的iOS9.3.2系统6s设备上（870张照片），平均滑动帧数在58左右，滑动十分流畅，在iOS7.0.4的4s设备上(124张照片)，平均滑动帧数在57左右，也十分流畅。经过对比，和QQ的图片选择器滑动帧数表现基本一致，都十分流畅，同时都强于微信的图片选择器。微信的图片选择器，在快速滑动的时候明显感到有一丝卡顿，通过Core Animation查看发现，微信的图片选择器在我的6s设备下帧数平均约52左右，好几次甚至低于50，在4s设备上则表现更糟一些。下面贴上帧数测试截图，大家也可以测试一下~（测试截图请去博客查看~）

tip: 如果你用的是老版本，建议你更新到新版，特别是需要适配iOS7甚至6的应用，因为旧版本在iOS7和6下性能比较糟糕...

2016.6.22更新:
刚刚更新了代码，现在版本更新到了1.5.0。更新如下：
1.可把拍照按钮放在外面了,可以设置弹出一个sheet提示用户选择相册或相机；
2.新增了sortAscendingByModificationDate属性，默认为YES，设置为NO时，照片会按修改时间降序，拍照按钮会在第一个；
3.优化了Demo页面的UI，新增6个开关控件，可方便地更改各个设置来打开选择器；
4.修复了若干bug；

最近更新:
1.8.0 修复若干bug, 提升流畅度
1.7.7 支持GIF图片的播放和选择
1.7.6 支持对共享相册和同步相册的显示 
1.7.5 允许不进入预览页面直接选择照片 
1.7.4 支持单选模式下裁剪照片，支持任意矩形和圆形裁剪框 
1.7.3 优化iCloud照片的显示与选择 
