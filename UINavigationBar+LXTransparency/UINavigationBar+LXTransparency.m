//
//  UINavigationBar+LXTransparency.m
//
//  Created by 从今以后 on 17/3/2.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import <objc/message.h>
#import <objc/runtime.h>
#import "UINavigationBar+LXTransparency.h"

@interface UINavigationBar (_LXTransparency)
- (UIViewController *)lx_viewController;
@end


@interface _LXKVOObserver : NSObject {
	UIScrollView *__unsafe_unretained _scrollView;
	UINavigationBar *__unsafe_unretained _navigationBar;
}
- (instancetype)initWithScrollView:(UIScrollView *)scrollView navigationBar:(UINavigationBar *)navigationBar;
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

	// push 等过渡动画会导致 contentOffset 变化，此时不应响应变化
	if ([[_navigationBar lx_viewController] transitionCoordinator]) {
		return;
	}

    CGFloat offsetY = _scrollView.contentOffset.y + _scrollView.contentInset.top;
    if (@available(iOS 11.0, *)) {
        if (_scrollView.contentInsetAdjustmentBehavior != UIScrollViewContentInsetAdjustmentNever) {
            offsetY = _scrollView.contentOffset.y + _scrollView.adjustedContentInset.top;
        }
    }

	CGFloat alpha = offsetY / [_navigationBar lx_fullyTransparentOffset];
	alpha = fmax(0, fmin(alpha, 1));
	[_navigationBar lx_setAlpha:alpha];
}

- (void)dealloc {
	[_scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

@end


@implementation UINavigationBar (LXExtension)

#pragma mark - 绑定 scroll view

- (void)lx_setScrollView:(UIScrollView *)scrollView
{
	if (scrollView) {
		_LXKVOObserver *observer = [[_LXKVOObserver alloc] initWithScrollView:scrollView navigationBar:self];
		objc_setAssociatedObject(self, _cmd, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	} else {
		objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	objc_setAssociatedObject(self, @selector(lx_scrollView), scrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIScrollView *)lx_scrollView {
	return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - 设置完全透明时的偏移量

- (void)lx_setFullyTransparentOffset:(CGFloat)offset {
	objc_setAssociatedObject(self, @selector(lx_fullyTransparentOffset), @(offset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)lx_fullyTransparentOffset {
	return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

#pragma mark - 设置 alpha

- (void)lx_setAlpha:(CGFloat)alpha
{
	id<UIViewControllerTransitionCoordinator> transitionCoordinator = [self lx_viewController].transitionCoordinator;
	if (transitionCoordinator) {
		[transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
			[self lx_setBackgroundViewAlpha:alpha];
		} completion:nil];
	} else {
		[self lx_setBackgroundViewAlpha:alpha];
	}
	objc_setAssociatedObject(self, @selector(lx_lastSetAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 设置 alpha 在主线程，因此同一时间最多只会有一个导航栏调用此方法
static BOOL _shouldSetAlpha = NO;
- (void)lx_setBackgroundViewAlpha:(CGFloat)alpha
{
	_shouldSetAlpha = YES;
	[[self lx_backgroundView] setAlpha:alpha];
	_shouldSetAlpha = NO;
}

#pragma mark - 获取 alpha

- (CGFloat)lx_currentAlpha {
	return [[self lx_backgroundView] alpha];
}

- (CGFloat)lx_lastSetAlpha {
	return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

#pragma mark - 重置 alpha

- (void)lx_resetAlpha
{
	id<UIViewControllerTransitionCoordinator> transitionCoordinator = [self lx_viewController].transitionCoordinator;
	if (transitionCoordinator) {
		[transitionCoordinator animateAlongsideTransitionInView:self animation:^(id context) {
			[self lx_setBackgroundViewAlpha:1.0];
		} completion:nil];
	} else {
		[self lx_setBackgroundViewAlpha:1.0];
	}
}

#pragma mark - 辅助方法

- (UIViewController *)lx_viewController
{
	UIViewController *viewController = objc_getAssociatedObject(self, _cmd);
	if (!viewController) {
		UIResponder *responder = self.nextResponder;
		Class class = [UIViewController class];
		while (responder && ![responder isKindOfClass:class]) {
			responder = responder.nextResponder;
		}
		viewController = (UIViewController *)responder;
		objc_setAssociatedObject(self, _cmd, viewController, OBJC_ASSOCIATION_ASSIGN);
	}
	return viewController;
}

- (UIView *)lx_backgroundView
{
	UIView *backgroundView = objc_getAssociatedObject(self, _cmd);
	if (!backgroundView) {
		if (@available(iOS 11.0, *)) {
			backgroundView = [self valueForKeyPath:@"visualProvider.backgroundView"];
			// 在 iOS 11，测试发现在 viewWillAppear: 之类的方法中改变 alpha 后会被重置为 1.0，故重写 setAlpha: 阻止这种行为。
            Class class = objc_lookUpClass("_LXBarBackground");
            if (class == nil) {
                class = objc_allocateClassPair([backgroundView class], "_LXBarBackground", 0);
                class_addMethod(class, @selector(setAlpha:), (IMP)imp_setAlpha, "v@:d");
                objc_registerClassPair(class);
            }
			object_setClass(backgroundView, class);
		} else if (@available(iOS 10.0, *)) {
			backgroundView = [self valueForKey:@"barBackgroundView"];
		} else {
			backgroundView = [self valueForKey:@"backgroundView"];
		}
		objc_setAssociatedObject(self, _cmd, backgroundView, OBJC_ASSOCIATION_ASSIGN);
	}
	return backgroundView;
}

static void imp_setAlpha(id self, SEL _cmd, CGFloat alpha)
{
	if (_shouldSetAlpha) {
		struct objc_super super = { self, [self superclass] };
		((void(*)(struct objc_super *, SEL, CGFloat))objc_msgSendSuper)(&super, @selector(setAlpha:), alpha);
	}
}

@end
