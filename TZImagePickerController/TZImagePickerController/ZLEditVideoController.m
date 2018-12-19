//
//  ZLEditVideoController.m
//  ZLPhotoBrowser
//
//  Created by long on 2017/9/15.
//  Copyright © 2017年 long. All rights reserved.
//

#import "ZLEditVideoController.h"
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <sys/utsname.h>
#import "TZImagePickerController.h"
#import "TSLocalVideoCoverSelectedVC.h"

@interface ZLEditVideoUX : NSObject

@property (nonatomic, assign) CGRect validRect;

@property (nonatomic, assign, readonly) CGFloat collectionItemHeight;
@property (nonatomic, assign) CGFloat collectionItemWidth;
// 裁剪左右指示器的宽度，高度默认和整个选择器等高
@property (nonatomic, assign, readonly) CGFloat editIndicatorViewWidth;

+ (ZLEditVideoUX*)share;

@end

@implementation ZLEditVideoUX
+ (ZLEditVideoUX*)share {
    static ZLEditVideoUX *_share;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _share = [[ZLEditVideoUX alloc]init];
        _share.collectionItemWidth = 50 * 2 / 3.0;
    });
    return _share;
}
// 默认设置高度
- (CGFloat)collectionItemHeight {
    return 50;
}
// 左右选择指示器的宽度
- (CGFloat)editIndicatorViewWidth {
    return 10;
}
@end

///////-----cell
@interface ZLEditVideoCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ZLEditVideoCell

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.frame = self.bounds;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

@end

@protocol ZLEditFrameViewDelegate <NSObject>

- (void)editViewValidRectChanged;

- (void)editViewValidRectEndChanged;

@end

///////-----编辑框
@interface ZLEditFrameView : UIView
{
}

@property (nonatomic, assign) CGRect validRect;
@property (nonatomic, assign) CGFloat minValidRectWidth;
@property (nonatomic, weak) id<ZLEditFrameViewDelegate> delegate;
@property (nonatomic, strong) UIImageView *leftView;
@property (nonatomic, strong) UIImageView *rightView;

@end

@implementation ZLEditFrameView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    //扩大下有效范围
    CGRect left = _leftView.frame;
    left.origin.x -= [ZLEditVideoUX share].collectionItemWidth/2;
    left.size.width += [ZLEditVideoUX share].collectionItemWidth/2;
    CGRect right = _rightView.frame;
    right.size.width += [ZLEditVideoUX share].collectionItemWidth/2;
    
    if (CGRectContainsPoint(left, point)) {
        return _leftView;
    }
    if (CGRectContainsPoint(right, point)) {
        return _rightView;
    }
    return nil;
}

- (void)setupUI
{
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    _leftView = [[UIImageView alloc] initWithImage: [UIImage imageNamedFromMyBundle: @"pic_left"]];
    _leftView.userInteractionEnabled = YES;
    _leftView.tag = 0;
    UIPanGestureRecognizer *lg = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [_leftView addGestureRecognizer:lg];
    [self addSubview:_leftView];
    
    _rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamedFromMyBundle: @"pic_right"]];
    _rightView.userInteractionEnabled = YES;
    _rightView.backgroundColor = [UIColor redColor];
    _rightView.tag = 1;
    UIPanGestureRecognizer *rg = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [_rightView addGestureRecognizer:rg];
    [self addSubview:_rightView];
}

- (void)panAction:(UIGestureRecognizer *)pan
{
    self.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:.4].CGColor;
    CGPoint point = [pan locationInView:self];
    CGRect rct = self.validRect;
    const CGFloat W = self.frame.size.width;
    CGFloat minX = 0;
    CGFloat maxX = W;
    
    switch (pan.view.tag) {
        case 0: {
            //left
            maxX = rct.origin.x + rct.size.width - [ZLEditVideoUX share].collectionItemWidth;
            
            point.x = MAX(minX, MIN(point.x, maxX));
            point.y = 0;
            
            rct.size.width -= (point.x - rct.origin.x);
            rct.origin.x = point.x;
        }
            break;
            
        case 1:
        {
            //right
            minX = rct.origin.x + 10;
            maxX = W;
            
            point.x = MAX(minX, MIN(point.x, maxX));
            point.y = 0;
            
            rct.size.width = (point.x - rct.origin.x);
        }
            break;
    }
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            if (self.delegate && [self.delegate respondsToSelector:@selector(editViewValidRectChanged)]) {
                [self.delegate editViewValidRectChanged];
            }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            self.layer.borderColor = [UIColor clearColor].CGColor;
            if (self.delegate && [self.delegate respondsToSelector:@selector(editViewValidRectEndChanged)]) {
                [self.delegate editViewValidRectEndChanged];
            }
            break;
            
        default:
            break;
    }
    
    
    self.validRect = rct;
}

- (void)setValidRect:(CGRect)validRect
{
    if (validRect.size.width < self.minValidRectWidth) {
        validRect = CGRectMake(validRect.origin.x, validRect.origin.y, self.minValidRectWidth, validRect.size.height);
    }
    if (validRect.origin.x + validRect.size.width > self.frame.size.width) {
        validRect = CGRectMake(self.frame.size.width - validRect.size.width, validRect.origin.y, self.minValidRectWidth, validRect.size.height);
    }
    _validRect = validRect;
    _leftView.frame = CGRectMake(validRect.origin.x > 10 / 2.0 ?  (validRect.origin.x - 10 / 2.0) : validRect.origin.x, 0, 10, [ZLEditVideoUX share].collectionItemHeight);
    _rightView.frame = CGRectMake(validRect.origin.x + validRect.size.width - 10.0, 0, 10, [ZLEditVideoUX share].collectionItemHeight);
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.validRect);
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetLineWidth(context, 4.0);
    CGPoint topPoints[2];
    topPoints[0] = CGPointMake(self.validRect.origin.x, 0);
    topPoints[1] = CGPointMake(self.validRect.origin.x+self.validRect.size.width, 0);
    CGPoint bottomPoints[2];
    bottomPoints[0] = CGPointMake(self.validRect.origin.x, [ZLEditVideoUX share].collectionItemHeight);
    bottomPoints[1] = CGPointMake(self.validRect.origin.x+self.validRect.size.width, [ZLEditVideoUX share].collectionItemHeight);
    CGContextAddLines(context, topPoints, 2);
    CGContextAddLines(context, bottomPoints, 2);
    CGContextDrawPath(context, kCGPathStroke);
}

@end


///////-----editvc
@interface ZLEditVideoController () <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, ZLEditFrameViewDelegate>
{
    //下方collectionview偏移量
    CGFloat _offsetX;
    BOOL _orientationChanged;
}
// Jar
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIImage *> *imageCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSBlockOperation *> *operationCache;
// UI
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ZLEditFrameView *editView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *indicatorLine;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIView *customNav;
/// 底部提示语
@property (nonatomic, strong) UILabel *noticeLabel;

// Other
@property (nonatomic, strong) AVAssetImageGenerator *generator;
@property (nonatomic, assign) BOOL collectionViewCouldScroll;
@property (nonatomic, strong) AVAsset *avAsset;
@property (nonatomic, assign) NSTimeInterval perItemSeconds;
@property (nonatomic, assign) NSInteger itemCount;
@property (nonatomic, strong) NSOperationQueue *getImageCacheQueue;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL appStatusBarHidden;
/// 编辑区域底部左右侧空间
@property (nonatomic) CGFloat editViewLeftRightSpace;

@end

@implementation ZLEditVideoController

- (void)dealloc
{
    [self.getImageCacheQueue cancelAllOperations];
    [self stopTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"---- %s", __FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    /// 判断最大、最小视频裁剪时长合法性
    if (self.minEditVideoTime == 0) {
        self.minEditVideoTime = 3;
    }
    if (self.maxEditVideoTime == 0) {
        self.maxEditVideoTime = 10;
    }
    if (self.minEditVideoTime > self.maxEditVideoTime) {
        self.maxEditVideoTime = self.minEditVideoTime;
    }
    self.editViewLeftRightSpace = 15;
    self.bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:self.bgView];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.appStatusBarHidden = [UIApplication sharedApplication].isStatusBarHidden;

    [self analysisAssetImages:^{
        [self setupUI];
        [self creatCostomUI];
    }];

    self.getImageCacheQueue = [[NSOperationQueue alloc] init];
    self.getImageCacheQueue.maxConcurrentOperationCount = 3;
    
    self.imageCache = [NSMutableDictionary dictionary];
    self.operationCache = [NSMutableDictionary dictionary];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}
/// 自定义导航
- (void)creatCostomUI {
    self.customNav = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 64)];
    if ([self zl_isIPhoneX]) {
        self.customNav.frame = CGRectMake(0, 30, [UIScreen mainScreen].bounds.size.width, 64);
    }
    UIButton *backBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 20, 30, 22)];
    [backBtn addTarget:self action:@selector(navLeftBarButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.customNav addSubview:backBtn];
    if (_backImage) {
        [backBtn setImage:_backImage forState:UIControlStateNormal];
    } else {
        [backBtn setImage:[UIImage imageNamedFromMyBundle:@"topbar_back"] forState:UIControlStateNormal];
    }
    UILabel *titleLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 40)];
    titleLab.textAlignment = NSTextAlignmentCenter;
    titleLab.text = @"编辑视频";
    titleLab.font = [UIFont fontWithName:@"PingFangSC-Medium" size:18];
    titleLab.textColor = [UIColor whiteColor];
    [self.customNav addSubview:titleLab];
    titleLab.center = CGPointMake(self.customNav.frame.size.width / 2.0, backBtn.center.y);
    /// 确定按钮
    UIButton *sureBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.customNav.frame.size.width - 50, 20, 50, 22)];
    [sureBtn setTitle:@"完成" forState:UIControlStateNormal];
    sureBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
    [sureBtn addTarget:self action:@selector(rightButtonClick:) forControlEvents:UIControlEventTouchUpInside];

    [self.customNav addSubview:sureBtn];

    [self.view addSubview:self.customNav];
}

- (void)navLeftBarButtonClick{
    [self.playerLayer.player pause];
    self.playerLayer.player = nil;
    [self.playerLayer removeFromSuperlayer];
    [self.getImageCacheQueue cancelAllOperations];
    self.playerLayer.delegate = nil;
    self.playerLayer = nil;
    [self stopTimer];
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)rightButtonClick:(UIButton *)btn {
    btn.userInteractionEnabled = NO;
    [self stopTimer];
    __weak typeof(self) weakSelf = self;
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    [imagePickerVc showProgressHUD];
    [self exportPHAsset:self.asset range:[self getTimeRange] complete:^(NSString *exportFilePath, NSError *error) {
        NSLog(@"error -%@",error);
        btn.userInteractionEnabled = YES;
        [imagePickerVc hideProgressHUD];
        if (error == nil) {
            /// 需要选择封面
            if (imagePickerVc.shouldSetCoverImage) {
                TSLocalVideoCoverSelectedVC *vc = [[TSLocalVideoCoverSelectedVC alloc]init];
                if (imagePickerVc.backImage) {
                    vc.backImage = imagePickerVc.backImage;
                }
                if (imagePickerVc.picCoverImage) {
                    vc.picCoverImage = imagePickerVc.picCoverImage;
                }
                if (imagePickerVc.mainColor) {
                    vc.mainColor = imagePickerVc.mainColor;
                }
                vc.videoPath = [NSURL fileURLWithPath:exportFilePath];
                vc.coverImageBlock = ^(UIImage *coverImage, NSURL *videoPath) {
                    [weakSelf stopTimer];
                    [weakSelf.getImageCacheQueue cancelAllOperations];
                    [weakSelf.playerLayer.player pause];
                    weakSelf.playerLayer.delegate = nil;
                    weakSelf.playerLayer.player = nil;
                    [weakSelf.playerLayer removeFromSuperlayer];
                    weakSelf.playerLayer = nil;
                    if (weakSelf.coverImageBlock) {
                        weakSelf.coverImageBlock(coverImage, videoPath);
                    }
                };
                [weakSelf.navigationController pushViewController:vc animated:YES];
            } else {
                /// 不需要选择封面
                if (weakSelf.coverImageBlock) {
                    CGFloat second = 0;
                    UIImage *coverImage;
                    AVURLAsset *asset = [AVURLAsset assetWithURL: [NSURL fileURLWithPath:exportFilePath]];
                    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset: asset];
                    generator.appliesPreferredTrackTransform = YES;
                    generator.requestedTimeToleranceBefore = kCMTimeZero;
                    generator.requestedTimeToleranceAfter = kCMTimeZero;
                    generator.apertureMode = AVAssetImageGeneratorApertureModeProductionAperture;
                    for (int i = 0; i < 5; i ++) {
                        CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(second * asset.duration.timescale, asset.duration.timescale) actualTime:NULL error:&error];
                        second = second + 0.1;
                        if (img != nil) {
                            coverImage = [UIImage imageWithCGImage:img];
                            break;
                        }
                        NSLog(@"error\n\n -%@", error);
                    }
                    [weakSelf stopTimer];
                    [weakSelf.getImageCacheQueue cancelAllOperations];
                    [weakSelf.playerLayer.player pause];
                    weakSelf.playerLayer.delegate = nil;
                    weakSelf.playerLayer.player = nil;
                    [weakSelf.playerLayer removeFromSuperlayer];
                    weakSelf.playerLayer = nil;
                    weakSelf.coverImageBlock(coverImage, [NSURL fileURLWithPath:exportFilePath]);
                }
            }
        } else {
            
        }
    }];
}

- (BOOL)zl_isIPhoneX {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if ([platform isEqualToString:@"i386"] || [platform isEqualToString:@"x86_64"]) {
        // 模拟器下采用屏幕的高度来判断
        return (CGSizeEqualToSize([UIScreen mainScreen].bounds.size, CGSizeMake(375, 812)) ||
                CGSizeEqualToSize([UIScreen mainScreen].bounds.size, CGSizeMake(812, 375)));
    }
    BOOL isIPhoneX = [platform isEqualToString:@"iPhone10,3"] || [platform isEqualToString:@"iPhone10,6"];
    return isIPhoneX;
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.editView.validRect.size.width > 0) {
        [self startTimer];
    }
    self.navigationController.navigationBarHidden = YES;
    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopTimer];
    self.navigationController.navigationBarHidden = NO;
    [UIApplication sharedApplication].statusBarHidden = self.appStatusBarHidden;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat bottomViewHeight = [ZLEditVideoUX share].collectionItemHeight + 18 + 13;
    CGFloat bottomViewBottom = 16;
    self.bottomView.frame = CGRectMake(self.editViewLeftRightSpace, [[UIScreen mainScreen] bounds].size.height - bottomViewHeight - bottomViewBottom, [[UIScreen mainScreen] bounds].size.width - self.editViewLeftRightSpace * 2, bottomViewHeight);
    ///iphoneX 底部预留安全区域34pt
    if ([self zl_isIPhoneX]) {
        self.bottomView.frame = CGRectMake(self.editViewLeftRightSpace, [[UIScreen mainScreen] bounds].size.height - bottomViewHeight - 34, [[UIScreen mainScreen] bounds].size.width - self.editViewLeftRightSpace * 2, bottomViewHeight);
    }
    self.collectionView.frame = CGRectMake(0, 0, self.bottomView.frame.size.width, [ZLEditVideoUX share].collectionItemHeight);
    self.noticeLabel.frame = CGRectMake(0, self.collectionView.frame.origin.y + self.collectionView.frame.size.height + 18, 200, 13);
    self.noticeLabel.center = CGPointMake(self.bottomView.frame.size.width / 2.0, self.noticeLabel.center.y);
    self.editView.frame = self.collectionView.bounds;
    self.editView.validRect = self.editView.bounds;
    /// 全屏显示播放内容
    self.playerLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [self startTimer];
}

#pragma mark - notifies
//设备旋转
- (void)deviceOrientationChanged:(NSNotification *)notify
{
    _offsetX = self.collectionView.contentOffset.x + self.collectionView.contentInset.left;
    _orientationChanged = YES;
}

- (void)appResignActive
{
    [self stopTimer];
}

- (void)appBecomeActive
{
    [self startTimer];
}

- (void)setupUI
{
    //禁用返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.playerLayer = [[AVPlayerLayer alloc] init];
    [self.view.layer addSublayer:self.playerLayer];
    self.playerLayer.backgroundColor = [UIColor clearColor].CGColor;
    /// 顶部和底部设置蒙层
    UIImageView *topMarkImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 188)];
    topMarkImageView.image = [UIImage imageNamedFromMyBundle: @"pic_mask_top"];
    [self.view addSubview:topMarkImageView];
    UIImageView *bottomMarkImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 188, [UIScreen mainScreen].bounds.size.width, 188)];
    bottomMarkImageView.image = [UIImage imageNamedFromMyBundle: @"pic_mask_bottom"];
    [self.view addSubview:bottomMarkImageView];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake([ZLEditVideoUX share].collectionItemWidth, [ZLEditVideoUX share].collectionItemHeight);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self.collectionView registerClass:ZLEditVideoCell.class forCellWithReuseIdentifier:@"ZLEditVideoCell"];
    self.collectionView.scrollEnabled = self.collectionViewCouldScroll;
    [self creatBottomView];
    [self.bottomView addSubview:self.collectionView];
    /// 总时间提示
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectZero];
    self.noticeLabel.textColor = [UIColor whiteColor];
    self.noticeLabel.text = [NSString stringWithFormat:@"最长支持%luS视频裁剪", self.maxEditVideoTime];
    self.noticeLabel.font = [UIFont systemFontOfSize:13];
    self.noticeLabel.textAlignment = NSTextAlignmentCenter;
    [self.bottomView addSubview: self.noticeLabel];

    self.editView = [[ZLEditFrameView alloc] init];
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    if (imagePickerVc.editFaceLeft) {
        self.editView.leftView.image = imagePickerVc.editFaceLeft;
    }
    if (imagePickerVc.editFaceRight) {
        self.editView.rightView.image = imagePickerVc.editFaceRight;
    }
    self.editView.delegate = self;
    [self.bottomView addSubview:self.editView];
    // 更新最小可编辑区域
    self.editView.minValidRectWidth = self.minEditVideoTime / self.perItemSeconds * [ZLEditVideoUX share].collectionItemWidth;
    NSLog(@"minValidRectWidth -%f", self.editView.minValidRectWidth);
    self.indicatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, [ZLEditVideoUX share].collectionItemHeight)];
    self.indicatorLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:.7];
}

- (void)creatBottomView
{
    //下方视图
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.bottomView];
}

#pragma mark - 解析视频每一帧图片
- (void)analysisAssetImages:(void (^)(void))completion {
    float duration = roundf(self.asset.duration);
    // 最大裁剪时长是否大于10秒
    if (self.maxEditVideoTime >= 10) {
        // 满足1秒一个item的最低要求
        if (duration <= self.maxEditVideoTime) {
            self.itemCount = 10;
            self.perItemSeconds = duration / self.itemCount;
            self.collectionViewCouldScroll = NO;
        } else {
            // 整个裁剪栏整个宽度（默认显示10个item）为允许的最大裁剪时长
            self.perItemSeconds = (self.maxEditVideoTime * 1.0) / 10;
            self.itemCount = duration / self.perItemSeconds;
            self.collectionViewCouldScroll = YES;
        }
    } else {
        // 拆解1秒
        self.itemCount = 10;
        self.perItemSeconds = duration / self.itemCount;
        self.collectionViewCouldScroll = NO;
    }
    [ZLEditVideoUX share].collectionItemWidth = ([UIScreen mainScreen].bounds.size.width - self.editViewLeftRightSpace * 2) / 10.0;

    PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        NSLog(@"requestAVAssetForVideo asset-%@ -%@", asset, info);
        __weak typeof(self) weakSelf = self;
        self.avAsset = asset;
        self.generator = [[AVAssetImageGenerator alloc] initWithAsset:self.avAsset];
        self.generator.appliesPreferredTrackTransform = YES;
        self.generator.requestedTimeToleranceBefore = kCMTimeZero;
        self.generator.requestedTimeToleranceAfter = kCMTimeZero;
        self.generator.apertureMode = AVAssetImageGeneratorApertureModeProductionAperture;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
        [[PHCachingImageManager defaultManager] requestPlayerItemForVideo:self.asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!playerItem) return;
                AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
                self.playerLayer.player = player;
                [self startTimer];
                [weakSelf.collectionView reloadData];
            });
        }];
    }];
}

#pragma mark - action
- (void)cancelBtn_click
{
    [self stopTimer];
    UIViewController *vc = [self.navigationController popViewControllerAnimated:NO];
    if (!vc) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)exportPHAsset:(PHAsset *)PHasset range:(CMTimeRange)range complete:(void (^)(NSString *exportFilePath, NSError *error))complete {
    if (PHasset.mediaType != PHAssetMediaTypeVideo) {
        if (complete) complete(nil, [NSError errorWithDomain:@"导出失败" code:-1 userInfo:@{@"message": @"导出对象不是视频对象"}]);
        return;
    }
    
    PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestAVAssetForVideo:PHasset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        NSLog(@"info -%@",info);
        [self export:asset range:range complete:^(NSString *exportFilePath, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete(exportFilePath, error);
            }) ;
        }];
    }];
}
- (void)export:(AVAsset *)asset range:(CMTimeRange)range complete:(void (^)(NSString *exportFilePath, NSError *error))complete
{
    NSString *exportFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",@"exportVideo",@"mp4"]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportFilePath]) {
        // 移除上一个
        NSError *removeErr;
        [[NSFileManager defaultManager] removeItemAtPath:exportFilePath error: &removeErr];
    }
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset1280x720];
    
    NSURL *exportFileUrl = [NSURL fileURLWithPath:exportFilePath];
    NSLog(@"exportFileUrl -%@", exportFileUrl.absoluteString);
    exportSession.outputURL = exportFileUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.timeRange = range;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        BOOL suc = NO;
        switch ([exportSession status]) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export canceled");
                break;
                
            case AVAssetExportSessionStatusCompleted:{
                NSLog(@"Export completed");
                suc = YES;
            }
                break;
                
            default:
                NSLog(@"Export other");
                break;
        }
        
        if (complete) {
            complete(suc?exportFilePath:nil, suc?nil:exportSession.error);
            if (!suc) {
                [exportSession cancelExport];
            }
        }
    }];
}

- (NSString *)getUniqueStrByUUID
{
    
    CFUUIDRef uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    CFStringRef uuidString = CFUUIDCreateString(nil, uuidObj);
    NSString *str = [NSString stringWithString:(__bridge NSString *)uuidString];
    CFRelease(uuidObj);
    CFRelease(uuidString);
    return [str lowercaseString];
}

#pragma mark - timer
- (void)startTimer
{
    [self stopTimer];
    if (self.editView.frame.size.width == 0) {
        return;
    }
    
    CGFloat duration = self.perItemSeconds * self.editView.validRect.size.width / ([ZLEditVideoUX share].collectionItemWidth);
    _timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(playPartVideo:) userInfo:nil repeats:YES];
    [_timer fire];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
    self.indicatorLine.frame = CGRectMake(self.editView.validRect.origin.x, 0, 2, [ZLEditVideoUX share].collectionItemHeight);
    [self.editView addSubview:self.indicatorLine];
    [UIView animateWithDuration:duration delay:.0 options:UIViewAnimationOptionRepeat|UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear animations:^{
        self.indicatorLine.frame = CGRectMake(CGRectGetMaxX(self.editView.validRect)-2, 0, 2, [ZLEditVideoUX share].collectionItemHeight);
    } completion:nil];
}

- (void)stopTimer
{
    [_timer invalidate];
    _timer = nil;
    [self.indicatorLine removeFromSuperview];
    [self.playerLayer.player pause];
}

- (CMTime)getStartTime
{
    CGRect rect = [self.collectionView convertRect:self.editView.validRect fromView:self.editView];
    CGFloat s = MAX(0, self.perItemSeconds * rect.origin.x / ([ZLEditVideoUX share].collectionItemWidth));
    return CMTimeMakeWithSeconds(s, self.playerLayer.player.currentTime.timescale);
}

- (CMTimeRange)getTimeRange
{
    CMTime start = [self getStartTime];
    CGFloat d = self.perItemSeconds * self.editView.validRect.size.width / ([ZLEditVideoUX share].collectionItemWidth);
    CMTime duration = CMTimeMakeWithSeconds(d, self.playerLayer.player.currentTime.timescale);
    return CMTimeRangeMake(start, duration);
}

- (void)playPartVideo:(NSTimer *)timer
{
    [self.playerLayer.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self.playerLayer.player play];
}

#pragma mark - edit view delegate
- (void)editViewValidRectChanged
{
    [self stopTimer];
    [self.playerLayer.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)editViewValidRectEndChanged
{
    [self startTimer];
}

#pragma mark - scroll view delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.playerLayer.player || _orientationChanged) {
        _orientationChanged = NO;
        return;
    }
    [self stopTimer];
    [self.playerLayer.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self startTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self startTimer];
}

#pragma mark - collection view data sources
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.itemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZLEditVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ZLEditVideoCell" forIndexPath:indexPath];
    
    UIImage *image = self.imageCache[@(indexPath.row).stringValue];
    if (image) {
        cell.imageView.image = image;
    }
    
    return cell;
}

static const char _ZLOperationCellKey;
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.avAsset) return;
    
    if (self.imageCache[@(indexPath.row).stringValue] || self.operationCache[@(indexPath.row).stringValue]) {
        return;
    }
    __weak ZLEditVideoController *weakSelf = self;
     NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        NSInteger row = indexPath.row;
         // 每次尝试7次截图，如果都获取不到那就只有黑屏
         int j = 0;
         for (int i = 0; i < 7; i ++) {
             if (i % 2 > 0) {
                 j ++;
             }
             CGFloat offset = (i % 2) > 0 ? -1 * j / 10.0 : j / 10.0;
             CGFloat timeDur = (row + 0.5 + offset) * weakSelf.perItemSeconds;
             CMTime time = CMTimeMake(timeDur * weakSelf.avAsset.duration.timescale, weakSelf.avAsset.duration.timescale);
             NSError *error = nil;
             CGImageRef cgImg = [weakSelf.generator copyCGImageAtTime:time actualTime:NULL error:&error];
             if (!error && cgImg) {
                 UIImage *image = [UIImage imageWithCGImage:cgImg];
                 CGImageRelease(cgImg);
                 
                 [weakSelf.imageCache setValue:image forKey:@(row).stringValue];
                 dispatch_async(dispatch_get_main_queue(), ^{
                     NSIndexPath *nowIndexPath = [collectionView indexPathForCell:cell];
                     if (row == nowIndexPath.row) {
                         [(ZLEditVideoCell *)cell imageView].image = image;
                     } else {
                         UIImage *cacheImage = weakSelf.imageCache[@(nowIndexPath.row).stringValue];
                         if (cacheImage) {
                             [(ZLEditVideoCell *)cell imageView].image = cacheImage;
                         }
                     }
                 });
                 [weakSelf.operationCache removeObjectForKey:@(row).stringValue];
                 break;
             }
         }
        objc_removeAssociatedObjects(cell);
    }];
    [self.getImageCacheQueue addOperation:op];
    [self.operationCache setValue:op forKey:@(indexPath.row).stringValue];
    objc_setAssociatedObject(cell, &_ZLOperationCellKey, op, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSBlockOperation *op = objc_getAssociatedObject(cell, &_ZLOperationCellKey);
    if (op) {
        [op cancel];
        objc_removeAssociatedObjects(cell);
        [self.operationCache removeObjectForKey:@(indexPath.row).stringValue];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
