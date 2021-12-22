//
//  TZVideoCropController.m
//  TZImagePickerController
//
//  Created by 肖兰月 on 2021/5/27.
//  Copyright © 2021 谭真. All rights reserved.
//

#import "TZVideoCropController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+TZLayout.h"
#import "TZImageManager.h"
#import "TZAssetModel.h"
#import "TZImagePickerController.h"

@interface TZVideoCropController ()<TZVideoEditViewDelegate,UICollectionViewDelegate, UICollectionViewDataSource> {
    AVPlayer *_player;
    AVPlayerLayer *_playerLayer;
    UIButton *_playButton;
    UIImage *_cover;
    NSString *_outputPath;
    NSString *_errorMsg;
    
    UIButton *_cancelButton;
    UIButton *_doneButton;
    UIProgressView *_progress;
    UILabel *_cropVideoDurationLabel;
    
    AVAssetImageGenerator *_imageGenerator;
    AVAsset *_asset;
    
    CGFloat _collectionViewBeginOffsetX;
    BOOL _isPlayed;
    CGFloat _itemW;
    BOOL _isDraging;
    
    UIStatusBarStyle _originStatusBarStyle;
}

// iCloud无法同步提示UI
@property (nonatomic, strong) UIView *iCloudErrorView;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) TZVideoEditView *videoEditView;
@property (strong, nonatomic) NSMutableArray *videoImgArray;
@property (strong, nonatomic) NSArray *imageTimes;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation TZVideoCropController

#define VideoEditLeftMargin 40
#define PanImageWidth 10
#define MinCropVideoDuration 1

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self configMoviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayer) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopTimer];
}

- (void)configMoviePlayer {
    [[TZImageManager manager] getPhotoWithAsset:_model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        BOOL iCloudSyncFailed = !photo && [TZCommonTools isICloudSyncError:info[PHImageErrorKey]];
        self.iCloudErrorView.hidden = !iCloudSyncFailed;
        self->_doneButton.enabled = !iCloudSyncFailed;
    }];
    [[TZImageManager manager] getVideoWithAsset:_model.asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_asset = playerItem.asset;
            self->_player = [AVPlayer playerWithPlayerItem:playerItem];
            self->_playerLayer = [AVPlayerLayer playerLayerWithPlayer:self->_player];
            self->_playerLayer.frame = self.view.bounds;
            [self.view.layer addSublayer:self->_playerLayer];
            [self configPlayButton];
            [self configBottomToolBar];
            if (self.imagePickerVc.allowEditVideo) {
                [self configVideoImageCollectionView];
                [self configVideoEditView];
                [self generateVideoImage];
            }
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayer) name:AVPlayerItemDidPlayToEndTimeNotification object:self->_player.currentItem];
        });
    }];
}

- (void)configPlayButton {
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playButton setImage:[UIImage tz_imageNamedFromMyBundle:@"MMVideoPreviewPlay"] forState:UIControlStateNormal];
    [_playButton setImage:[UIImage tz_imageNamedFromMyBundle:@"MMVideoPreviewPlayHL"] forState:UIControlStateHighlighted];
    [_playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playButton];
}

- (void)configBottomToolBar {
    _cropVideoDurationLabel = UILabel.new;
    _cropVideoDurationLabel.textAlignment = NSTextAlignmentCenter;
    _cropVideoDurationLabel.textColor = UIColor.whiteColor;
    _cropVideoDurationLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:_cropVideoDurationLabel];
    
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_cancelButton setTitle:[NSBundle tz_localizedStringForKey:@"Cancel"] forState:0];
    [_cancelButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cancelButton];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:self.imagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
    [_doneButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [_doneButton setTitleColor:self.imagePickerVc.oKButtonTitleColorDisabled forState:UIControlStateDisabled];
    [self.view addSubview:_doneButton];
    
    if (self.imagePickerVc.videoEditViewPageUIConfigBlock) {
        self.imagePickerVc.videoEditViewPageUIConfigBlock(_playButton, _cropVideoDurationLabel, _cancelButton, _doneButton);
    }
}

- (void)configVideoImageCollectionView {
    _itemW = (self.view.tz_width - VideoEditLeftMargin * 2 - 2 * PanImageWidth) / 10.0;
    UICollectionViewFlowLayout *layout = UICollectionViewFlowLayout.new;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(_itemW, _itemW * 2);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.contentInset = UIEdgeInsetsMake(0, VideoEditLeftMargin + PanImageWidth, 0, VideoEditLeftMargin + PanImageWidth);
    _collectionView.clipsToBounds = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.alwaysBounceHorizontal = YES;
    [_collectionView registerClass:TZVideoPictureCell.class forCellWithReuseIdentifier:@"TZVideoPictureCell"];
    [self.view addSubview:_collectionView];
}

- (void)configVideoEditView {
    _videoEditView = TZVideoEditView.new;
    _videoEditView.backgroundColor = UIColor.clearColor;
    _videoEditView.delegate = self;
    _videoEditView.maxCropVideoDuration = self.imagePickerVc.maxCropVideoDuration;
    [self.view addSubview:_videoEditView];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.imagePickerVc && [self.imagePickerVc isKindOfClass:[TZImagePickerController class]]) {
        return self.imagePickerVc.statusBarStyle;
    }
    return [super preferredStatusBarStyle];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    BOOL isFullScreen = self.view.tz_height == [UIScreen mainScreen].bounds.size.height;
    CGFloat statusBarHeight = isFullScreen ? [TZCommonTools tz_statusBarHeight] : 0;
    CGFloat statusBarAndNaviBarHeight = statusBarHeight + self.navigationController.navigationBar.tz_height;
    
    CGFloat toolBarHeight = 44 + [TZCommonTools tz_safeAreaInsets].bottom;
    CGFloat doneButtonWidth = [_doneButton.currentTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} context:nil].size.width;
    doneButtonWidth = MAX(44, doneButtonWidth);
    _cancelButton.frame = CGRectMake(12, self.view.tz_height - toolBarHeight, 44, 44);
    [_cancelButton sizeToFit];
    _cancelButton.tz_height = 44;
    _doneButton.frame = CGRectMake(self.view.tz_width - doneButtonWidth - 12, self.view.tz_height - toolBarHeight, doneButtonWidth, 44);
    _playButton.frame = CGRectMake(0, statusBarAndNaviBarHeight, self.view.tz_width, self.view.tz_height - statusBarAndNaviBarHeight - toolBarHeight);
    
    CGFloat collectionViewH = (self.view.tz_width - VideoEditLeftMargin * 2 - 2 * PanImageWidth) / 10.0 * 2;
    _collectionView.frame = CGRectMake(0, self.view.tz_height - collectionViewH - toolBarHeight - statusBarHeight, self.view.tz_width, collectionViewH);
    _videoEditView.frame = _collectionView.frame;
    _cropVideoDurationLabel.frame = CGRectMake(0, _videoEditView.tz_bottom, self.view.tz_width, 20);
    
    CGFloat playerLayerHeight = CGRectGetMinY(_collectionView.frame) - statusBarHeight * 2;
    CGFloat playerLayerWidth = self.view.tz_width/self.view.tz_height * playerLayerHeight;
    CGFloat playerLayerLeft = (self.view.tz_width - playerLayerWidth) / 2.0;
    CGRect playerLayerFrame = CGRectMake(playerLayerLeft, statusBarHeight, playerLayerWidth, playerLayerHeight);
    _playerLayer.frame = playerLayerFrame;
    _playButton.frame = CGRectMake(0, statusBarAndNaviBarHeight, self.view.tz_width, playerLayerHeight - statusBarAndNaviBarHeight);
   
    if (self.imagePickerVc.videoEditViewPageDidLayoutSubviewsBlock) {
        self.imagePickerVc.videoEditViewPageDidLayoutSubviewsBlock(_playButton, _cropVideoDurationLabel, _cancelButton, _doneButton);
    }
}

- (void)generateVideoImage {
    _imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_asset];
    _imageGenerator.appliesPreferredTrackTransform = YES;
    _imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    _imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    _imageGenerator.maximumSize = CGSizeMake(100, 100);
    
    NSTimeInterval durationSeconds = self.model.asset.duration;
    self.videoEditView.videoDuration = durationSeconds;
    
    NSUInteger imageCount = 10;
    CGFloat maxCropWidth = self.view.tz_width - (VideoEditLeftMargin + PanImageWidth) * 2;
    if (durationSeconds <= MinCropVideoDuration) return;
    if (durationSeconds <= self.imagePickerVc.maxCropVideoDuration) {
        imageCount = 10;
        self.videoEditView.allImgWidth = maxCropWidth;
        _cropVideoDurationLabel.text = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Selected for %ld seconds"], (NSInteger)durationSeconds];
    } else {
        CGFloat singleWidthSecond = maxCropWidth / self.imagePickerVc.maxCropVideoDuration;
        CGFloat allImgWidth = singleWidthSecond * durationSeconds;
        self.videoEditView.allImgWidth = allImgWidth;
        imageCount = allImgWidth / _itemW;
        _cropVideoDurationLabel.text = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Selected for %ld seconds"],(long)self.imagePickerVc.maxCropVideoDuration];
    }
    NSArray *assetTracks = [_asset tracksWithMediaType:AVMediaTypeVideo];
    if (!assetTracks.count) {
        self.iCloudErrorView.hidden = NO;
        _doneButton.enabled = NO;
        _cropVideoDurationLabel.hidden = YES;
        return;
    };
    Float64 frameRate = [[_asset tracksWithMediaType:AVMediaTypeVideo][0] nominalFrameRate];;
    NSMutableArray *times = NSMutableArray.array;
    NSTimeInterval intervalSecond = durationSeconds/imageCount;
    CMTime timeFrame;
    for (NSInteger i = 0; i < imageCount; i++) {
        timeFrame = CMTimeMake(intervalSecond * i *frameRate, frameRate);
        NSValue *timeValue = [NSValue valueWithCMTime:timeFrame];
        [times addObject:timeValue];
    }
    self.videoImgArray = NSMutableArray.new;
    self.imageTimes = times;
    typeof(self) weakSelf = self;
    [_imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        if (image) {
            UIImage *img = [[UIImage alloc] initWithCGImage:image];
            [weakSelf.videoImgArray addObject:img];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.collectionView reloadData];
            });
        }
    }];
}

#pragma mark - UICollectiobViewDataSource & UIcollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.videoImgArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TZVideoPictureCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZVideoPictureCell" forIndexPath:indexPath];
    cell.imgView.image = self.videoImgArray[indexPath.item];
    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_isDraging) return;
    CGFloat offsetX = scrollView.contentOffset.x;
    if (offsetX - _collectionViewBeginOffsetX >= self.view.tz_width) {
        [self.collectionView setContentOffset:CGPointMake(self.view.tz_width + _collectionViewBeginOffsetX, 0) animated:NO];
    } else if (_collectionViewBeginOffsetX - offsetX >= self.view.tz_width) {
        [self.collectionView setContentOffset:CGPointMake(_collectionViewBeginOffsetX - self.view.tz_width, 0) animated:NO];
    }
    
    [self editViewCropRectBeginChange];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _isDraging = YES;
    _collectionViewBeginOffsetX = scrollView.contentOffset.x;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _isDraging = NO;
    [self editViewCropRectEndChange];
}

#pragma mark - TZVideoEditViewDelegate

- (void)editViewCropRectBeginChange {
    [self stopTimer];
    [_playerLayer.player seekToTime:[self getCropStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    NSTimeInterval second = [self getCropVideoDuration];
    _cropVideoDurationLabel.text = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Selected for %ld seconds"], (NSInteger)second];
}

- (void)editViewCropRectEndChange {
    if (_isPlayed) {
        [self starTimer];
    }
}

#pragma mark - Click Event

- (void)playButtonClick {
    CMTime currentTime = _player.currentItem.currentTime;
    CMTime durationTime = _player.currentItem.duration;
    if (_player.rate == 0.0f) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TZ_VIDEO_PLAY_NOTIFICATION" object:_player];
        if (currentTime.value == durationTime.value) [_player.currentItem seekToTime:CMTimeMake(0, 1)];
        _isPlayed = YES;
        [self starTimer];
        [_playButton setImage:nil forState:UIControlStateNormal];
    } else {
        _isPlayed = NO;
        [self stopTimer];
        [self pausePlayer];
    }
}

- (void)cancelButtonClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)doneButtonClick {
    if ([[TZImageManager manager] isAssetCannotBeSelected:_model.asset]) {
        return;
    }
    [self stopTimer];
    
    TZImagePickerController *imagePickerVc = self.imagePickerVc;
    [imagePickerVc showProgressHUD];
    [[TZImageManager manager] getVideoOutputPathWithAsset:_model.asset presetName:imagePickerVc.presetName timeRange:[self getCropVideoTimeRange] success:^(NSString *outputPath) {
        [imagePickerVc hideProgressHUD];
        self->_outputPath = outputPath;
        [self dismissAndCallDelegateMethod];
    } failure:^(NSString *errorMessage, NSError *error) {
        [imagePickerVc hideProgressHUD];
        self->_errorMsg = errorMessage;
        [self dismissAndCallDelegateMethod];
    }];
}

- (void)dismissAndCallDelegateMethod {
    [self dismissViewControllerAnimated:NO completion:^{
        [self callDelegateMethod];
    }];
    [self.imagePickerVc dismissViewControllerAnimated:YES completion:nil];
}

- (void)callDelegateMethod {
    if (_outputPath) {
        NSURL *videoURL = [NSURL fileURLWithPath:_outputPath];
        if (self.imagePickerVc.saveEditedVideoToAlbum) {
            [[TZImageManager manager] saveVideoWithUrl:videoURL completion:^(PHAsset *asset, NSError *error) {
                if (error) { // 视频保存失败
                    if ([self.imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFailToSaveEditedVideoWithError:)]) {
                        [self.imagePickerVc.pickerDelegate imagePickerController:self.imagePickerVc didFailToSaveEditedVideoWithError:error];
                    }
                }
            }];
        }
        UIImage *coverImage = [[TZImageManager manager] getImageWithVideoURL:videoURL];
        if ([self.imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingAndEditingVideo:outputPath:error:)]) {
            [self.imagePickerVc.pickerDelegate imagePickerController:self.imagePickerVc didFinishPickingAndEditingVideo:coverImage outputPath:_outputPath error:nil];
        }
        if (self.imagePickerVc.didFinishPickingAndEditingVideoHandle) {
            self.imagePickerVc.didFinishPickingAndEditingVideoHandle(coverImage, _outputPath, nil);
        }
    } else {
        if ([self.imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingAndEditingVideo:outputPath:error:)]) {
            [self.imagePickerVc.pickerDelegate imagePickerController:self.imagePickerVc didFinishPickingAndEditingVideo:nil outputPath:nil error:_errorMsg];
        }
        if (self.imagePickerVc.didFinishPickingAndEditingVideoHandle) {
            self.imagePickerVc.didFinishPickingAndEditingVideoHandle(nil, nil, _errorMsg);
        }
    }
}

#pragma mark - private method

- (CMTime)getCropStartTime {
    NSTimeInterval second = [self getCropVideoStartSecond];
    if (second > self.model.asset.duration) {
        second = roundf(self.model.asset.duration);
    }
    return CMTimeMakeWithSeconds(second, _playerLayer.player.currentTime.timescale);
}

- (CMTimeRange)getCropVideoTimeRange {
    NSTimeInterval startSecond = [self getCropVideoStartSecond];
    CMTime start = CMTimeMakeWithSeconds(startSecond, _playerLayer.player.currentTime.timescale);
    NSTimeInterval second = [self getCropVideoDuration];
    CMTime duration = CMTimeMakeWithSeconds(second, _playerLayer.player.currentTime.timescale);
    return CMTimeRangeMake(start, duration);
}

- (NSTimeInterval)getCropVideoDuration {
    CGFloat rectW = self.videoEditView.cropRect.size.width;
    CGFloat contentW = self.videoEditView.allImgWidth;
    CGFloat second = rectW / contentW * roundf(self.model.asset.duration);
    return roundf(second);
}

- (NSTimeInterval)getCropVideoStartSecond {
    CGFloat offsetX = self.collectionView.contentOffset.x;
    CGFloat contentW = self.videoEditView.allImgWidth;
    CGFloat cropRectX = self.videoEditView.cropRect.origin.x - VideoEditLeftMargin - PanImageWidth;
    NSTimeInterval second = (offsetX + cropRectX) / contentW * roundf(self.model.asset.duration);
    if (second < 0) second = 0;
    return roundf(second);
}

- (CMTime)getTimeOfSeek {
    NSTimeInterval second = [self getCropVideoStartSecond];
    if (second > self.model.asset.duration) {
        second = roundf(self.model.asset.duration);
    }
    return CMTimeMakeWithSeconds(second, _playerLayer.player.currentTime.timescale);
}

- (void)starTimer {
    [self stopTimer];
    NSTimeInterval timeInterval = [self getCropVideoDuration];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(playCropVideo) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)stopTimer {
    if (self.timer) {
        [self.videoEditView resetIndicatorLine];
        [_player pause];
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)playCropVideo {
    [_player seekToTime:[self getCropStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [_player play];
    [self.videoEditView indicatorLineAnimateWithDuration:[self getCropVideoDuration] cropRect:self.videoEditView.cropRect];
}

#pragma mark - Notification Method

- (void)pausePlayer {
    [_player pause];
    [_playButton setImage:[UIImage tz_imageNamedFromMyBundle:@"MMVideoPreviewPlay"] forState:UIControlStateNormal];
}

#pragma mark - lazy
- (UIView *)iCloudErrorView{
    if (!_iCloudErrorView) {
        _iCloudErrorView = [[UIView alloc] initWithFrame:CGRectMake(0, [TZCommonTools tz_statusBarHeight] + 44 + 10, self.view.tz_width, 28)];
        UIImageView *icloud = [[UIImageView alloc] init];
        icloud.image = [UIImage tz_imageNamedFromMyBundle:@"iCloudError"];
        icloud.frame = CGRectMake(20, 0, 28, 28);
        [_iCloudErrorView addSubview:icloud];
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(53, 0, self.view.tz_width - 63, 28);
        label.font = [UIFont systemFontOfSize:10];
        label.textColor = [UIColor whiteColor];
        label.text = [NSBundle tz_localizedStringForKey:@"iCloud sync failed"];
        [_iCloudErrorView addSubview:label];
        [self.view addSubview:_iCloudErrorView];
        _iCloudErrorView.hidden = YES;
    }
    return _iCloudErrorView;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
    NSLog(@"%s",__func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma clang diagnostic pop

@end


@implementation TZVideoEditView {
    UILabel *_dragingLabel;
    CGFloat _itemWidth;
    CGFloat _beginOffsetX;
    CGFloat _endOffsetX;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self =  [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews {
    _indicatorLine = UIView.new;
    _indicatorLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    [self addSubview:_indicatorLine];
    
    _beginImgView = UIImageView.new;
    _beginImgView.image = [UIImage imageNamed:@"leftVideoEdit"];
    _beginImgView.userInteractionEnabled = YES;
    _beginImgView.tag = 0;
    UIPanGestureRecognizer *beginPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [_beginImgView addGestureRecognizer:beginPanGesture];
    [self addSubview:_beginImgView];
    
    _endImgView = UIImageView.new;
    _endImgView.image = [UIImage imageNamed:@"rightVideoEdit"];
    _endImgView.userInteractionEnabled = YES;
    _endImgView.tag = 1;
    UIPanGestureRecognizer *endPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [_endImgView addGestureRecognizer:endPanGesture];
    [self addSubview:_endImgView];
}

- (void)layoutSubviews {
    _beginImgView.frame = CGRectMake(VideoEditLeftMargin, 0, PanImageWidth, self.tz_height);
    _indicatorLine.frame = CGRectMake(_beginImgView.tz_right - 2, 2, 2, self.tz_height - 4);
    _endImgView.frame = CGRectMake(self.tz_width - PanImageWidth - VideoEditLeftMargin, 0, PanImageWidth, self.tz_height);
    
    self.cropRect =  CGRectMake(VideoEditLeftMargin + PanImageWidth, 0, self.tz_width - VideoEditLeftMargin * 2 - PanImageWidth * 2, self.tz_height);
}

- (void)setAllImgWidth:(CGFloat)allImgWidth {
    _allImgWidth = allImgWidth;
    if ((NSInteger)roundf(self.videoDuration) <= 0) {
        self.minCropRectWidth = allImgWidth;
        return;
    }
    
    CGFloat scale = MinCropVideoDuration / self.videoDuration;
    self.minCropRectWidth = scale * allImgWidth;
}

- (void)setCropRect:(CGRect)cropRect {
    _cropRect = cropRect;
    self.beginImgView.tz_left = cropRect.origin.x - PanImageWidth;
    self.indicatorLine.tz_left = cropRect.origin.x - self.indicatorLine.tz_width;
    self.endImgView.tz_left = CGRectGetMaxX(cropRect);

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    
    CGPoint topPoints[] = {
        CGPointMake(self.cropRect.origin.x, 0),
        CGPointMake(CGRectGetMaxX(self.cropRect), 0)
    };
    CGPoint bottomPoints[] = {
        CGPointMake(self.cropRect.origin.x, self.tz_height),
        CGPointMake(CGRectGetMaxX(self.cropRect), self.tz_height)
    };

    CGContextAddLines(context, topPoints, 2);
    CGContextAddLines(context, bottomPoints, 2);
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 4.0);
    CGContextDrawPath(context, kCGPathStroke);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect beginImgViewFrame = self.beginImgView.frame;
    beginImgViewFrame.origin.x -= PanImageWidth;
    beginImgViewFrame.size.width += PanImageWidth * 2;
    if (CGRectContainsPoint(beginImgViewFrame, point)) return self.beginImgView;
    
    CGRect endImgViewFrame = self.endImgView.frame;
    endImgViewFrame.origin.x -= PanImageWidth;
    endImgViewFrame.size.width += PanImageWidth * 2;
    if (CGRectContainsPoint(endImgViewFrame, point)) return self.endImgView;
    
    return nil;
}

#pragma mark - private

- (void)indicatorLineAnimateWithDuration:(NSTimeInterval)duration cropRect:(CGRect)cropRect {
    [self resetIndicatorLine];
    [UIView animateWithDuration:duration delay:.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.indicatorLine.tz_left = CGRectGetMaxX(cropRect);
    } completion:nil];
}

- (void)resetIndicatorLine {
    [self.indicatorLine.layer removeAllAnimations];
    self.indicatorLine.tz_left = CGRectGetMinX(self.cropRect) - self.indicatorLine.tz_width;
}

- (void)panGestureAction:(UIGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self];
    CGRect rect = self.cropRect;
    CGFloat minCropRectLeft = VideoEditLeftMargin + PanImageWidth;

    switch (gesture.view.tag) {
        case 0: { // 左边拖拽
            CGFloat maxX = self.endImgView.tz_left - self.minCropRectWidth;
            point.x = MAX(minCropRectLeft, MIN(point.x, maxX));
            point.y = 0;
            
            rect.size.width = CGRectGetMaxX(rect) - point.x;
            rect.origin.x = point.x;
        } break;
        case 1: { // 右边拖拽
            minCropRectLeft = CGRectGetMaxX(self.beginImgView.frame) + self.minCropRectWidth;
            CGFloat  maxX = self.tz_width - VideoEditLeftMargin - PanImageWidth;

            point.x = MAX(minCropRectLeft, MIN(point.x, maxX));
            point.y = 0;

            rect.size.width = (point.x - rect.origin.x);
        } break;
        default:break;
    }
    
    self.cropRect = rect;
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(editViewCropRectBeginChange)]) {
                [self.delegate editViewCropRectBeginChange];
            }
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(editViewCropRectEndChange)]) {
                [self.delegate editViewCropRectEndChange];
            }
        } break;
        default: break;
    }
}

@end



@implementation TZVideoPictureCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews {
    _imgView = [[UIImageView alloc] initWithFrame:self.bounds];
    _imgView.contentMode = UIViewContentModeScaleAspectFill;
    _imgView.clipsToBounds = YES;
    [self.contentView addSubview:_imgView];
}

@end
