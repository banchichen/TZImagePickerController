# TZImagePickerController
[![CocoaPods](https://img.shields.io/cocoapods/v/TZImagePickerController.svg?style=flat)](https://github.com/banchichen/TZImagePickerController)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)


 A clone of UIImagePickerController, support picking multiple photos、original photo、video, also allow preview photo and video, support iOS6+.   
 一个支持多选、选原图和视频的图片选择器，同时有预览功能，支持iOS6+。
 
 ## 重要提示1：提issue前，请先对照Demo、常见问题自查！Demo正常说明你可以升级下新版试试。          
   
 ## 重要提示2：1.9.0版本后移除了"prefs:root="的调用，这个API已经被列为私有API，请大家尽快升级。
 
 ## 重要提示3：3.0.7版本适配了iPhoneXR、XS、XS Max，建议大家尽快更新            
 
     关于升级iOS10和Xcdoe8的提示:    
 在Xcode8环境下将项目运行在iOS10的设备/模拟器中，访问相册和相机需要额外配置info.plist文件。分别是Privacy - Photo Library Usage Description和Privacy - Camera Usage Description字段，详见Demo中info.plist中的设置。
    
     项目截图 1.Demo首页 2.照片列表页 3.照片预览页 4.视频预览页
<img src="https://github.com/banchichen/TZImagePickerController/blob/master/TZImagePickerController/ScreenShots/DemoPage.png" width="40%" height="40%"><img src="https://github.com/banchichen/TZImagePickerController/blob/master/TZImagePickerController/ScreenShots/photoPickerVc.PNG" width="40%" height="40%">
<img src="https://github.com/banchichen/TZImagePickerController/blob/master/TZImagePickerController/ScreenShots/photoPreviewVc.PNG" width="40%" height="40%"><img src="https://github.com/banchichen/TZImagePickerController/blob/master/TZImagePickerController/ScreenShots/videoPlayerVc.PNG" width="40%" height="40%">

## 一. Installation 安装

#### CocoaPods
> pod 'TZImagePickerController'   #iOS8 and later        
> pod 'TZImagePickerController', '2.2.6'   #iOS6、iOS7        

#### Carthage
> github "banchichen/TZImagePickerController"

#### 手动安装
> 将TZImagePickerController文件夹拽入项目中，导入头文件：#import "TZImagePickerController.h"

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
   When system version is iOS8 or later, Using PhotoKit.  
   如果运行在iOS6或7系统上，用的是AssetsLibrary库获取照片资源。  
   如果运行在iOS8及以上系统上，用的是PhotoKit库获取照片资源。
   
   TZImagePickerController uses Camera、Location、Microphone、Photo Library，you need add these properties to info.plist like Demo：       
   TZImagePickerController使用了相机、定位、麦克风、相册，请参考Demo添加下列属性到info.plist文件：        
   	`Privacy - Camera Usage Description`     
	`Privacy - Location When In Use Usage Description`    
 	`Privacy - Microphone Usage Description`   
 	`Privacy - Photo Library Usage Description`   
   
## 四. More 更多 

  If you find a bug, please create a issue.  
  Welcome to pull requests.  
  More infomation please view code.  
  如果你发现了bug，请提一个issue。 
  欢迎给我提pull requests。  
  更多信息详见代码，也可查看我的博客: [我的博客](http://www.jianshu.com/p/1975411a31bb "半尺尘 - 简书")
  
      关于issue: 
  请尽可能详细地描述**系统版本**、**手机型号**、**库的版本**、**崩溃日志**和**复现步骤**，**请先更新到最新版再测试一下**，如果新版还存在再提~如果已有开启的类似issue，请直接在该issue下评论说出你的问题
  
## 五. FAQ 常见问题    

**Q：pod search TZImagePickerController 搜索出来的不是最新版本**       
A：需要在终端执行cd转换文件路径命令退回到Desktop，然后执行pod setup命令更新本地spec缓存（可能需要几分钟）,然后再搜索就可以了       
     
**Q：拍照后照片保存失败**         
A：请参考issue481：https://github.com/banchichen/TZImagePickerController/issues/481 的信息排查，若还有问题请直接在issue内评论   
 
**Q：photos数组图片不是原图，如何获取原图？**        
A：请参考issue457的解释：https://github.com/banchichen/TZImagePickerController/issues/457    

**Q：系统语言是中文/英文，界面上却有部分相册名字、返回按钮显示成了英文/中文？**        
A：请参考 https://github.com/banchichen/TZImagePickerController/issues/443 和 https://github.com/banchichen/TZImagePickerController/issues/929          
 
**Q：预览界面能否支持传入NSURL、UIImage对象？**        
A：3.0.1版本已支持，需新接一个库：[TZImagePreviewController](https://github.com/banchichen/TZImagePreviewController)，请参考里面的Demo使用。       

**Q：设置可选视频的最大/最小时长？照片的最小/最大尺寸？不符合要求的不显示**       
A：可以的，参照Demo的isAssetCanSelect方法实现。我会返回asset出来，显示与否你来决定，注意这个是一个同步方法，对于需要根据asset去异步获取的信息如视频的大小、视频是否存在iCloud里来过滤的，无法做到。如果真要这样做，相册打开速度会变慢，你需要改我源码。

**Q：预览页面出现了导航栏？**        
A：https://github.com/banchichen/TZImagePickerController/issues/652         
   
**Q：可否增加微信编辑图片的功能？**           
A：考虑下，优先级低  

**Q：是否有QQ/微信群？**            
A：有QQ群：778723997        

**Q：想提交一个PR？**           
A：请先加QQ群和我确认下，避免同时改动同一处内容。**一个PR请只修复1个问题，变动内容越少越好**。                 

**Q：demo在真机上跑不起来？**             
A：1、team选你自己的；2、bundleId也改成你自己的或改成一个不会和别人重复的。可参考[简书的这篇博客](https://www.jianshu.com/p/cbe59138fca6)             

**Q：设置导航栏颜色无效？导航栏颜色总是白色？**            
A：是否有集成WRNavigationBar？如有，参考其readme调一下它的wr_setBlackList，把TZImagePickerController相关的控制器放到黑名单里，使得不受WRNavigationBar的影响。如果没有集成，可在issues列表里搜一下看看类似的issue参考下，如实在没头绪，可加群提供个能复现该问题的demo，0~2天给你解决。最近发现WRNavigationBar的黑名单会有不生效的情况，临时解决方案大家可参考：[https://github.com/wangrui460/WRNavigationBar/issues/145](https://github.com/wangrui460/WRNavigationBar/issues/145)                          

**Q：导航栏没了？**            
A：是否有集成GKNavigationBarViewController？需要升级到2.0.4及以上版本，详见issue：[https://github.com/QuintGao/GKNavigationBarViewController/issues/7](https://github.com/QuintGao/GKNavigationBarViewController/issues/7)。       

**Q：有的视频导出失败？**            
A：升级到2.2.6及以上版本试试，发现是修正视频转向导致的，2.2.6开始默认不再主动修正。如需打开，可设置needFixComposition为YES，但有几率导致安卓拍的视频导出失败。       

**Q：视频导出慢？**            
A：视频导出分两步，第一步是通过PHAsset获取AVURLAsset，如是iCloud视频则涉及到网络请求，耗时容易不可控，第二步是通过AVURLAsset把视频保存到沙盒，耗时不算多。但第一步耗时不可控，你可以拷贝我源码出来拿到第一步的进度给用户一个进度提示...     

**Q：有的图片info里没有PHImageFileURLKey？**            
A：不要去拿PHImageFileURLKey，没用的，只有通过Photos框架才能访问相册照片，光拿一个路径没用。        
如果需要通过路径上传照片，请先把UIImage保存到沙盒，**用沙盒路径**。           
如果你上传照片需要一个名字参数，请参考Demo**直接用照片名字**。          

## 六. Release Notes 最近更新     

3.1.5 相册内无照片时给出提示，修复快速滑动时内存一直增加的问题        
3.1.3 适配阿拉伯等语言下从右往左布局的特性         
3.0.8 新增gifImagePlayBlock允许使用FLAnimatedImage等替换内部的GIF播放方案         
**3.0.7 适配iPhoneXR、XS、XS Max，建议大家尽快更新**           
3.0.6 优化保存照片、视频的方法        
3.0.1 新增对[TZImagePreviewController](https://github.com/banchichen/TZImagePreviewController)库的支持，允许预览UIImage、NSURL、PHAsset对象       
**3.0.0 去除iOS6和7的适配代码，更轻量，最低支持iOS8**      
2.2.6 新增needFixComposition属性，默认为NO，不再主动修正视频转向，防止部分安卓拍的视频导出失败（**最后一个支持iOS6和7的版本**）          
2.1.5 修复开启showSelectedIndex后照片列表页iCloud图片进度条紊乱的bug              
2.1.4 新增多个页面和组件的样式自定义block，允许自定义绝大多数UI样式              
2.1.2 新增showPhotoCannotSelectLayer属性，当已选照片张数达到最大可选张数时，可像微信一样让其它照片显示一个提示不可选的浮层            
2.1.1 新增是否显示图片选中序号的属性，优化一些细节                 
2.1.0.3 新增拍摄视频功能，优化一些细节           
2.0.0.6 优化自定义languageBundle的支持，加入使用示例       
2.0.0.5 优化性能，提高选择器打开速度，新增越南语支持    
2.0.0.2 新增繁体语言，可设置首选语言，国际化支持更强大；优化一些细节     
1.9.8  支持Carthage，优化一些细节    
1.9.6  优化视频预览和gif预览页toolbar在iPhoneX上的样式      
1.9.0  移除"prefs:root="的调用，这个API已经被列为私有API，请大家尽快升级     
...   
1.8.4  加入横竖屏适配；支持视频/gif多选；支持视频和照片一起选    
1.8.1  新增2个代理方法，支持由上层来决定相册/照片的显示与否     
...   
1.7.7  支持GIF图片的播放和选择    
1.7.6  支持对共享相册和同步相册的显示     
1.7.5  允许不进入预览页面直接选择照片     
1.7.4  支持单选模式下裁剪照片，支持任意矩形和圆形裁剪框    
1.7.3  优化iCloud照片的显示与选择    
...   
1.5.0  可把拍照按钮放在外面；可自定义照片排序方式；Demo页的UI大改版，新增若干开关；   
...      
1.4.5  性能大幅提升（性能测试截图请去博客查看）；可在照片列表页拍照；Demo大幅优化；   
...        
