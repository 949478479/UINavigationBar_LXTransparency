# LXNavigationBar

![](https://github.com/949478479/LXNavigationBar/blob/gif/screenshot.gif)

```objective-c
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
```
