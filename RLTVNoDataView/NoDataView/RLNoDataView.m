//
//  RLNoDataView.m
//  RLTVNoDataView
//
//  Created by 饶磊 on 2018/1/12.
//  Copyright © 2018年 RL. All rights reserved.
//

#import "RLNoDataView.h"

NSString * const kRLNoDataViewObserveKeyPath = @"frame";

@implementation RLNoDataView

-(void)dealloc{
    NSLog(@"占位图没了");
}

@end
