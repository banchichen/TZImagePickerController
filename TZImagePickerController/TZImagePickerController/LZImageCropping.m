//
//  LZImageCropping.m
//  CroppingImage
//
//  Created by 刘志雄 on 2017/12/25.
//  Copyright © 2017年 刘志雄. All rights reserved.
//

#import "LZImageCropping.h"
#import "sys/utsname.h"
@interface LZImageCropping ()<UIScrollViewDelegate>
{
    CGFloat _selfHeight;
    CGFloat _selfWidth;
    
    CGRect _cropFrame;
}

@property(nonatomic,strong)UIScrollView *scrollView;
@property(nonatomic,strong)UIImageView *imageView;
@property(nonatomic,strong)UIImageView *cropImageView;
@property(nonatomic,strong)UIView *navView;
@property(nonatomic,strong)UILabel *bottomLabel;
@property(nonatomic,strong)UIButton *cancleButton;
@property(nonatomic,strong)UIButton *sureButton;
@property(nonatomic,strong)UIView *overLayView;
@property(nonatomic,strong)UIView *bottomBgView;
@property(nonatomic,strong)UIView *topLine;

@end
#define IOS11 [[UIDevice currentDevice].systemVersion floatValue] >= 11.0
@implementation LZImageCropping
//000
//3
//2
//--
-(BOOL)prefersStatusBarHidden{
    return YES;
}
//1
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self setDefaultData];
    [self createUI];
    self.titleLabel.text = @"图片裁剪";
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //自动缩放填满裁剪区域
    CGFloat scale;
    if (_cropSize.width/_cropSize.height > _image.size.width/_image.size.height) {
        scale = _cropSize.width/_imageView.frame.size.width;
        [self.scrollView setZoomScale:scale];
        [self.scrollView setZoomScale:scale animated:YES];
    }else{
        scale = _cropSize.height/_imageView.frame.size.height;
        [self.scrollView setZoomScale:scale animated:YES];
    }
    self.scrollView.userInteractionEnabled = YES;
    [self.scrollView setMinimumZoomScale:scale];
}

-(void)setDefaultData{
    _selfWidth = self.view.frame.size.width;
    _selfHeight = self.view.frame.size.height;
}

-(void)createUI{
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.imageView];
    [self.view addSubview:self.overLayView];
    [self.view addSubview:self.navView];
    [self.navView addSubview:self.titleLabel];
    [self.view addSubview:self.topLine];
//    [self.view addSubview:self.bottomLabel];
    [self.view addSubview:self.cancleButton];
    [self.view addSubview:self.sureButton];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];

    if (!_image) {
        return;
    }
    BOOL isStatusBarHidden = [UIApplication sharedApplication].isStatusBarHidden;
    CGFloat height = [UIFont systemFontOfSize:15].pointSize;
    CGFloat width = 40;
    if ([self lz_isIPhoneX]) {
        [self.navView setFrame:CGRectMake(0, 0, _selfWidth, 64 + 24)];
        self.titleLabel.frame = CGRectMake(0, 0, 200, 20);
        self.titleLabel.center = CGPointMake(self.navView.frame.size.width / 2.0, self.navView.center.y + 20);
        self.topLine.frame = CGRectMake(0, 64 + 24, self.navView.frame.size.width, 0.5);
        [self.cancleButton setFrame:CGRectMake(15, (64 + 24 - height) / 2.0,width, 20)];
        self.cancleButton.center = CGPointMake(self.cancleButton.center.x, self.titleLabel.center.y);
        [self.bottomLabel setFrame:CGRectMake(0, _selfHeight - 44 - 34.0,_selfWidth, 44 + 34.0)];
        [self.sureButton setFrame:CGRectMake(_selfWidth - 15- width, _selfHeight-15-height - 34.0, width, height + 34.0)];
        self.sureButton.center = CGPointMake(self.sureButton.center.x, self.cancleButton.center.y);
    } else {
        [self.navView setFrame:CGRectMake(0, 0, _selfWidth, isStatusBarHidden ? 44 : 64)];
        self.titleLabel.frame = CGRectMake(0, 0, 200, 20);
        self.titleLabel.center = CGPointMake(self.navView.frame.size.width / 2.0, (self.navView.frame.size.height - (isStatusBarHidden ? 0 : self.titleLabel.frame.size.height)) / 2.0 + (isStatusBarHidden ? 0 : 20));
        self.topLine.frame = CGRectMake(0, self.navView.frame.size.height, self.navView.frame.size.width, 0.5);
        [self.cancleButton setFrame:CGRectMake(15, (self.navView.frame.size.height - height) / 2.0,width, 20)];
        self.cancleButton.center = CGPointMake(self.cancleButton.center.x, self.titleLabel.center.y);
        [self.bottomLabel setFrame:CGRectMake(0, _selfHeight - 44,_selfWidth, 44)];
        [self.sureButton setFrame:CGRectMake(_selfWidth - 15- width, _selfHeight - 15 - height, width, height)];
        self.sureButton.center = CGPointMake(self.sureButton.center.x, self.cancleButton.center.y);
    }

    if (_mainColor && _sureButton) {
        [_sureButton setTitleColor:_mainColor forState:0];
    }

    [self.overLayView setFrame:self.view.frame];
    [self.scrollView setFrame:CGRectMake(0, 0, _selfWidth, _selfHeight)];
    [self.scrollView setContentSize:CGSizeMake(_selfWidth, _selfHeight)];

    //初始位置
    if (_cropSize.width/_cropSize.height > _image.size.width/_image.size.height) {
        [_imageView setFrame:CGRectMake((_cropSize.width - _cropSize.height*_image.size.width/_image.size.height)/2 + (self.view.frame.size.width-_cropSize.width)/2,(_selfHeight-_cropSize.height)/2, _image.size.width/_image.size.height*_cropSize.height, _cropSize.height)];
    }else{
        [_imageView setFrame:CGRectMake((_selfWidth - _cropSize.width)/2, (_cropSize.height-_cropSize.width*_image.size.height/_image.size.width)/2+(_selfHeight-_cropSize.height)/2, _cropSize.width, _cropSize.width*_image.size.height/_image.size.width)];
    }

    //绘制裁剪框
    if (self.isRound) {
        [self transparentCutRoundArea];
    }else{
        [self transparentCutSquareArea];
    }
}

#pragma mark -
//矩形裁剪区域
- (void)transparentCutSquareArea{
    //圆形透明区域
    UIBezierPath *alphaPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, _selfWidth, _selfHeight)];
    UIBezierPath *squarePath = [UIBezierPath bezierPathWithRect:_cropFrame];
    [alphaPath appendPath:squarePath];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = alphaPath.CGPath;
    shapeLayer.fillRule = kCAFillRuleEvenOdd;
    self.overLayView.layer.mask = shapeLayer;
    
    //裁剪框
    UIBezierPath *cropPath = [UIBezierPath bezierPathWithRect:CGRectMake(_cropFrame.origin.x-1, _cropFrame.origin.y-1, _cropFrame.size.width+2, _cropFrame.size.height+2)];
    CAShapeLayer *cropLayer = [CAShapeLayer layer];
    cropLayer.path = cropPath.CGPath;
    cropLayer.fillColor = [UIColor whiteColor].CGColor;
    cropLayer.strokeColor = [UIColor whiteColor].CGColor;
//    [self.overLayView.layer addSublayer:cropLayer];
}

//圆形裁剪区域
-(void)transparentCutRoundArea{
    CGFloat arcX = _cropFrame.origin.x + _cropFrame.size.width/2;
    CGFloat arcY = _cropFrame.origin.y + _cropFrame.size.height/2;
    CGFloat arcRadius;
    if (_cropSize.height > _cropSize.width) {
        arcRadius = _cropSize.width/2;
    }else{
        arcRadius  = _cropSize.height/2;
    }
    
    //圆形透明区域
    UIBezierPath *alphaPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, _selfWidth, _selfHeight)];
    UIBezierPath *arcPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(arcX, arcY) radius:arcRadius startAngle:0 endAngle:2*M_PI clockwise:NO];
    [alphaPath appendPath:arcPath];
    CAShapeLayer  *layer = [CAShapeLayer layer];
    layer.path = alphaPath.CGPath;
    layer.fillRule = kCAFillRuleEvenOdd;
    self.overLayView.layer.mask = layer;
    
    //裁剪框
    UIBezierPath *cropPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(arcX, arcY) radius:arcRadius+1 startAngle:0 endAngle:2*M_PI clockwise:NO];
    CAShapeLayer *cropLayer = [CAShapeLayer layer];
    cropLayer.path = cropPath.CGPath;
    cropLayer.strokeColor = [UIColor whiteColor].CGColor;
    cropLayer.fillColor = [UIColor whiteColor].CGColor;
    [self.overLayView.layer addSublayer:cropLayer];
}

-(UIImage *)getSubImage{
    //图片大小和当前imageView的缩放比例
    CGFloat scaleRatio = self.image.size.width/_imageView.frame.size.width ;
    //scrollView的缩放比例，即是ImageView的缩放比例
    CGFloat scrollScale = self.scrollView.zoomScale;
    //裁剪框的 左上、右上和左下三个点在初始ImageView上的坐标位置（注意：转换后的坐标为原始ImageView的坐标计算的，而非缩放后的）
    CGPoint leftTopPoint =  [self.view  convertPoint:_cropFrame.origin toView:_imageView];
    CGPoint rightTopPoint = [self.view convertPoint:CGPointMake(_cropFrame.origin.x + _cropSize.width, _cropFrame.origin.y) toView:_imageView];
    CGPoint leftBottomPoint =[self.view convertPoint:CGPointMake(_cropFrame.origin.x, _cropFrame.origin.y+_cropSize.height) toView:_imageView];
    
    //计算三个点在缩放后imageView上的坐标
    leftTopPoint = CGPointMake(leftTopPoint.x * scrollScale, leftTopPoint.y*scrollScale);
    rightTopPoint = CGPointMake(rightTopPoint.x * scrollScale, rightTopPoint.y*scrollScale);
    leftBottomPoint = CGPointMake(leftBottomPoint.x * scrollScale, leftBottomPoint.y*scrollScale);
    
    //计算图片的宽高
    CGFloat width = (rightTopPoint.x - leftTopPoint.x )* scaleRatio;
    CGFloat height = (leftBottomPoint.y - leftTopPoint.y) *scaleRatio;
    
    //计算裁剪区域在原始图片上的位置
    CGRect myImageRect = CGRectMake(leftTopPoint.x * scaleRatio, leftTopPoint.y*scaleRatio, width, height);
    
    //裁剪图片
    CGImageRef imageRef = self.image.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, myImageRect);
    CGSize size;
    size.width = myImageRect.size.width;
    size.height = myImageRect.size.height;
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, myImageRect, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    CGImageRelease(subImageRef);
    UIGraphicsEndImageContext();
    
    //是否需要圆形图片
    if (self.isRound) {
        //将图片裁剪成圆形
        smallImage = [self clipCircularImage:smallImage];
    }
    return smallImage;
}

//将图片裁剪成圆形
-(UIImage *)clipCircularImage:(UIImage *)image{
    CGFloat arcCenterX = image.size.width/ 2;
    CGFloat arcCenterY = image.size.height / 2;
    
    UIGraphicsBeginImageContext(image.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextBeginPath(context);
    CGContextAddArc(context, arcCenterX, arcCenterY, image.size.width/2, 0.0, 2*M_PI, NO);
    CGContextClip(context);
    CGRect myRect = CGRectMake(0 , 0, image.size.width ,  image.size.height);
    [image drawInRect:myRect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return  newImage;
}

#pragma mark - UIScrollViewDelegate(Zoom)
// 返回要在ScrollView中缩放的控件
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    
    //等比例放大图片以后，让放大后的ImageView保持在ScrollView的中央
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?(scrollView.bounds.size.width - scrollView.contentSize.width) *0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) *0.5 : 0.0;
    _imageView.center =CGPointMake(scrollView.contentSize.width *0.5 + offsetX,scrollView.contentSize.height *0.5 + offsetY);
    
    //设置scrollView的contentSize，最小为self.view.frame
    if (scrollView.contentSize.width >= _selfWidth  && scrollView.contentSize.height <= _selfHeight) {
        scrollView.contentSize = CGSizeMake(scrollView.contentSize.width, _selfHeight);
    }else if(scrollView.contentSize.width <= _selfWidth && scrollView.contentSize.height <= _selfHeight){
        scrollView.contentSize = CGSizeMake(_selfWidth, _selfHeight);
    }else if(scrollView.contentSize.width <= _selfWidth && scrollView.contentSize.height >= _selfHeight){
        scrollView.contentSize = CGSizeMake(_selfWidth, scrollView.contentSize.height);
    }else{
    }
    
    //设置scrollView的contentInset
    CGFloat imageWidth = _imageView.frame.size.width;
    CGFloat imageHeight = _imageView.frame.size.height;
    CGFloat cropWidth = _cropSize.width;
    CGFloat cropHeight = _cropSize.height;
    
    CGFloat leftRightInset = 0.0,topBottomInset = 0.0;
    
    //imageview的大小和裁剪框大小的三种情况，保证imageview最多能滑动到裁剪框的边缘
    if (imageWidth<= cropWidth) {
        leftRightInset = 0;
    }else if (imageWidth >= cropWidth && imageWidth <= _selfWidth){
        leftRightInset =(imageWidth - cropWidth)*0.5;
    }else{
        leftRightInset = (_selfWidth-_cropSize.width)*0.5;
    }
    
    if (imageHeight <= cropHeight) {
        topBottomInset = 0;
    }else if (imageHeight >= cropHeight && imageHeight <= _selfHeight){
        topBottomInset = (imageHeight - cropHeight)*0.5;
    }else {
        topBottomInset = (_selfHeight-_cropSize.height)*0.5;
    }
    [self.scrollView setContentInset:UIEdgeInsetsMake(topBottomInset, leftRightInset, topBottomInset, leftRightInset)];
}

#pragma mark - Click Event
-(void)cancleButtonClick{
    if ([self.delegate respondsToSelector:@selector(lzImageCroppingDidCancle:)]) {
        [self.delegate lzImageCroppingDidCancle:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)sureButtonClick{
    if ([self.delegate respondsToSelector:@selector(lzImageCropping:didCropImage:)]) {
        [self.delegate lzImageCropping:self didCropImage:[self getSubImage]];
    } else {
        if (self.didFinishPickingImage) {
            self.didFinishPickingImage([self getSubImage]);
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Public
-(void)setCropSize:(CGSize)cropSize{
    _cropSize = cropSize;
    
    //设置裁剪框区域
    _cropFrame = CGRectMake((self.view.frame.size.width-cropSize.width)/2,(self.view.frame.size.height-cropSize.height)/2,cropSize.width, cropSize.height);
    
    [self.view setNeedsLayout];
}

-(void)setImage:(UIImage *)image{
    [_imageView setImage:image];
    _image = image;
    _imageView.backgroundColor = [UIColor redColor];
    [self.view setNeedsLayout];
    
    //初始化ImageView的Frame
    if (_cropSize.width/_cropSize.height > _image.size.width/_image.size.height) {
        [_imageView setFrame:CGRectMake((_cropSize.width - _cropSize.height*_image.size.width/_image.size.height)/2 + (self.view.frame.size.width-_cropSize.width)/2,0, _image.size.width/_image.size.height*_cropSize.height, _cropSize.height)];
    }else{
        [_imageView setFrame:CGRectMake(0, (_cropSize.height-_cropSize.width*_image.size.height/_image.size.width)/2+(_selfHeight-_cropSize.height)/2, _cropSize.width, _cropSize.width*_image.size.height/_image.size.width)];
    }
}

#pragma mark - private
-(UIScrollView *)scrollView{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc]init];
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        //设置缩放的最大比例和最小比例
        _scrollView.maximumZoomScale = 10;
        _scrollView.minimumZoomScale = 1;
        //初始缩放比例为1
        [_scrollView setZoomScale:1 animated:YES];
        [_scrollView setFrame:CGRectMake(0, 0, _selfWidth, _selfHeight)];
        if(IOS11){
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _scrollView;
}

-(UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc]init];
        [_imageView setUserInteractionEnabled:YES];
        [_imageView setContentMode:UIViewContentModeScaleAspectFill];
    }
    return _imageView;
}

- (UIView*)navView {
    if (!_navView) {
        _navView = [[UIView alloc]init];
        _navView.backgroundColor = [UIColor whiteColor];
    }
    return _navView;
}
- (UILabel*)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.font = [UIFont systemFontOfSize:17];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}
-(UIButton *)cancleButton{
    if (!_cancleButton) {
        _cancleButton = [[UIButton alloc]init];
        [_cancleButton setImage:[UIImage imageNamed:@"topbar_back"] forState:UIControlStateNormal];
        [_cancleButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_cancleButton addTarget:self action:@selector(cancleButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancleButton;
}

-(UIButton *)sureButton{
    if (!_sureButton) {
        _sureButton = [[UIButton alloc]init];
        [_sureButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [_sureButton setTitle:@"完成" forState:UIControlStateNormal];
        [_sureButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_sureButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [_sureButton setTitleColor:[UIColor colorWithRed:89 / 256.0 green:182 / 256.0 blue:215 / 256.0 alpha:1] forState:UIControlStateNormal];
        [_sureButton addTarget:self action:@selector(sureButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sureButton;
}

-(UILabel *)bottomLabel{
    if (!_bottomLabel) {
        _bottomLabel = [[UILabel alloc]init];
        _bottomLabel.backgroundColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:0.7];
    }
    return _bottomLabel;
}

//用于展示裁剪框的视图
-(UIView *)overLayView{
    if (!_overLayView) {
        _overLayView = [[UIView alloc]init];
        _overLayView.userInteractionEnabled = NO;
//        _overLayView.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.8];
        _overLayView.backgroundColor = [UIColor colorWithWhite: 1 alpha:0.7];
    }
    return _overLayView;
}

- (UIView *)topLine {
    if (!_topLine) {
        _topLine = [[UIView alloc] init];
        _topLine.backgroundColor = UIColor.grayColor;
    }
    return _topLine;
}

- (BOOL)lz_isIPhoneX {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if ([platform isEqualToString:@"i386"] || [platform isEqualToString:@"x86_64"]) {
        return [UIScreen mainScreen].bounds.size.height == 812;
    }
    BOOL isIPhoneX = [platform isEqualToString:@"iPhone10,3"] || [platform isEqualToString:@"iPhone10,6"];
    return isIPhoneX;
}

- (void)setMainColor:(UIColor *)mainColor {
    _mainColor = mainColor;
    if (_mainColor && _sureButton) {
        [_sureButton setTitleColor:_mainColor forState:0];
    }
}

@end
