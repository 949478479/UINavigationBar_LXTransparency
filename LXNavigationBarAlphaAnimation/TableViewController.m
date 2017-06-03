//
//  TableViewController.m
//  LXNavigationBarAlphaAnimation
//
//  Created by 从今以后 on 17/3/3.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import "TableViewController.h"
#import "UINavigationBar+LXAlphaAnimation.h"

@interface TableViewController ()
@property (nonatomic) UINavigationBar *navigationBar;
@end

@implementation TableViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.navigationBar = self.navigationController.navigationBar;

	// 关联 scroll view 就可以自动调整 alpha
	[self.navigationBar lx_setScrollView:self.tableView];
	[self.navigationBar lx_setFullyTransparentOffset:CGRectGetHeight(self.tableView.tableHeaderView.bounds) - 64];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	// 也可以手动设置 alpha
	[self.navigationBar lx_setAlpha:self.navigationBar.lx_lastSetAlpha];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	// 跳转界面时可根据需要还原 alpha
	[self.navigationBar lx_resetAlpha];
}

@end
