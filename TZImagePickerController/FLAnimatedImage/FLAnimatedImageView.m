//
//  FLAnimatedImageView.h
//  Flipboard
//
//  Created by Raphael Schaad on 7/8/13.
//  Copyright (c) Flipboard. All rights reserved.
//


#import "FLAnimatedImageView.h"
#import "FLAnimatedImage.h"
#import <QuartzCore/QuartzCore.h>


#if defined(DEBUG) && DEBUG
@protocol FLAnimatedImageViewDebugDelegate <NSObject>
@optional
- (void)debug_animatedImageView:(FLAnimatedImageView *)animatedImageView waitingForFrame:(NSUInteger)index duration:(NSTimeInterval)duration;
@end
#endif


@interface FLAnimatedImageView ()

// Override of public `readonly` properties as private `readwrite`
@property (nonatomic, strong, readwrite) UIImage *currentFrame;
@property (nonatomic, assign, readwrite) NSUInteger currentFrameIndex;

@property (nonatomic, assign) NSUInteger loopCountdown;
@property (nonatomic, assign) NSTimeInterval accumulator;
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) BOOL shouldAnimate; // Before checking this value, call `-updateShouldAnimate` whenever the animated image or visibility (window, superview, hidden, alpha) has changed.
@property (nonatomic, assign) BOOL needsDisplayWhenImageBecomesAvailable;

#if defined(DEBUG) && DEBUG
@property (nonatomic, weak) id<FLAnimatedImageViewDebugDelegate> debug_delegate;
#endif

@end


@implementation FLAnimatedImageView
@synthesize runLoopMode = _runLoopMode;

#pragma mark - Initializers

// -initWithImage: isn't documented as a designated initializer of UIImageView, but it actually seems to be.
// Using -initWithImage: doesn't call any of the other designated initializers.
- (instancetype)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self) {
        [self commonInit];
    }
    return self;
}

// -initWithImage:highlightedImage: also isn't documented as a designated initializer of UIImageView, but it doesn't call any other designated initializers.
- (instancetype)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    self = [super initWithImage:image highlightedImage:highlightedImage];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.runLoopMode = [[self class] defaultRunLoopMode];
    
    if (@available(iOS 11.0, *)) {
        self.accessibilityIgnoresInvertColors = YES;
    }
}


#pragma mark - Accessors
#pragma mark Public

- (void)setAnimatedImage:(FLAnimatedImage *)animatedImage
{
    if (![_animatedImage isEqual:animatedImage]) {
        if (animatedImage) {
            if (super.image) {
                // UIImageView's `setImage:` will internally call its layer's `setContentsTransform:` based on the `image.imageOrientation`.
                // The `contentsTransform` will affect layer rendering rotation because the CGImage's bitmap buffer does not actually take rotation.
                // However, when calling `setImage:nil`, this `contentsTransform` will not be reset to identity.
                // Further animation frame will be rendered as rotated. So we must set it to the poster image to clear the previous state.
                // See more here: https://github.com/Flipboard/FLAnimatedImage/issues/100
                super.image = animatedImage.posterImage;
                // Clear out the image.
                super.image = nil;
            }
            // Ensure disabled highlighting; it's not supported (see `-setHighlighted:`).
            super.highlighted = NO;
            // UIImageView seems to bypass some accessors when calculating its intrinsic content size, so this ensures its intrinsic content size comes from the animated image.
            [self invalidateIntrinsicContentSize];
        } else {
            // Stop animating before the animated image gets cleared out.
            [self stopAnimating];
        }
        
        _animatedImage = animatedImage;
        
        self.currentFrame = animatedImage.posterImage;
        self.currentFrameIndex = 0;
        if (animatedImage.loopCount > 0) {
            self.loopCountdown = animatedImage.loopCount;
        } else {
            self.loopCountdown = NSUIntegerMax;
        }
        self.accumulator = 0.0;
        
        // Start animating after the new animated image has been set.
        [self updateShouldAnimate];
        if (self.shouldAnimate) {
            [self startAnimating];
        }
        
        [self.layer setNeedsDisplay];
    }
}


#pragma mark - Life Cycle

- (void)dealloc
{
    // Removes the display link from all run loop modes.
    [_displayLink invalidate];
}


#pragma mark - UIView Method Overrides
#pragma mark Observing View-Related Changes

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}


- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)setAlpha:(CGFloat)alpha
{
    [super setAlpha:alpha];

    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];

    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}


#pragma mark Auto Layout

- (CGSize)intrinsicContentSize
{
    // Default to let UIImageView handle the sizing of its image, and anything else it might consider.
    CGSize intrinsicContentSize = [super intrinsicContentSize];
    
    // If we have have an animated image, use its image size.
    // UIImageView's intrinsic content size seems to be the size of its image. The obvious approach, simply calling `-invalidateIntrinsicContentSize` when setting an animated image, results in UIImageView steadfastly returning `{UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric}` for its intrinsicContentSize.
    // (Perhaps UIImageView bypasses its `-image` getter in its implementation of `-intrinsicContentSize`, as `-image` is not called after calling `-invalidateIntrinsicContentSize`.)
    if (self.animatedImage) {
        intrinsicContentSize = self.image.size;
    }
    
    return intrinsicContentSize;
}


#pragma mark - UIImageView Method Overrides
#pragma mark Image Data

- (UIImage *)image
{
    UIImage *image = nil;
    if (self.animatedImage) {
        // Initially set to the poster image.
        image = self.currentFrame;
    } else {
        image = super.image;
    }
    return image;
}


- (void)setImage:(UIImage *)image
{
    if (image) {
        // Clear out the animated image and implicitly pause animation playback.
        self.animatedImage = nil;
    }
    
    super.image = image;
}


#pragma mark Animating Images

- (NSTimeInterval)frameDelayGreatestCommonDivisor
{
    // Presision is set to half of the `kFLAnimatedImageDelayTimeIntervalMinimum` in order to minimize frame dropping.
    const NSTimeInterval kGreatestCommonDivisorPrecision = 2.0 / kFLAnimatedImageDelayTimeIntervalMinimum;

    NSArray *const delays = self.animatedImage.delayTimesForIndexes.allValues;

    // Scales the frame delays by `kGreatestCommonDivisorPrecision`
    // then converts it to an UInteger for in order to calculate the GCD.
    NSUInteger scaledGCD = lrint([delays.firstObject floatValue] * kGreatestCommonDivisorPrecision);
    for (NSNumber *value in delays) {
        scaledGCD = gcd(lrint([value floatValue] * kGreatestCommonDivisorPrecision), scaledGCD);
    }

    // Reverse to scale to get the value back into seconds.
    return (double)scaledGCD / kGreatestCommonDivisorPrecision;
}


static NSUInteger gcd(NSUInteger a, NSUInteger b)
{
    // http://en.wikipedia.org/wiki/Greatest_common_divisor
    if (a < b) {
        return gcd(b, a);
    } else if (a == b) {
        return b;
    }

    while (true) {
        const NSUInteger remainder = a % b;
        if (remainder == 0) {
            return b;
        }
        a = b;
        b = remainder;
    }
}


- (void)startAnimating
{
    if (self.animatedImage) {
        // Lazily create the display link.
        if (!self.displayLink) {
            // It is important to note the use of a weak proxy here to avoid a retain cycle. `-displayLinkWithTarget:selector:`
            // will retain its target until it is invalidated. We use a weak proxy so that the image view will get deallocated
            // independent of the display link's lifetime. Upon image view deallocation, we invalidate the display
            // link which will lead to the deallocation of both the display link and the weak proxy.
            FLWeakProxy *weakProxy = [FLWeakProxy weakProxyForObject:self];
            self.displayLink = [CADisplayLink displayLinkWithTarget:weakProxy selector:@selector(displayDidRefresh:)];
            
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.runLoopMode];
        }

        if (@available(iOS 10, *)) {
            // Adjusting preferredFramesPerSecond allows us to skip unnecessary calls to displayDidRefresh: when showing GIFs
            // that don't animate quickly. Use ceil to err on the side of too many FPS so we don't miss a frame transition moment.
            self.displayLink.preferredFramesPerSecond = ceil(1.0 / [self frameDelayGreatestCommonDivisor]);
        } else {
            const NSTimeInterval kDisplayRefreshRate = 60.0; // 60Hz
            self.displayLink.frameInterval = MAX([self frameDelayGreatestCommonDivisor] * kDisplayRefreshRate, 1);
        }
        self.displayLink.paused = NO;
    } else {
        [super startAnimating];
    }
}

- (void)setRunLoopMode:(NSRunLoopMode)runLoopMode
{
    if (![@[NSDefaultRunLoopMode, NSRunLoopCommonModes] containsObject:runLoopMode]) {
        NSAssert(NO, @"Invalid run loop mode: %@", runLoopMode);
        _runLoopMode = [[self class] defaultRunLoopMode];
    } else {
        _runLoopMode = runLoopMode;
    }
}

- (void)stopAnimating
{
    if (self.animatedImage) {
        self.displayLink.paused = YES;
    } else {
        [super stopAnimating];
    }
}


- (BOOL)isAnimating
{
    BOOL isAnimating = NO;
    if (self.animatedImage) {
        isAnimating = self.displayLink && !self.displayLink.isPaused;
    } else {
        isAnimating = [super isAnimating];
    }
    return isAnimating;
}


#pragma mark Highlighted Image Unsupport

- (void)setHighlighted:(BOOL)highlighted
{
    // Highlighted image is unsupported for animated images, but implementing it breaks the image view when embedded in a UICollectionViewCell.
    if (!self.animatedImage) {
        [super setHighlighted:highlighted];
    }
}


#pragma mark - Private Methods
#pragma mark Animation

// Don't repeatedly check our window & superview in `-displayDidRefresh:` for performance reasons.
// Just update our cached value whenever the animated image or visibility (window, superview, hidden, alpha) is changed.
- (void)updateShouldAnimate
{
    const BOOL isVisible = self.window && self.superview && ![self isHidden] && self.alpha > 0.0;
    self.shouldAnimate = self.animatedImage && isVisible;
}


- (void)displayDidRefresh:(CADisplayLink *)displayLink
{
    // If for some reason a wild call makes it through when we shouldn't be animating, bail.
    // Early return!
    if (!self.shouldAnimate) {
        FLLog(FLLogLevelWarn, @"Trying to animate image when we shouldn't: %@", self);
        return;
    }
    
    NSNumber *_Nullable const delayTimeNumber = [self.animatedImage.delayTimesForIndexes objectForKey:@(self.currentFrameIndex)];
    // If we don't have a frame delay (e.g. corrupt frame), don't update the view but skip the playhead to the next frame (in else-block).
    if (delayTimeNumber != nil) {
        const NSTimeInterval delayTime = [delayTimeNumber floatValue];
        // If we have a nil image (e.g. waiting for frame), don't update the view nor playhead.
        UIImage *_Nullable const image = [self.animatedImage imageLazilyCachedAtIndex:self.currentFrameIndex];
        if (image) {
            FLLog(FLLogLevelVerbose, @"Showing frame %lu for animated image: %@", (unsigned long)self.currentFrameIndex, self.animatedImage);
            self.currentFrame = image;
            if (self.needsDisplayWhenImageBecomesAvailable) {
                [self.layer setNeedsDisplay];
                self.needsDisplayWhenImageBecomesAvailable = NO;
            }
            
            if (@available(iOS 10, *)) {
                self.accumulator += displayLink.targetTimestamp - CACurrentMediaTime();
            } else {
                self.accumulator += displayLink.duration * (NSTimeInterval)displayLink.frameInterval;
            }
            
            // While-loop first inspired by & good Karma to: https://github.com/ondalabs/OLImageView/blob/master/OLImageView.m
            while (self.accumulator >= delayTime) {
                self.accumulator -= delayTime;
                self.currentFrameIndex++;
                if (self.currentFrameIndex >= self.animatedImage.frameCount) {
                    // If we've looped the number of times that this animated image describes, stop looping.
                    self.loopCountdown--;
                    if (self.loopCompletionBlock) {
                        self.loopCompletionBlock(self.loopCountdown);
                    }
                    
                    if (self.loopCountdown == 0) {
                        [self stopAnimating];
                        return;
                    }
                    self.currentFrameIndex = 0;
                }
                // Calling `-setNeedsDisplay` will just paint the current frame, not the new frame that we may have moved to.
                // Instead, set `needsDisplayWhenImageBecomesAvailable` to `YES` -- this will paint the new image once loaded.
                self.needsDisplayWhenImageBecomesAvailable = YES;
            }
        } else {
            FLLog(FLLogLevelDebug, @"Waiting for frame %lu for animated image: %@", (unsigned long)self.currentFrameIndex, self.animatedImage);
#if defined(DEBUG) && DEBUG
            if ([self.debug_delegate respondsToSelector:@selector(debug_animatedImageView:waitingForFrame:duration:)]) {
                if (@available(iOS 10, *)) {
                    [self.debug_delegate debug_animatedImageView:self waitingForFrame:self.currentFrameIndex duration:displayLink.targetTimestamp - CACurrentMediaTime()];
                } else {
                    [self.debug_delegate debug_animatedImageView:self waitingForFrame:self.currentFrameIndex duration:displayLink.duration * (NSTimeInterval)displayLink.frameInterval];
                }
            }
#endif
        }
    } else {
        self.currentFrameIndex++;
    }
}

+ (NSRunLoopMode)defaultRunLoopMode
{
    // Key off `activeProcessorCount` (as opposed to `processorCount`) since the system could shut down cores in certain situations.
    return [NSProcessInfo processInfo].activeProcessorCount > 1 ? NSRunLoopCommonModes : NSDefaultRunLoopMode;
}


#pragma mark - CALayerDelegate (Informal)
#pragma mark Providing the Layer's Content

- (void)displayLayer:(CALayer *)layer
{
    layer.contents = (__bridge id)self.image.CGImage;
}


@end
