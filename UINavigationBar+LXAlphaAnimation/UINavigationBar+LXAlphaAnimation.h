//
//  UINavigationBar+LXAlphaAnimation.h
//
//  Created by 从今以后 on 17/3/2.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationBar (LXAlphaAnimation)

/// 设置关联的 scroll view，通过 KVO 监测 contentOffset 来自动调整 alpha
- (void)lx_setScrollView:(UIScrollView *)scrollView;
- (UIScrollView *)lx_scrollView;

/// 设置完全透明时 scroll view 偏移量，仅在关联了 scroll view 时有效
- (void)lx_setFullyTransparentOffset:(CGFloat)offset;
- (CGFloat)lx_fullyTransparentOffset;

/// 手动设置 alpha，在 viewWillAppear 等方法中设置则附带动画效果
- (void)lx_setAlpha:(CGFloat)alpha;

/// 当前 alpha
- (CGFloat)lx_currentAlpha;

/// 最后一次设置的 alpha
- (CGFloat)lx_lastSetAlpha;

/// 将 alpha 重置为 1.0，不影响 lastSetAlpha
- (void)lx_resetAlpha;

@end
