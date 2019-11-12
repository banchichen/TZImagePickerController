//
//  TZImagePickerController.h
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//  version 3.2.7 - 2019.11.12
//  更多信息，请前往项目的github地址：https://github.com/banchichen/TZImagePickerController

/*
 经过测试，比起xib的方式，把TZAssetCell改用纯代码的方式来写，滑动帧数明显提高了（约提高10帧左右）
 
 最初发现这个问题并修复的是@小鱼周凌宇同学，她的博客地址: http://zhoulingyu.com/
 表示感谢~
 
 原来xib确实会导致性能问题啊...大家也要注意了...
 */

#import <UIKit/UIKit.h>
#import "TZAssetModel.h"
#import "NSBundle+TZImagePicker.h"
#import "TZImageManager.h"
#import "TZVideoPlayerController.h"
#import "TZGifPhotoPreviewController.h"
#import "TZLocationManager.h"
#import "TZPhotoPreviewController.h"
#import "TZPhotoPreviewCell.h"

@class TZAlbumCell, TZAssetCell;
@protocol TZImagePickerControllerDelegate;
@interface TZImagePickerController : UINavigationController

#pragma mark -
/// Use this init method / 用这个初始化方法
- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount delegate:(id<TZImagePickerControllerDelegate>)delegate;
- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount columnNumber:(NSInteger)columnNumber delegate:(id<TZImagePickerControllerDelegate>)delegate;
- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount columnNumber:(NSInteger)columnNumber delegate:(id<TZImagePickerControllerDelegate>)delegate pushPhotoPickerVc:(BOOL)pushPhotoPickerVc;
/// This init method just for previewing photos / 用这个初始化方法以预览图片
- (instancetype)initWithSelectedAssets:(NSMutableArray *)selectedAssets selectedPhotos:(NSMutableArray *)selectedPhotos index:(NSInteger)index;
/// This init method for crop photo / 用这个初始化方法以裁剪图片
- (instancetype)initCropTypeWithAsset:(PHAsset *)asset photo:(UIImage *)photo completion:(void (^)(UIImage *cropImage,PHAsset *asset))completion;

#pragma mark -
/// Default is 9 / 默认最大可选9张图片
@property (nonatomic, assign) NSInteger maxImagesCount;

/// The minimum count photos user must pick, Default is 0
/// 最小照片必选张数,默认是0
@property (nonatomic, assign) NSInteger minImagesCount;

/// Always enale the done button, not require minimum 1 photo be picked
/// 让完成按钮一直可以点击，无须最少选择一张图片
@property (nonatomic, assign) BOOL alwaysEnableDoneBtn;

/// Sort photos ascending by modificationDate，Default is YES
/// 对照片排序，按修改时间升序，默认是YES。如果设置为NO,最新的照片会显示在最前面，内部的拍照按钮会排在第一个
@property (nonatomic, assign) BOOL sortAscendingByModificationDate;

/// The pixel width of output image, Default is 828px，you need to set photoPreviewMaxWidth at the same time
/// 导出图片的宽度，默认828像素宽，你需要同时设置photoPreviewMaxWidth的值
@property (nonatomic, assign) CGFloat photoWidth;

/// Default is 600px / 默认600像素宽
@property (nonatomic, assign) CGFloat photoPreviewMaxWidth;

/// Default is 15, While fetching photo, HUD will dismiss automatic if timeout;
/// 超时时间，默认为15秒，当取图片时间超过15秒还没有取成功时，会自动dismiss HUD；
@property (nonatomic, assign) NSInteger timeout;

/// Default is YES, if set NO, the original photo button will hide. user can't picking original photo.
/// 默认为YES，如果设置为NO,原图按钮将隐藏，用户不能选择发送原图
@property (nonatomic, assign) BOOL allowPickingOriginalPhoto;

/// Default is YES, if set NO, user can't picking video.
/// 默认为YES，如果设置为NO,用户将不能选择视频
@property (nonatomic, assign) BOOL allowPickingVideo;
/// Default is NO / 默认为NO，为YES时可以多选视频/gif/图片，和照片共享最大可选张数maxImagesCount的限制
@property (nonatomic, assign) BOOL allowPickingMultipleVideo;

/// Default is NO, if set YES, user can picking gif image.
/// 默认为NO，如果设置为YES,用户可以选择gif图片
@property (nonatomic, assign) BOOL allowPickingGif;

/// Default is YES, if set NO, user can't picking image.
/// 默认为YES，如果设置为NO,用户将不能选择发送图片
@property (nonatomic, assign) BOOL allowPickingImage;

/// Default is YES, if set NO, user can't take picture.
/// 默认为YES，如果设置为NO, 用户将不能拍摄照片
@property (nonatomic, assign) BOOL allowTakePicture;
@property (nonatomic, assign) BOOL allowCameraLocation;

/// Default is YES, if set NO, user can't take video.
/// 默认为YES，如果设置为NO, 用户将不能拍摄视频
@property(nonatomic, assign) BOOL allowTakeVideo;
/// Default value is 10 minutes / 视频最大拍摄时间，默认是10分钟，单位是秒
@property (assign, nonatomic) NSTimeInterval videoMaximumDuration;
/// Customizing UIImagePickerController's other properties, such as videoQuality / 定制UIImagePickerController的其它属性，比如视频拍摄质量videoQuality
@property (nonatomic, copy) void(^uiImagePickerControllerSettingBlock)(UIImagePickerController *imagePickerController);

/// 首选语言，如果设置了就用该语言，不设则取当前系统语言。
/// 由于目前只支持中文、繁体中文、英文、越南语。故该属性只支持zh-Hans、zh-Hant、en、vi四种值，其余值无效。
@property (copy, nonatomic) NSString *preferredLanguage;

/// 语言bundle，preferredLanguage变化时languageBundle会变化
/// 可通过手动设置bundle，让选择器支持新的的语言（需要在设置preferredLanguage后设置languageBundle）。欢迎提交PR把语言文件提交上来~
@property (strong, nonatomic) NSBundle *languageBundle;

/// Default is YES, if set NO, user can't preview photo.
/// 默认为YES，如果设置为NO,预览按钮将隐藏,用户将不能去预览照片
@property (nonatomic, assign) BOOL allowPreview;

/// Default is YES, if set NO, the picker don't dismiss itself.
/// 默认为YES，如果设置为NO, 选择器将不会自己dismiss
@property(nonatomic, assign) BOOL autoDismiss;

/// Default is NO, if set YES, in the delegate method the photos and infos will be nil, only assets hava value.
/// 默认为NO，如果设置为YES，代理方法里photos和infos会是nil，只返回assets
@property (assign, nonatomic) BOOL onlyReturnAsset;

/// Default is NO, if set YES, will show the image's selected index.
/// 默认为NO，如果设置为YES，会显示照片的选中序号
@property (assign, nonatomic) BOOL showSelectedIndex;

/// Default is NO, if set YES, when selected photos's count up to maxImagesCount, other photo will show float layer what's color is cannotSelectLayerColor.
/// 默认是NO，如果设置为YES，当照片选择张数达到maxImagesCount时，其它照片会显示颜色为cannotSelectLayerColor的浮层
@property (assign, nonatomic) BOOL showPhotoCannotSelectLayer;
/// Default is white color with 0.8 alpha;
@property (strong, nonatomic) UIColor *cannotSelectLayerColor;

/// Default is YES, if set NO, the result photo will be scaled to photoWidth pixel width. The photoWidth default is 828px
/// 默认是YES，如果设置为NO，内部会缩放图片到photoWidth像素宽
@property (assign, nonatomic) BOOL notScaleImage;

/// 默认是NO，如果设置为YES，导出视频时会修正转向（慎重设为YES，可能导致部分安卓下拍的视频导出失败）
@property (assign, nonatomic) BOOL needFixComposition;

/// The photos user have selected
/// 用户选中过的图片数组
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSMutableArray<TZAssetModel *> *selectedModels;
@property (nonatomic, strong) NSMutableArray *selectedAssetIds;
- (void)addSelectedModel:(TZAssetModel *)model;
- (void)removeSelectedModel:(TZAssetModel *)model;

/// Minimum selectable photo width, Default is 0
/// 最小可选中的图片宽度，默认是0，小于这个宽度的图片不可选中
@property (nonatomic, assign) NSInteger minPhotoWidthSelectable;
@property (nonatomic, assign) NSInteger minPhotoHeightSelectable;
/// Hide the photo what can not be selected, Default is NO
/// 隐藏不可以选中的图片，默认是NO，不推荐将其设置为YES
@property (nonatomic, assign) BOOL hideWhenCanNotSelect;
/// Deprecated, Use statusBarStyle (顶部statusBar 是否为系统默认的黑色，默认为NO)
@property (nonatomic, assign) BOOL isStatusBarDefault __attribute__((deprecated("Use -statusBarStyle.")));
/// statusBar的样式，默认为UIStatusBarStyleLightContent
@property (assign, nonatomic) UIStatusBarStyle statusBarStyle;

#pragma mark -
/// Single selection mode, valid when maxImagesCount = 1
/// 单选模式,maxImagesCount为1时才生效
@property (nonatomic, assign) BOOL showSelectBtn;        ///< 在单选模式下，照片列表页中，显示选择按钮,默认为NO
@property (nonatomic, assign) BOOL allowCrop;            ///< 允许裁剪,默认为YES，showSelectBtn为NO才生效
@property (nonatomic, assign) BOOL scaleAspectFillCrop;  ///< 是否图片等比缩放填充cropRect区域
@property (nonatomic, assign) CGRect cropRect;           ///< 裁剪框的尺寸
@property (nonatomic, assign) CGRect cropRectPortrait;   ///< 裁剪框的尺寸(竖屏)
@property (nonatomic, assign) CGRect cropRectLandscape;  ///< 裁剪框的尺寸(横屏)
@property (nonatomic, assign) BOOL needCircleCrop;       ///< 需要圆形裁剪框
@property (nonatomic, assign) NSInteger circleCropRadius;  ///< 圆形裁剪框半径大小
@property (nonatomic, copy) void (^cropViewSettingBlock)(UIView *cropView);     ///< 自定义裁剪框的其他属性
@property (nonatomic, copy) void (^navLeftBarButtonSettingBlock)(UIButton *leftButton);     ///< 自定义返回按钮样式及其属性

/// 【自定义各页面/组件的样式】在界面初始化/组件setModel完成后调用，允许外界修改样式等
@property (nonatomic, copy) void (^photoPickerPageUIConfigBlock)(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine);
@property (nonatomic, copy) void (^photoPreviewPageUIConfigBlock)(UICollectionView *collectionView, UIView *naviBar, UIButton *backButton, UIButton *selectButton, UILabel *indexLabel, UIView *toolBar, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel);
@property (nonatomic, copy) void (^videoPreviewPageUIConfigBlock)(UIButton *playButton, UIView *toolBar, UIButton *doneButton);
@property (nonatomic, copy) void (^gifPreviewPageUIConfigBlock)(UIView *toolBar, UIButton *doneButton);
@property (nonatomic, copy) void (^assetCellDidSetModelBlock)(TZAssetCell *cell, UIImageView *imageView, UIImageView *selectImageView, UILabel *indexLabel, UIView *bottomView, UILabel *timeLength, UIImageView *videoImgView);
@property (nonatomic, copy) void (^albumCellDidSetModelBlock)(TZAlbumCell *cell, UIImageView *posterImageView, UILabel *titleLabel);
/// 【自定义各页面/组件的frame】在界面viewDidLayoutSubviews/组件layoutSubviews后调用，允许外界修改frame等
@property (nonatomic, copy) void (^photoPickerPageDidLayoutSubviewsBlock)(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine);
@property (nonatomic, copy) void (^photoPreviewPageDidLayoutSubviewsBlock)(UICollectionView *collectionView, UIView *naviBar, UIButton *backButton, UIButton *selectButton, UILabel *indexLabel, UIView *toolBar, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel);
@property (nonatomic, copy) void (^videoPreviewPageDidLayoutSubviewsBlock)(UIButton *playButton, UIView *toolBar, UIButton *doneButton);
@property (nonatomic, copy) void (^gifPreviewPageDidLayoutSubviewsBlock)(UIView *toolBar, UIButton *doneButton);
@property (nonatomic, copy) void (^assetCellDidLayoutSubviewsBlock)(TZAssetCell *cell, UIImageView *imageView, UIImageView *selectImageView, UILabel *indexLabel, UIView *bottomView, UILabel *timeLength, UIImageView *videoImgView);
@property (nonatomic, copy) void (^albumCellDidLayoutSubviewsBlock)(TZAlbumCell *cell, UIImageView *posterImageView, UILabel *titleLabel);
/// 自定义各页面/组件的frame】刷新底部状态(refreshNaviBarAndBottomBarState)使用的
@property (nonatomic, copy) void (^photoPickerPageDidRefreshStateBlock)(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine);

@property (nonatomic, copy) void (^photoPreviewPageDidRefreshStateBlock)(UICollectionView *collectionView, UIView *naviBar, UIButton *backButton, UIButton *selectButton, UILabel *indexLabel, UIView *toolBar, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel);

#pragma mark -
- (UIAlertController *)showAlertWithTitle:(NSString *)title;
- (void)hideAlertView:(UIAlertController *)alertView;
- (void)showProgressHUD;
- (void)hideProgressHUD;
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;
@property (assign, nonatomic) BOOL needShowStatusBar;

#pragma mark -
@property (nonatomic, copy) NSString *takePictureImageName __attribute__((deprecated("Use -takePictureImage.")));
@property (nonatomic, copy) NSString *photoSelImageName __attribute__((deprecated("Use -photoSelImage.")));
@property (nonatomic, copy) NSString *photoDefImageName __attribute__((deprecated("Use -photoDefImage.")));
@property (nonatomic, copy) NSString *photoOriginSelImageName __attribute__((deprecated("Use -photoOriginSelImage.")));
@property (nonatomic, copy) NSString *photoOriginDefImageName __attribute__((deprecated("Use -photoOriginDefImage.")));
@property (nonatomic, copy) NSString *photoPreviewOriginDefImageName __attribute__((deprecated("Use -photoPreviewOriginDefImage.")));
@property (nonatomic, copy) NSString *photoNumberIconImageName __attribute__((deprecated("Use -photoNumberIconImage.")));
@property (nonatomic, strong) UIImage *takePictureImage;
@property (nonatomic, strong) UIImage *photoSelImage;
@property (nonatomic, strong) UIImage *photoDefImage;
@property (nonatomic, strong) UIImage *photoOriginSelImage;
@property (nonatomic, strong) UIImage *photoOriginDefImage;
@property (nonatomic, strong) UIImage *photoPreviewOriginDefImage;
@property (nonatomic, strong) UIImage *photoNumberIconImage;

#pragma mark -
/// Appearance / 外观颜色 + 按钮文字
@property (nonatomic, strong) UIColor *oKButtonTitleColorNormal;
@property (nonatomic, strong) UIColor *oKButtonTitleColorDisabled;
@property (nonatomic, strong) UIColor *naviBgColor;
@property (nonatomic, strong) UIColor *naviTitleColor;
@property (nonatomic, strong) UIFont *naviTitleFont;
@property (nonatomic, strong) UIColor *barItemTextColor;
@property (nonatomic, strong) UIFont *barItemTextFont;

@property (nonatomic, copy) NSString *doneBtnTitleStr;
@property (nonatomic, copy) NSString *cancelBtnTitleStr;
@property (nonatomic, copy) NSString *previewBtnTitleStr;
@property (nonatomic, copy) NSString *fullImageBtnTitleStr;
@property (nonatomic, copy) NSString *settingBtnTitleStr;
@property (nonatomic, copy) NSString *processHintStr;

/// Icon theme color, default is green color like wechat, the value is r:31 g:185 b:34. Currently only support image selection icon when showSelectedIndex is YES. If you need it, please set it as soon as possible
/// icon主题色，默认是微信的绿色，值是r:31 g:185 b:34。目前仅支持showSelectedIndex为YES时的图片选中icon。如需要，请尽早设置它。
@property (strong, nonatomic) UIColor *iconThemeColor;

#pragma mark -
- (void)cancelButtonClick;

// For method annotations, see the corresponding method in TZImagePickerControllerDelegate / 方法注释见TZImagePickerControllerDelegate中对应方法
@property (nonatomic, copy) void (^didFinishPickingPhotosHandle)(NSArray<UIImage *> *photos,NSArray *assets,BOOL isSelectOriginalPhoto);
@property (nonatomic, copy) void (^didFinishPickingPhotosWithInfosHandle)(NSArray<UIImage *> *photos,NSArray *assets,BOOL isSelectOriginalPhoto,NSArray<NSDictionary *> *infos);
@property (nonatomic, copy) void (^imagePickerControllerDidCancelHandle)(void);
@property (nonatomic, copy) void (^didFinishPickingVideoHandle)(UIImage *coverImage,PHAsset *asset);
@property (nonatomic, copy) void (^didFinishPickingGifImageHandle)(UIImage *animatedImage,id sourceAssets);

@property (nonatomic, weak) id<TZImagePickerControllerDelegate> pickerDelegate;

@end


@protocol TZImagePickerControllerDelegate <NSObject>
@optional
// The picker should dismiss itself; when it dismissed these callback will be called.
// You can also set autoDismiss to NO, then the picker don't dismiss itself.
// If isOriginalPhoto is YES, user picked the original photo.
// You can get original photo with asset, by the method [[TZImageManager manager] getOriginalPhotoWithAsset:completion:].
// The UIImage Object in photos default width is 828px, you can set it by photoWidth property.
// 这个照片选择器会自己dismiss，当选择器dismiss的时候，会执行下面的代理方法
// 你也可以设置autoDismiss属性为NO，选择器就不会自己dismis了
// 如果isSelectOriginalPhoto为YES，表明用户选择了原图
// 你可以通过一个asset获得原图，通过这个方法：[[TZImageManager manager] getOriginalPhotoWithAsset:completion:]
// photos数组里的UIImage对象，默认是828像素宽，你可以通过设置photoWidth属性的值来改变它
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto;
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos;
- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker;

// If user picking a video and allowPickingMultipleVideo is NO, this callback will be called.
// If allowPickingMultipleVideo is YES, will call imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:
// 如果用户选择了一个视频且allowPickingMultipleVideo是NO，下面的代理方法会被执行
// 如果allowPickingMultipleVideo是YES，将会调用imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(PHAsset *)asset;

// If user picking a gif image and allowPickingMultipleVideo is NO, this callback will be called.
// If allowPickingMultipleVideo is YES, will call imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:
// 如果用户选择了一个gif图片且allowPickingMultipleVideo是NO，下面的代理方法会被执行
// 如果allowPickingMultipleVideo是YES，将会调用imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingGifImage:(UIImage *)animatedImage sourceAssets:(PHAsset *)asset;

// Decide album show or not't
// 决定相册显示与否 albumName:相册名字 result:相册原始数据
- (BOOL)isAlbumCanSelect:(NSString *)albumName result:(PHFetchResult *)result;

// Decide asset show or not't
// 决定照片显示与否
- (BOOL)isAssetCanSelect:(PHAsset *)asset;
@end


@interface TZAlbumPickerController : UIViewController
@property (nonatomic, assign) NSInteger columnNumber;
@property (assign, nonatomic) BOOL isFirstAppear;
- (void)configTableView;
@end


@interface UIImage (MyBundle)
+ (UIImage *)tz_imageNamedFromMyBundle:(NSString *)name;
@end


@interface TZCommonTools : NSObject
+ (BOOL)tz_isIPhoneX;
+ (CGFloat)tz_statusBarHeight;
// 获得Info.plist数据字典
+ (NSDictionary *)tz_getInfoDictionary;
+ (BOOL)tz_isRightToLeftLayout;
+ (void)configBarButtonItem:(UIBarButtonItem *)item tzImagePickerVc:(TZImagePickerController *)tzImagePickerVc;
@end


@interface TZImagePickerConfig : NSObject
+ (instancetype)sharedInstance;
@property (copy, nonatomic) NSString *preferredLanguage;
@property(nonatomic, assign) BOOL allowPickingImage;
@property (nonatomic, assign) BOOL allowPickingVideo;
@property (strong, nonatomic) NSBundle *languageBundle;
@property (assign, nonatomic) BOOL showSelectedIndex;
@property (assign, nonatomic) BOOL showPhotoCannotSelectLayer;
@property (assign, nonatomic) BOOL notScaleImage;
@property (assign, nonatomic) BOOL needFixComposition;

/// 默认是50，如果一个GIF过大，里面图片个数可能超过1000，会导致内存飙升而崩溃
@property (assign, nonatomic) NSInteger gifPreviewMaxImagesCount;
/// 【自定义GIF播放方案】为了避免内存过大，内部默认限制只播放50帧（平均取），可通过gifPreviewMaxImagesCount属性调整，若对GIF预览有更好的效果要求，可实现这个block采用FLAnimatedImage等三方库来播放，但注意FLAnimatedImage有播放速度较慢问题，自行取舍下。
@property (nonatomic, copy) void (^gifImagePlayBlock)(TZPhotoPreviewView *view, UIImageView *imageView, NSData *gifData, NSDictionary *info);
@end
