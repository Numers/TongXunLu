//
//  ZBExpressionSectionBar.m
//  MessageDisplay
//
//  Created by zhoubin@moshi on 14-5-13.
//  Copyright (c) 2014年 Crius_ZB. All rights reserved.
//

#import "ZBExpressionSectionBar.h"

@implementation ZBExpressionSectionBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:255.0f/255 green:250.0f/255 blue:240.0f/255 alpha:1];
        UIButton *sendBtn = [[UIButton alloc] initWithFrame:CGRectMake(250.0f, 0.0f, 70.0f, CGRectGetHeight(frame))];
        [sendBtn addTarget:self action:@selector(clickSendBtn) forControlEvents:UIControlEventTouchUpInside];
        [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
        [sendBtn setBackgroundColor:[UIColor blueColor]];
        sendBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [sendBtn setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [self addSubview:sendBtn];
    }
    return self;
}

-(void)clickSendBtn
{
    if ([self.delegate respondsToSelector:@selector(sendBtnClick)]) {
        [self.delegate sendBtnClick];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
