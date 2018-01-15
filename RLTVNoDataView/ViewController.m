//
//  ViewController.m
//  RLTVNoDataView
//
//  Created by 饶磊 on 2018/1/12.
//  Copyright © 2018年 RL. All rights reserved.
//

#import "ViewController.h"
#import "MJRefresh.h"

#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView               = [[UITableView alloc] initWithFrame:CGRectMake(0, 0,kScreenWidth, kScreenHeight) style:UITableViewStylePlain];
    self.tableView.delegate      = self;
    self.tableView.dataSource    = self;
    [self.view addSubview:self.tableView];

    __weak typeof(self) weakSelf = self;
    self.tableView.mj_header     = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadData];
    }];
    self.tableView.tableFooterView = [UIView new];
}


- (void)loadData{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView.mj_header endRefreshing];
        [self.tableView reloadData];
    });
}

#pragma mark - UItableViewdelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [[UITableViewCell alloc] init];
}

#pragma mark - 调节占位图
- (UIImage *)rl_noDataViewImage {
    return [UIImage imageNamed:@"123.jpg"];
}

- (NSString *)rl_noDataViewString {
    return @"大吉大利，今晚吃鸡";
}

- (UIColor *)rl_noDataViewMessageColor {
    return [UIColor redColor];
}


@end
