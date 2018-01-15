//
//  UITableView+RLNoDataView.m
//  RLTVNoDataView
//
//  Created by 饶磊 on 2018/1/11.
//  Copyright © 2018年 RL. All rights reserved.
//

#import "UITableView+RLNoDataView.h"
#import <objc/runtime.h>
#import "RLNoDataView.h"

#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@protocol RLTableViewDelegate <NSObject>
@optional
- (UIView *)rl_noDataView;               //  完全自定义占位图
- (UIImage *)rl_noDataViewImage;         //  使用默认占位图, 提供一张图片,可不提供, 默认不显示
- (NSString *)rl_noDataViewString;       //  使用默认占位图, 提供显示文字,可不提供, 默认为暂无数据
- (UIColor *)rl_noDataViewStringColor;   //  使用默认占位图, 提供显示文字颜色, 可不提供, 默认为灰色
- (NSNumber *)rl_noDataViewCenterYOffset;//  使用默认占位图, CenterY 向下的偏移量

@end


@implementation UITableView (RLNoDataView)

/**
 加载时，交换方法
 */
+(void)load{
    
    //执行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
     
        Method reloadData       =   class_getInstanceMethod(self, @selector(reloadData));
        Method rl_reloadData    =   class_getInstanceMethod(self, @selector(rl_reloadData));
        method_exchangeImplementations(reloadData, rl_reloadData);
    
        Method dealloc          =   class_getInstanceMethod(self, NSSelectorFromString(@"dealloc"));
        Method rl_dealloc       =   class_getInstanceMethod(self, @selector(rl_dealloc));
        method_exchangeImplementations(dealloc, rl_dealloc);
    });
}



- (void)rl_reloadData {
    [self rl_reloadData];
    
    //忽略第一次加载
    if (![self isInitFinish]) {
        [self rl_havingData:YES];
        [self setIsInitFinish:YES];
        return;
    }
    
    //刷新完成之后检测数据
    dispatch_async(dispatch_get_main_queue(), ^{
       
        NSInteger number = [self numberOfSections];
        BOOL havingData = NO;
        for (NSInteger i = 0; i < number; i ++) {
            if ([self numberOfRowsInSection:i]>0) {
                havingData = YES;
                break;
            }
        }
        [self rl_havingData:havingData];
    });
}

- (void)rl_havingData:(BOOL)havingData {
    
    //不需要展示占位图
    if (havingData) {
        self.backgroundView  = nil;
        return;
    }
    
    //不需要重复创建
    if (self.backgroundView) {
        return;
    }
    
    //自定义占位图
    if ([self.delegate respondsToSelector:@selector(rl_noDataView)]) {
        self.backgroundView = [self.delegate performSelector:@selector(rl_noDataView)];
        return;
    }
    
    //使用自带的图片，文字，颜色以及偏移量
    UIImage *img   = nil;
    NSString *str  = @"暂无数据";
    UIColor *color = [UIColor lightGrayColor];
    CGFloat offset = 0;
    
    //获取图片
    if ([self.delegate respondsToSelector:@selector(rl_noDataViewImage)]) {
        img = [self.delegate performSelector:@selector(rl_noDataViewImage)];
    }
    //获取文字
    if ([self.delegate respondsToSelector:@selector(rl_noDataViewString)]) {
        str = [self.delegate performSelector:@selector(rl_noDataViewString)];
    }
    //获取颜色
    if ([self.delegate respondsToSelector:@selector(rl_noDataViewStringColor)]) {
        color = [self.delegate performSelector:@selector(rl_noDataViewStringColor)];
    }
    //获取偏移量
    if ([self.delegate respondsToSelector:@selector(rl_noDataViewCenterYOffset)]) {
        offset = [[self.delegate performSelector:@selector(rl_noDataViewCenterYOffset)] floatValue];
    }
    //创建占位图
    self.backgroundView = [self rl_defaultNoDataViewWithImage:img
                                                       string:str
                                                        color:color
                                                      offsetY:offset];
}

/**
 默认的占位图
 */
- (UIView *)rl_defaultNoDataViewWithImage:(UIImage *)image string:(NSString *)string color:(UIColor *)color offsetY:(CGFloat)offset {

    //计算位置，垂直居中，照片默认中心偏上
    CGFloat sW = self.bounds.size.width;
    CGFloat cX = sW / 2;
    CGFloat cY = self.bounds.size.height * (1 - 0.618) + offset;
    CGFloat iW = image.size.width;
    CGFloat iH = image.size.height;
    
    //图片
    UIImageView *imgView     = [[UIImageView alloc] init];
    imgView.contentMode      = UIViewContentModeScaleAspectFill;
    imgView.frame            = CGRectMake(cX-iW / 2, cY-iH / 2, iW, iH);
    imgView.image            = image;
    
    //文字
    UILabel *label           = [[UILabel alloc] init];
    label.font               = [UIFont systemFontOfSize:17];
    label.textColor          = color;
    label.text               = string;
    label.textAlignment      = NSTextAlignmentCenter;
    label.frame              = CGRectMake(0, CGRectGetMaxY(imgView.frame) + 24, sW, label.font.lineHeight);
    
    //视图
    RLNoDataView *view       = [[RLNoDataView alloc] init];
    [view addSubview:imgView];
    [view addSubview:label];
    
    //实现跟随TableView滚动
    [view addObserver:self forKeyPath:kRLNoDataViewObserveKeyPath options:NSKeyValueObservingOptionNew context:nil];
    
    return view;
}


#pragma mark - 标记属性

// 加载完数据的标记属性名
static NSString *const kRLTableViewPropertyInitFinish = @"kRLTableViewPropertyInitFinish";

/**
 设置已经加载完成的数据
 */
- (void)setIsInitFinish:(BOOL)finish{
    objc_setAssociatedObject(self, &kRLTableViewPropertyInitFinish, @(finish), OBJC_ASSOCIATION_ASSIGN);
}

/**
 是否已经加载完成数据
 */
- (BOOL)isInitFinish{
    id obj = objc_getAssociatedObject(self, &kRLTableViewPropertyInitFinish);
    return [obj boolValue];
}

/**
 监听
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:kRLNoDataViewObserveKeyPath]) {
        
        /**
         在 TableView 滚动 ContentOffset 改变时, 会同步改变 backgroundView 的 frame.origin.y
         可以实现, backgroundView 位置相对于 TableView 不动, 但是我们希望
         backgroundView 跟随 TableView 的滚动而滚动, 只能强制设置 frame.origin.y 永远为 0
         兼容 MJRefresh
         */
        CGRect frame        = [[change objectForKey:NSKeyValueChangeNewKey] CGRectValue];
        if (frame.origin.y != 0) {
            frame.origin.y  = 0 ;
            self.backgroundView.frame = frame;
        }
        
    }
}

/**
 移除 KVO 监听
 */
- (void)freeNoDataViewIfNeeded {
    
    if ([self.backgroundView isKindOfClass:[RLNoDataView class]]) {
        [self.backgroundView removeObserver:self forKeyPath:kRLNoDataViewObserveKeyPath context:nil];
    }
}


- (void)rl_dealloc {
    [self freeNoDataViewIfNeeded];
    [self rl_dealloc];
    NSLog(@"RLTV 视图正常销毁");
}

@end
