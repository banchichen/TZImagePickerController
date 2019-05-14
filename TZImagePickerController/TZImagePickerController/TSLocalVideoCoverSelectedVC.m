//
//  TSLocalVideoCoverSelectedVC.m
//  ThinkSNSPlus
//
//  Created by SmellOfTime on 2018/7/20.
//  Copyright © 2018年 ZhiYiCX. All rights reserved.

#import "TSLocalVideoCoverSelectedVC.h"
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <sys/utsname.h>
#import "TZImagePickerController.h"
/*
 固定底部固定铺满10个item
 */
@interface TSLocalVideoCoverSelectedUX : NSObject

@property (nonatomic, assign) CGRect validRect;

@property (nonatomic, assign, readonly) CGFloat collectionItemHeight;
@property (nonatomic, assign) CGFloat collectionItemWidth;

+ (TSLocalVideoCoverSelectedUX*)share;

@end

@implementation TSLocalVideoCoverSelectedUX
+ (TSLocalVideoCoverSelectedUX*)share {
    static TSLocalVideoCoverSelectedUX *_share;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _share = [[TSLocalVideoCoverSelectedUX alloc]init];
        _share.collectionItemWidth = 50;
    });
    return _share;
}
// 默认设置高度
- (CGFloat)collectionItemHeight {
    return 50;
}
@end

///////-----cell
@interface TSLocalEditVideoCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation TSLocalEditVideoCell

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

@protocol TSLocalEditFrameViewDelegate <NSObject>

- (void)editViewValidRectChanged;

- (void)editViewValidRectEndChanged;

@end

///////-----编辑框
@interface TSLocalEditFrameView : UIView
{

}

@property (nonatomic, assign) CGRect validRect;
@property (nonatomic, weak) id<TSLocalEditFrameViewDelegate> delegate;
@property (nonatomic, strong) UIImageView *selectedView;

@end

@implementation TSLocalEditFrameView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self creatUI];
    }
    return self;
}
- (void)creatUI
{
    self.backgroundColor = [UIColor clearColor];
    _selectedView = [[UIImageView alloc] initWithImage: [UIImage tz_imageNamedFromMyBundle: @"pic_cover_frame"]];
    _selectedView.userInteractionEnabled = YES;
    _selectedView.tag = 0;
    UIPanGestureRecognizer *lg = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [_selectedView addGestureRecognizer:lg];
    [self addSubview:_selectedView];
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect left = _selectedView.frame;
    left.origin.x -= 30 / 2;
    left.size.width += 30 / 2;
    if (CGRectContainsPoint(left, point)) {
        return _selectedView;
    }
    return nil;
}
- (void)panAction:(UIGestureRecognizer *)pan
{
    CGPoint point = [pan locationInView:self];
    CGRect rct = self.validRect;
    const CGFloat W = self.frame.size.width;
    CGFloat minX = 0;
    CGFloat maxX = W;
    
    maxX = rct.origin.x + rct.size.width;
    point.x = MAX(minX, MIN(point.x, maxX));
    point.y = 0;
    rct.size.width -= (point.x - rct.origin.x);
    rct.origin.x = point.x;
    
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
    _selectedView.frame = CGRectMake(validRect.origin.x >= 30 / 2.0 ?  (validRect.origin.x - 30 / 2.0) : validRect.origin.x - 30.0 / 2, 0, 30, [TSLocalVideoCoverSelectedUX  share].collectionItemHeight);
    [self setNeedsDisplay];
}

@end


///////-----TSLocalVideoCoverSelectedVC
@interface TSLocalVideoCoverSelectedVC () <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, TSLocalEditFrameViewDelegate>
{
    
}
// Jar
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIImage *> *imageCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSBlockOperation *> *operationCache;
// UI
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIImageView *centerImageView;
@property (nonatomic, strong) TSLocalEditFrameView *editView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *bottomView;
// Other
@property (nonatomic, strong) AVAssetImageGenerator *generator;
@property (nonatomic, assign) NSTimeInterval perItemSeconds;
@property (nonatomic, strong) NSOperationQueue *getImageCacheQueue;
@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) UIImage *selectedImage ;
@property (nonatomic, assign) NSInteger videoItemCount;

@end

@implementation TSLocalVideoCoverSelectedVC

- (void)dealloc
{
    [self.getImageCacheQueue cancelAllOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"---- %s", __FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initJar];
    [self creatNavUI];
    [self getDefaultImage:^{
        [self creatUI];
    }];
}

- (void)initJar {
    self.asset = [AVURLAsset assetWithURL:self.videoPath];
    self.imageCache = [NSMutableDictionary dictionary];
    self.operationCache = [NSMutableDictionary dictionary];
    self.getImageCacheQueue = [[NSOperationQueue alloc] init];
    self.getImageCacheQueue.maxConcurrentOperationCount = 3;
}

- (void)creatNavUI {
    self.navigationItem.title = @"封面选择";

    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(0, 0, 44, 44);
    rightButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [rightButton setTitle: @"完成" forState:UIControlStateNormal];
    if (_mainColor) {
        [rightButton setTitleColor:_mainColor forState:UIControlStateNormal];
    } else {
        [rightButton setTitleColor:[UIColor colorWithRed:89/255.0 green:182/255.0 blue:215/255.0 alpha:1] forState:UIControlStateNormal];
    }
    [rightButton addTarget:self action:@selector(rightButtonClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(0, 0, 44, 44);
    if (_backImage) {
        [leftButton setImage:_backImage forState:UIControlStateNormal];
    } else {
        [leftButton setImage:[UIImage tz_imageNamedFromMyBundle:@"topbar_back"] forState:UIControlStateNormal];
    }
    [leftButton addTarget:self action:@selector(navLeftBarButtonClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (@available(iOS 11, *)) {
        inset = self.view.safeAreaInsets;
    }
    self.collectionView.frame = CGRectMake(inset.left, 0, [[UIScreen mainScreen] bounds].size.width - inset.left - inset.right, [TSLocalVideoCoverSelectedUX  share].collectionItemHeight);
    self.editView.frame = self.collectionView.bounds;
    self.editView.validRect = self.editView.bounds;
    self.bottomView.frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - [TSLocalVideoCoverSelectedUX  share].collectionItemHeight - 15 -inset.bottom, [[UIScreen mainScreen] bounds].size.width, [TSLocalVideoCoverSelectedUX  share].collectionItemHeight);
    self.centerImageView.frame = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height,[[UIScreen mainScreen] bounds].size.width, self.bottomView.frame.origin.y - ( self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height));
}


- (void)creatUI
{
    self.bgView = [[UIView alloc]initWithFrame:CGRectMake(0, ([self tsIsIPhoneX] ? 24 : 0) + 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.bgView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.bgView];

    //禁用返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.centerImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 300)];
    self.centerImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.centerImageView.backgroundColor = [UIColor clearColor];
    self.centerImageView.image = self.selectedImage;
    [self.view addSubview:self.centerImageView];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake([TSLocalVideoCoverSelectedUX  share].collectionItemWidth, [TSLocalVideoCoverSelectedUX  share].collectionItemHeight);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self.collectionView registerClass:TSLocalEditVideoCell.class forCellWithReuseIdentifier:@"TSLocalEditVideoCell"];
    
    [self creatBottomView];
    [self.bottomView addSubview:self.collectionView];

    self.editView = [[TSLocalEditFrameView alloc] init];
    if (_picCoverImage) {
        self.editView.selectedView.image = _picCoverImage;
    }
    self.editView.delegate = self;
    [self.bottomView addSubview:self.editView];
}

- (void)creatBottomView
{
    //下方视图
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1];
    [self.view addSubview:self.bottomView];
}

// MARK: - tool
// 解析默认第一帧图片
- (void)getDefaultImage:(void (^)(void))completion {
    float duration = CMTimeGetSeconds(self.asset.duration);
    // 底部的预览栏目
    if (duration <= 10) {
        UIEdgeInsets inset = UIEdgeInsetsZero;
        if (@available(iOS 11, *)) {
            inset = self.view.safeAreaInsets;
        }
        self.videoItemCount = 10;
        self.perItemSeconds = duration / self.videoItemCount;
    } else {
        // 固定单个图片的时间为1s
        self.perItemSeconds = 1.0;
        self.videoItemCount = (NSInteger)duration;
    }

    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:self.videoPath options:opts];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = YES;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    self.generator = generator;
    NSError *error = nil;
    CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(0, self.asset.duration.timescale) actualTime:NULL error:&error];
    if (img != nil) {
        UIImage *image = [UIImage imageWithCGImage:img];
        CGFloat WHScale = image.size.width / image.size.height;
        [TSLocalVideoCoverSelectedUX  share].collectionItemWidth = [TSLocalVideoCoverSelectedUX  share].collectionItemHeight * WHScale;
        // 如果不能铺满整个collocationView就不按原始图片比例
        if ([TSLocalVideoCoverSelectedUX  share].collectionItemWidth * self.videoItemCount < [UIScreen mainScreen].bounds.size.width) {
            [TSLocalVideoCoverSelectedUX share].collectionItemWidth = [UIScreen mainScreen].bounds.size.width / self.videoItemCount;
        }
        self.selectedImage = image;
        CGImageRelease(img);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    } else {
        NSError *error = nil;
        CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(0.15, self.asset.duration.timescale) actualTime:NULL error:&error];
        if (img != nil) {
            UIImage *image = [UIImage imageWithCGImage:img];
            CGFloat WHScale = image.size.width / image.size.height;
            [TSLocalVideoCoverSelectedUX  share].collectionItemWidth = [TSLocalVideoCoverSelectedUX  share].collectionItemHeight * WHScale;
            // 如果不能铺满整个collocationView就不按原始图片比例
            if ([TSLocalVideoCoverSelectedUX  share].collectionItemWidth * self.videoItemCount < [UIScreen mainScreen].bounds.size.width) {
                [TSLocalVideoCoverSelectedUX share].collectionItemWidth = [UIScreen mainScreen].bounds.size.width / self.videoItemCount;
            }
            self.selectedImage = image;
            CGImageRelease(img);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion();
                }
            });
        } else {
            NSLog(@"解析不到啊");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion();
                }
            });
        }
    }
}
- (BOOL)tsIsIPhoneX {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if ([platform isEqualToString:@"i386"] || [platform isEqualToString:@"x86_64"]) {
        return (CGSizeEqualToSize([UIScreen mainScreen].bounds.size, CGSizeMake(375, 812)) ||
                CGSizeEqualToSize([UIScreen mainScreen].bounds.size, CGSizeMake(812, 375)));
    }
    BOOL isIPhoneX = [platform isEqualToString:@"iPhone10,3"] || [platform isEqualToString:@"iPhone10,6"];
    return isIPhoneX;
}
// 获取当前选中的时间点
- (CMTime)getSelectedNowTime
{
    CGRect rect = [self.collectionView convertRect:self.editView.validRect fromView:self.editView];
    CGFloat s = MAX(0, self.perItemSeconds * rect.origin.x / ([TSLocalVideoCoverSelectedUX  share].collectionItemWidth));
    return CMTimeMakeWithSeconds(s, self.asset.duration.timescale);
}
// 获取下一个时间点
// 主要用于当前时间点获取失败的时候，去获取下一个10%个单位时间的截图
- (CMTime)getSelectedNextTime
{
    CGRect rect = [self.collectionView convertRect:self.editView.validRect fromView:self.editView];
    CGFloat s = MAX(0, self.perItemSeconds * rect.origin.x / ([TSLocalVideoCoverSelectedUX  share].collectionItemWidth)) + 0.1 * self.perItemSeconds;
    return CMTimeMakeWithSeconds(s, self.asset.duration.timescale);
}

// MARK: - action
- (void)navLeftBarButtonClick{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)rightButtonClick {
    NSLog(@"完成\n\n");
    if (self.coverImageBlock) {
        if (self.centerImageView.image == nil) {
            NSLog(@"当前选中封面不可用，请重新选择");
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"当前选中封面不可用，请重新选择。" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }];
            [alertVC addAction:sureAction];
            [self presentViewController:alertVC animated:YES completion:nil];
        } else {
            self.coverImageBlock(self.centerImageView.image, self.videoPath);
        }
    } else {
        NSLog(@"\n\n注意：没有实现选择封面完成block\n\n");
    }
}

// MARK: - edit view delegate
- (void)editViewValidRectChanged
{
    static CGFloat curentTime = 0;
    if (curentTime == CMTimeGetSeconds([self getSelectedNowTime])) {
        return;
    }
    curentTime =  CMTimeGetSeconds([self getSelectedNowTime]);

    NSError *error = nil;
    CGImageRef img = [self.generator copyCGImageAtTime:[self getSelectedNowTime] actualTime:NULL error:&error];
    if (img != nil) {
        UIImage *image = [UIImage imageWithCGImage:img];
        self.centerImageView.image = image;
        CGImageRelease(img);
    } else {
        NSLog(@"editViewValidRectChanged eror - %@", error);
    }
}

- (void)editViewValidRectEndChanged
{
//    [self startTimer];
//    NSError *error = nil;
//    CGImageRef img = [self.generator copyCGImageAtTime:[self getSelectedNowTime] actualTime:NULL error:&error];
//    {
//        UIImage *image = [UIImage imageWithCGImage:img];
//        self.centerImageView.image = image;
//    }
}

// MARK: - scroll view delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    NSLog(@"scrollViewDidEndDragging %d", decelerate);
    if (!decelerate) {
        [self scrollViewEndScroll:scrollView];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self scrollViewEndScroll:scrollView];
}

// collection停止滚动就更新一下封面图
- (void)scrollViewEndScroll:(UIScrollView *)scrollView {
    NSError *error = nil;
    CGImageRef img = [self.generator copyCGImageAtTime:[self getSelectedNowTime] actualTime:NULL error:&error];
    if (img != nil) {
        UIImage *image = [UIImage imageWithCGImage:img];
        self.centerImageView.image = image;
        CGImageRelease(img);
    } else {
        
    }
}


// MARK: - collection view data sources
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.videoItemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TSLocalEditVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TSLocalEditVideoCell" forIndexPath:indexPath];
    UIImage *image = _imageCache[@(indexPath.row).stringValue];
    if (image) {
        cell.imageView.image = image;
    }
    return cell;
}

static const char _TSOperationCellKey;
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.asset) return;
    
    if (_imageCache[@(indexPath.row).stringValue] || _operationCache[@(indexPath.row).stringValue]) {
        return;
    }
    __weak TSLocalVideoCoverSelectedVC *wkSelf = self;
     NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
         NSInteger row = indexPath.row;
         NSInteger timeDur = (row + 0.5) * wkSelf.perItemSeconds;
         // 每次尝试7次截图，如果都获取不到那就只有黑屏
         int j = 0;
         for (int i = 0; i < 7; i ++) {
             if (i % 2 > 0) {
                 j ++;
             }
             CGFloat offset = (i % 2) > 0 ? -1 * j / 10.0 : j / 10.0;
             CGFloat timeDur = (row + 0.5 + offset) * wkSelf.perItemSeconds;
             CMTime time = CMTimeMake((timeDur) * wkSelf.asset.duration.timescale, wkSelf.asset.duration.timescale);
             NSError *error = nil;
             CGImageRef cgImg = [wkSelf.generator copyCGImageAtTime:time actualTime:NULL error:&error];
             if (!error && cgImg) {
                 UIImage *image = [UIImage imageWithCGImage:cgImg];
                 CGImageRelease(cgImg);
                 [wkSelf.imageCache setValue:image forKey:@(row).stringValue];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     NSIndexPath *nowIndexPath = [collectionView indexPathForCell:cell];
                     if (row == nowIndexPath.row) {
                         [(TSLocalEditVideoCell *)cell imageView].image = image;
                     } else {
                         UIImage *cacheImage = wkSelf.imageCache[@(nowIndexPath.row).stringValue];
                         if (cacheImage) {
                             [(TSLocalEditVideoCell *)cell imageView].image = cacheImage;
                         }
                     }
                 });
                 [wkSelf.operationCache removeObjectForKey:@(row).stringValue];
                 break;
             }
         }
        objc_removeAssociatedObjects(cell);
    }];
    [self.getImageCacheQueue addOperation:op];
    [_operationCache setValue:op forKey:@(indexPath.row).stringValue];
    objc_setAssociatedObject(cell, &_TSOperationCellKey, op, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSBlockOperation *op = objc_getAssociatedObject(cell, &_TSOperationCellKey);
    if (op) {
        [op cancel];
        objc_removeAssociatedObjects(cell);
        [_operationCache removeObjectForKey:@(indexPath.row).stringValue];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
