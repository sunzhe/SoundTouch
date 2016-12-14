//
//  DotimeManage.m
//  BobySongs
//
//  Created by chuliangliang on 13-12-25.
//  Copyright (c) 2013年 banvon. All rights reserved.
//

#import "DotimeManage.h"

@implementation DotimeManage
static DotimeManage *timeManage = nil;
+ (DotimeManage *)DefaultManage{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeManage = [[DotimeManage alloc] init];
    });
    return timeManage;
}
- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

//开始计时
- (void)startTime {
    //停止上次计时器
    [self stopTimer];
    
    if (BBtimer == nil) {
        self.timeValue = 0;
        BBtimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(TimerAction) userInfo:nil repeats:YES];
        NSRunLoop *main=[NSRunLoop currentRunLoop];
        [main addTimer:BBtimer forMode:NSRunLoopCommonModes];
    }
}

//停止计时
- (void)stopTimer {
    if (BBtimer != nil) {
        [BBtimer invalidate];
        BBtimer = nil;
    }
}

//倒计时
- (void)TimerAction {
    self.timeValue ++;
    if ([self.delegate respondsToSelector:@selector(TimerActionValueChange:)]) {
        [self.delegate TimerActionValueChange:self.timeValue];
    }
}
@end
