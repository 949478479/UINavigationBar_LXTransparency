//
//  UINavigationBar+LXAlphaChange.m
//
//  Created by 从今以后 on 17/3/2.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import <objc/runtime.h>
#import "UINavigationBar+LXAlphaChange.h"

@interface _LXKVOObserver : NSObject
{
	UIScrollView *_scrollView;
	UINavigationBar *__unsafe_unretained _navigationBar;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView navigationBar:(UINavigationBar *)navigationBar;

@end

@implementation UINavigationBar (LXExtension)

#pragma mark - 绑定 scroll view

- (void)lx_setScrollView:(UIScrollView *)scrollView
{
	objc_setAssociatedObject(self, @selector(lx_scrollView), scrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	if (scrollView) {
		_LXKVOObserver *observer = [[_LXKVOObserver alloc] initWithScrollView:scrollView navigationBar:self];
		objc_setAssociatedObject(self, _cmd, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	} else {
		objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
}

- (UIScrollView *)lx_scrollView
{
	return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - 设置完全透明时的偏移量

- (void)lx_setFullyTransparentOffset:(CGFloat)offset
{
	objc_setAssociatedObject(self, @selector(lx_fullyTransparentOffset), @(offset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)lx_fullyTransparentOffset
{
	return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

#pragma mark - 设置 alpha

- (void)lx_setAlpha:(CGFloat)alpha
{
	id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.lx_viewController.transitionCoordinator;
	if (transitionCoordinator) {
		[transitionCoordinator animateAlongsideTransitionInView:self animation:^(id context) {
			[[self lx_backgroundView] setAlpha:alpha];
		} completion:nil];
	} else {
		[[self lx_backgroundView] setAlpha:alpha];
	}

	objc_setAssociatedObject(self, @selector(lx_lastSetAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - 获取 alpha

- (CGFloat)lx_currentAlpha
{
	return [[self lx_backgroundView] alpha];
}

- (CGFloat)lx_lastSetAlpha
{
	return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

#pragma mark - 重置 alpha

- (void)lx_resetAlpha
{
	id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.lx_viewController.transitionCoordinator;
	if (transitionCoordinator) {
		[transitionCoordinator animateAlongsideTransitionInView:self animation:^(id context) {
			[[self lx_backgroundView] setAlpha:1.0];
		} completion:nil];
	} else {
		[[self lx_backgroundView] setAlpha:1.0];
	}
}

#pragma mark - 辅助方法

- (UIViewController *)lx_viewController
{
	UIResponder *responder = self.nextResponder;
	for (Class cls = [UIViewController class]; responder && ![responder isKindOfClass:cls];) {
		responder = responder.nextResponder;
	}
	return (UIViewController *)responder;
}

- (UIView *)lx_backgroundView
{
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_9_x_Max) {
        return [self valueForKey:@"barBackgroundView"];
    }
    return [self valueForKey:@"backgroundView"];
}

@end

@implementation _LXKVOObserver

- (instancetype)initWithScrollView:(UIScrollView *)scrollView navigationBar:(UINavigationBar *)navigationBar
{
	self = [super init];
	if (self) {
		_scrollView = scrollView;
		_navigationBar = navigationBar;
		[scrollView addObserver:self forKeyPath:@"contentOffset" options:kNilOptions context:NULL];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object != _scrollView) {
		return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}

	// push 动画会导致 contentOffset 变化，此时不应响应变化
	if ([[_navigationBar lx_viewController] transitionCoordinator]) {
		return;
	}

	CGFloat alpha = (_scrollView.contentOffset.y + _scrollView.contentInset.top) / [_navigationBar lx_fullyTransparentOffset];
	alpha = fmax(0, fmin(alpha, 1));
	[_navigationBar lx_setAlpha:alpha];
}

- (void)dealloc
{
	[_scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

@end
