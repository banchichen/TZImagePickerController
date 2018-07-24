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

#define kItemWidth kItemHeight * 2/3
#define kItemHeight 50
#define maxEditVideoTime 5
/*
 固定底部固定铺满10个item
 */
static inline CGFloat GetMatchValue(NSString *text, CGFloat fontSize, BOOL isHeightFixed, CGFloat fixedValue) {
    CGSize size;
    if (isHeightFixed) {
        size = CGSizeMake(MAXFLOAT, fixedValue);
    } else {
        size = CGSizeMake(fixedValue, MAXFLOAT);
    }
    
    CGSize resultSize;
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        //返回计算出的size
        resultSize = [text boundingRectWithSize:size options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]} context:nil].size;
    }
    if (isHeightFixed) {
        return resultSize.width;
    } else {
        return resultSize.height;
    }
}

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
    UIImageView *_leftView;
    UIImageView *_rightView;
}

@property (nonatomic, assign) CGRect validRect;
@property (nonatomic, weak) id<ZLEditFrameViewDelegate> delegate;

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
    left.origin.x -= kItemWidth/2;
    left.size.width += kItemWidth/2;
    CGRect right = _rightView.frame;
    right.size.width += kItemWidth/2;
    
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
            maxX = rct.origin.x + rct.size.width - kItemWidth;
            
            point.x = MAX(minX, MIN(point.x, maxX));
            point.y = 0;
            
            rct.size.width -= (point.x - rct.origin.x);
            rct.origin.x = point.x;
        }
            break;
            
        case 1:
        {
            //right
            minX = rct.origin.x + kItemWidth/2;
            maxX = W - kItemWidth/2;
            
            point.x = MAX(minX, MIN(point.x, maxX));
            point.y = 0;
            
            rct.size.width = (point.x - rct.origin.x + kItemWidth/2);
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
    _validRect = validRect;
    _leftView.frame = CGRectMake(validRect.origin.x, 0, kItemWidth/2, kItemHeight);
    _rightView.frame = CGRectMake(validRect.origin.x+validRect.size.width-kItemWidth/2, 0, kItemWidth/2, kItemHeight);
    
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
    bottomPoints[0] = CGPointMake(self.validRect.origin.x, kItemHeight);
    bottomPoints[1] = CGPointMake(self.validRect.origin.x+self.validRect.size.width, kItemHeight);
    
    CGContextAddLines(context, topPoints, 2);
    CGContextAddLines(context, bottomPoints, 2);
    
    CGContextDrawPath(context, kCGPathStroke);
}

@end


///////-----editvc
@interface ZLEditVideoController () <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, ZLEditFrameViewDelegate>
{
    UIView *_bottomView;
    NSTimer *_timer;
    
    //下方collectionview偏移量
    CGFloat _offsetX;
    BOOL _orientationChanged;
    
    UIView *_indicatorLine;
    
    AVAsset *_avAsset;
    
    NSTimeInterval _interval;
    
    NSInteger _measureCount;
    NSOperationQueue *_queue;
    NSMutableDictionary<NSString *, UIImage *> *_imageCache;
    NSMutableDictionary<NSString *, NSBlockOperation *> *_opCache;
}

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ZLEditFrameView *editView;
@property (nonatomic, strong) AVAssetImageGenerator *generator;
@property (nonatomic, strong) UIView *bgView;

@end

@implementation ZLEditVideoController

- (void)dealloc
{
    [_queue cancelAllOperations];
    [self stopTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"---- %s", __FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bgView = [[UIView alloc]initWithFrame:CGRectMake(0, ([self zl_isIPhoneX] ? 24 : 0) + 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:self.bgView];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    

    [self analysisAssetImages];
    [self setupUI];

    _queue = [[NSOperationQueue alloc] init];
    _queue.maxConcurrentOperationCount = 3;
    
    _imageCache = [NSMutableDictionary dictionary];
    _opCache = [NSMutableDictionary dictionary];
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    rightButton.frame = CGRectMake(0, 0, 44, 44);
    rightButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [rightButton setTitle: @"完成" forState:UIControlStateNormal];
    [rightButton setTitleColor:[UIColor colorWithRed:89/255.0 green:182/255.0 blue:215/255.0 alpha:1] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(rightButtonClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(0, 0, 44, 44);
    [leftButton setImage:[UIImage imageNamedFromMyBundle:@"topbar_back"] forState:UIControlStateNormal];
    [leftButton addTarget:self action:@selector(navLeftBarButtonClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftButton];

    self.navigationItem.title = @"裁剪视频";

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)navLeftBarButtonClick{
    [self.playerLayer.player pause];
    self.playerLayer.player = nil;
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    [self stopTimer];
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)rightButtonClick {
    NSLog(@"完成\n\n");
    [self saveBtnClick];

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
    [self startTimer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopTimer];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (@available(iOS 11, *)) {
        inset = self.view.safeAreaInsets;
    }
    self.editView.frame = CGRectMake(([[UIScreen mainScreen] bounds].size.width-kItemWidth*10)/2,0, kItemWidth*10, kItemHeight);
    self.editView.validRect = self.editView.bounds;
    self.collectionView.frame = CGRectMake(inset.left, 0, [[UIScreen mainScreen] bounds].size.width - inset.left - inset.right, kItemHeight);
    
    CGFloat leftOffset = (([[UIScreen mainScreen] bounds].size.width-kItemWidth*10)/2-inset.left);
    CGFloat rightOffset = (([[UIScreen mainScreen] bounds].size.width-kItemWidth*10)/2-inset.right);
    [self.collectionView setContentInset:UIEdgeInsetsMake(0, leftOffset, 0, rightOffset)];
    [self.collectionView setContentOffset:CGPointMake(_offsetX-leftOffset, 0)];
    _bottomView.frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - kItemHeight - 15 -inset.bottom, [[UIScreen mainScreen] bounds].size.width, kItemHeight);
    self.playerLayer.frame = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height,[[UIScreen mainScreen] bounds].size.width, _bottomView.frame.origin.y - ( self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height));
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
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(kItemWidth, kItemHeight);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self.collectionView registerClass:ZLEditVideoCell.class forCellWithReuseIdentifier:@"ZLEditVideoCell"];
    
    [self creatBottomView];
    [_bottomView addSubview:self.collectionView];

    self.editView = [[ZLEditFrameView alloc] init];
    self.editView.delegate = self;
    [_bottomView addSubview:self.editView];
    
    _indicatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, kItemHeight)];
    _indicatorLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:.7];
}

- (void)creatBottomView
{
    //下方视图
    _bottomView = [[UIView alloc] init];
    _bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1];
    [self.view addSubview:_bottomView];
}

#pragma mark - 解析视频每一帧图片
- (void)analysisAssetImages
{
    float duration = roundf(self.asset.duration);
    if (duration <= maxEditVideoTime) {
        UIEdgeInsets inset = UIEdgeInsetsZero;
        if (@available(iOS 11, *)) {
            inset = self.view.safeAreaInsets;
        }
        _measureCount = 10;
        _interval = duration / _measureCount;
        self.collectionView.scrollEnabled = NO;
    } else {
        // 固定单个图片的时间为1s
        _interval = 1.0;
        _measureCount = (NSInteger)duration;
        self.collectionView.scrollEnabled = YES;
    }

    [[PHCachingImageManager defaultManager] requestPlayerItemForVideo:self.asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!playerItem) return;
                AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
                self.playerLayer.player = player;
                [self startTimer];
            });
    }];
    PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        NSLog(@"requestAVAssetForVideo asset-%@ -%@", asset, info);
        __weak typeof(self) weakSelf = self;
        _avAsset = asset;
        _generator = [[AVAssetImageGenerator alloc] initWithAsset:_avAsset];
        //        _generator.maximumSize = CGSizeMake(kItemWidth*4, kItemHeight*4);
        _generator.appliesPreferredTrackTransform = YES;
        _generator.requestedTimeToleranceBefore = kCMTimeZero;
        _generator.requestedTimeToleranceAfter = kCMTimeZero;
        _generator.apertureMode = AVAssetImageGeneratorApertureModeProductionAperture;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.collectionView reloadData];
        });
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

- (void)saveBtnClick {
    [self stopTimer];
    __weak typeof(self) weakSelf = self;
    [self exportPHAsset:self.asset range:[self getTimeRange] complete:^(NSString *exportFilePath, NSError *error) {
        NSLog(@"error -%@",error);
        // sot todo
        if (error == nil) {
            TSLocalVideoCoverSelectedVC *vc = [[TSLocalVideoCoverSelectedVC alloc]init];
            vc.videoPath = [NSURL fileURLWithPath:exportFilePath];
            vc.coverImageBlock = ^(UIImage *coverImage, NSURL *videoPath) {
                if (self.coverImageBlock) {
                    self.coverImageBlock(coverImage, videoPath);
                }
            };
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            
        }
    }];
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
    NSString *exportFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", [self getUniqueStrByUUID],  @"mp4"]];
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
    
    CGFloat duration = _interval * self.editView.validRect.size.width / (kItemWidth);
    _timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(playPartVideo:) userInfo:nil repeats:YES];
    [_timer fire];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
    _indicatorLine.frame = CGRectMake(self.editView.validRect.origin.x, 0, 2, kItemHeight);
    [self.editView addSubview:_indicatorLine];
    [UIView animateWithDuration:duration delay:.0 options:UIViewAnimationOptionRepeat|UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear animations:^{
        _indicatorLine.frame = CGRectMake(CGRectGetMaxX(self.editView.validRect)-2, 0, 2, kItemHeight);
    } completion:nil];
}

- (void)stopTimer
{
    [_timer invalidate];
    _timer = nil;
    [_indicatorLine removeFromSuperview];
    [self.playerLayer.player pause];
}

- (CMTime)getStartTime
{
    CGRect rect = [self.collectionView convertRect:self.editView.validRect fromView:self.editView];
    CGFloat s = MAX(0, _interval * rect.origin.x / (kItemWidth));
    return CMTimeMakeWithSeconds(s, self.playerLayer.player.currentTime.timescale);
}

- (CMTimeRange)getTimeRange
{
    CMTime start = [self getStartTime];
    CGFloat d = _interval * self.editView.validRect.size.width / (kItemWidth);
    CMTime duration = CMTimeMakeWithSeconds(d, self.playerLayer.player.currentTime.timescale);
    return CMTimeRangeMake(start, duration);
}

- (void)playPartVideo:(NSTimer *)timer
{
    [self.playerLayer.player play];
    [self.playerLayer.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
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
    return _measureCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZLEditVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ZLEditVideoCell" forIndexPath:indexPath];
    
    UIImage *image = _imageCache[@(indexPath.row).stringValue];
    if (image) {
        cell.imageView.image = image;
    }
    
    return cell;
}

static const char _ZLOperationCellKey;
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_avAsset) return;
    
    if (_imageCache[@(indexPath.row).stringValue] || _opCache[@(indexPath.row).stringValue]) {
        return;
    }
    
     NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        NSInteger row = indexPath.row;
        NSInteger i = row  * _interval;
        
        CMTime time = CMTimeMake((i+0.35) * _avAsset.duration.timescale, _avAsset.duration.timescale);
        
        NSError *error = nil;
        CGImageRef cgImg = [self.generator copyCGImageAtTime:time actualTime:NULL error:&error];
        if (!error && cgImg) {
            UIImage *image = [UIImage imageWithCGImage:cgImg];
            CGImageRelease(cgImg);

            [_imageCache setValue:image forKey:@(row).stringValue];

            dispatch_async(dispatch_get_main_queue(), ^{

                NSIndexPath *nowIndexPath = [collectionView indexPathForCell:cell];
                if (row == nowIndexPath.row) {
                    [(ZLEditVideoCell *)cell imageView].image = image;
                } else {
                    UIImage *cacheImage = _imageCache[@(nowIndexPath.row).stringValue];
                    if (cacheImage) {
                        [(ZLEditVideoCell *)cell imageView].image = cacheImage;
                    }
                }
            });
            [_opCache removeObjectForKey:@(row).stringValue];
        }
        objc_removeAssociatedObjects(cell);
    }];
    [_queue addOperation:op];
    [_opCache setValue:op forKey:@(indexPath.row).stringValue];
    
    objc_setAssociatedObject(cell, &_ZLOperationCellKey, op, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSBlockOperation *op = objc_getAssociatedObject(cell, &_ZLOperationCellKey);
    if (op) {
        [op cancel];
        objc_removeAssociatedObjects(cell);
        [_opCache removeObjectForKey:@(indexPath.row).stringValue];
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
