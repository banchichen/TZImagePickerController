//
//  TZAuthLimitedFooterTipView.m
//  TZImagePickerController
//
//  Created by qiaoxy on 2021/8/24.
//

#import "TZAuthLimitedFooterTipView.h"
#import "TZImagePickerController.h"

@interface TZAuthLimitedFooterTipView()
@property (nonatomic,strong) UIImageView *tipImgView;
@property (nonatomic,strong) UILabel *tipLable;
@property (nonatomic,strong) UIImageView *detailImgView;
@end

@implementation TZAuthLimitedFooterTipView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews {
    [self addSubview:self.tipImgView];
    [self addSubview:self.tipLable];
    [self addSubview:self.detailImgView];
    CGFloat margin = 15;
    CGFloat tipImgViewWH = 20;
    CGFloat detailImgViewWH = 12;
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;

    self.tipImgView.frame = CGRectMake(margin, 0, tipImgViewWH, tipImgViewWH);
    self.detailImgView.frame = CGRectMake(screenW - margin - detailImgViewWH, 0, detailImgViewWH, detailImgViewWH);
    
    CGFloat tipLabelX = CGRectGetMaxX(self.tipImgView.frame) + 10;
    CGFloat tipLabelW = screenW - tipLabelX - detailImgViewWH - margin - 4;
    self.tipLable.frame = CGRectMake(tipLabelX, 0, tipLabelW, self.bounds.size.height);
    
    self.tipImgView.center = CGPointMake(self.tipImgView.center.x, self.tipLable.center.y);
    self.detailImgView.center = CGPointMake(self.detailImgView.center.x, self.tipLable.center.y);
}

#pragma mark - Getter

- (UIImageView *)tipImgView {
    if (!_tipImgView) {
        _tipImgView = [[UIImageView alloc] init];
        _tipImgView.contentMode = UIViewContentModeScaleAspectFit;
        _tipImgView.image = [UIImage tz_imageNamedFromMyBundle:@"tip"];
    }
    return _tipImgView;
}

- (UILabel *)tipLable {
    if (!_tipLable) {
        _tipLable = [[UILabel alloc] init];
        NSString *appName = [TZCommonTools tz_getAppName];
        _tipLable.text = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Allow %@ to access your all photos"], appName];
        _tipLable.numberOfLines = 0;
        _tipLable.font = [UIFont systemFontOfSize:14];
        _tipLable.textColor = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0];
    }
    return _tipLable;
}

- (UIImageView *)detailImgView {
    if (!_detailImgView) {
        _detailImgView = [[UIImageView alloc] init];
        _detailImgView.contentMode = UIViewContentModeScaleAspectFit;
        _detailImgView.image = [UIImage tz_imageNamedFromMyBundle:@"right_arrow"];
    }
    return _detailImgView;
}

@end
