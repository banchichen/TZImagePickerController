//
//  TZPhotoPickerController+Custom.m
//  yxqls
//
//  Created by mac17 on 2021/8/24.
//

#import "TZPhotoPickerController+Custom.h"
#import <Photos/PHImageManager.h>
#import <Photos/Photos.h>
#import "TZAssetCell.h"
#import <objc/runtime.h>

@implementation TZPhotoPickerController (Custom)

+ (void)load {
    [self swizzleSEL:NSSelectorFromString(@"initSubviews") withSEL:@selector(sw_initSubviews)];
}

+ (void)swizzleSEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL {
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSEL);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSEL);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSEL,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSEL,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)sw_initSubviews {
    [self sw_initSubviews];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TZImagePickerController *imgPicker = (TZImagePickerController *)self.navigationController;
        if (imgPicker.maxImagesCount == 1 || imgPicker.allowPickingVideo) {
            return;//只能选择一个或者能选视频,不启用多选
        }
        UIPanGestureRecognizer *ges = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(multiSelectAction:)];
        [self.view addGestureRecognizer:ges];
    });
}

//@property (nonatomic, strong) TZCollectionView *collectionView;UICollectionViewFlowLayout *layout
- (TZCollectionView *)collView {
    return [self valueForKey:@"collectionView"];
}
- (UICollectionViewFlowLayout *)collLayout {
    return [self valueForKey:@"layout"];
}

static CGFloat itemMargin = 5;//这个变量直接复制自原文件,如果原文件改了这个需要也改一下
- (void)multiSelectAction:(UIGestureRecognizer *)ges {
    static NSInteger beginIdx = -1;
    CGPoint lc = [ges locationInView:self.collView];
    NSInteger h = self.collLayout.itemSize.height + itemMargin;
    NSInteger w = self.collLayout.itemSize.width + itemMargin;
    NSInteger line = (NSInteger)lc.y / h;
    NSInteger column = (NSInteger)lc.x / w;
    NSInteger idx = line * self.columnNumber + column;
    if (beginIdx == -1) {
        beginIdx = idx;
    }
    [self selectIdx:beginIdx toIdx2:idx];
    if (self.collView.contentOffset.y + self.collView.bounds.size.height - lc.y < 40) {
        selectingTopEdge = NO;
        [self dpLink];
    } else if (lc.y - self.collView.contentOffset.y < 40) {
        selectingTopEdge = YES;
        [self dpLink];
    } else {
        [dpLink invalidate];
        dpLink = nil;
    }
    if (ges.state == UIGestureRecognizerStateEnded || ges.state == UIGestureRecognizerStateCancelled) {
        beginIdx = -1;
        isCancel = -1;
        previousEndIdx = -1;
        currEndIdx = -1;
        [dpLink invalidate];
        dpLink = nil;
    }
}

- (void)selectingEdge {
    CGPoint off = self.collView.contentOffset;
    off.y += selectingTopEdge ? -5 : 5;
    off.y = MAX(- itemMargin, off.y);
    off.y = MIN(self.collView.contentSize.height - self.collView.frame.size.height + itemMargin, off.y);
    self.collView.contentOffset = off;
}

- (CADisplayLink *)dpLink {
    if (!dpLink) {
        dpLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(selectingEdge)];
        [dpLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    return dpLink;
}

static CADisplayLink *dpLink;
static BOOL selectingTopEdge;
static NSInteger isCancel = -1;
static NSInteger previousEndIdx = -1;//选过的最大index
static NSInteger currEndIdx = -1;
- (void)selectIdx:(NSInteger)idx toIdx2:(NSInteger)idx2 {
    if (currEndIdx == idx2) {
        return;//手指在同一个cell上多次触发
    }
    currEndIdx = idx2;
    if (previousEndIdx != -1) {
        BOOL preBigger = previousEndIdx > idx2 && previousEndIdx > idx;
        BOOL preSmaller = previousEndIdx < idx2 && previousEndIdx < idx;
        if (preBigger || preSmaller) {//选则过程中往回滑动
            //是否反转了方向(例:本来向下滑选择,往回滑动越过了起点变成了向上滑选择)
            BOOL isReverse = (idx2 > idx && idx > previousEndIdx) || (idx2 < idx && idx < previousEndIdx);
            for (NSInteger i = previousEndIdx; (preBigger && i > MAX(idx, idx2)) || (preSmaller && i < MIN(idx, idx2)); preBigger ? i-- : i++) {
                NSIndexPath *idxp = [NSIndexPath indexPathForItem:i inSection:0];
                TZAssetCell *cell = (TZAssetCell *)[self.collView cellForItemAtIndexPath:idxp];
                [self selectCell:cell isBack:YES];
            }
            previousEndIdx = idx2;
            if (!isReverse) {
                return;//之前的已经选中/取消选中,不再走下面的逻辑
            }
        }
    }
    BOOL idx2Bigger = idx2 > idx;
    for (NSInteger i = idx; (idx2Bigger && i <= idx2) || (!idx2Bigger && i >= idx2); idx2Bigger ? i++ : i--) {
        NSIndexPath *idxp = [NSIndexPath indexPathForItem:i inSection:0];
        TZAssetCell *cell = (TZAssetCell *)[self.collView cellForItemAtIndexPath:idxp];
        if (isCancel == -1 && i == idx) {//如果第一个选择的是已选中状态,则全体都是取消选中,反之为选中
            isCancel = cell.selectPhotoButton.selected;
        }
        [self selectCell:cell isBack:NO];
    }
    previousEndIdx = idx2;
    NSLog(@"%@选择至%ld", isCancel ? @"取消" : @"", (long)idx2);
}

- (void)selectCell:(TZAssetCell *)cell isBack:(BOOL)isBack {
    BOOL select = isBack ? !isCancel : isCancel;
    SEL selectSel = NSSelectorFromString(@"selectPhotoButtonClick:");
    if ([cell respondsToSelector:selectSel] && cell.selectPhotoButton.selected == select) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [cell performSelector:selectSel withObject:cell.selectPhotoButton];
#pragma clang diagnostic pop
    }
}

@end
