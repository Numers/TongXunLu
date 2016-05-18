//
//  ChatViewRightItemsView.m
//  TongXunLu
//
//  Created by macmini on 14-12-8.
//  Copyright (c) 2014年 dhb. All rights reserved.
//

#import "ChatViewRightItemsView.h"

@implementation ChatViewRightItemsView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _callBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, frame.size.width/2-10, frame.size.height)];
        [_callBtn setBackgroundImage:[UIImage imageNamed:@"activity_chat_sipcall"] forState:UIControlStateNormal];
        [_callBtn addTarget:self action:@selector(callContact) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_callBtn];
        
        _profileBtn = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width/2+10, 0, frame.size.width/2-10, frame.size.height)];
        [_profileBtn setBackgroundImage:[UIImage imageNamed:@"tab_user_center_normal"] forState:UIControlStateNormal];
        [_profileBtn addTarget:self action:@selector(pushContactProfileView) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_profileBtn];
    }
    return self;
}

-(void)callContact
{
    if ([_delegate respondsToSelector:@selector(callContactMember)]) {
        [_delegate callContactMember];
    }
}

-(void)pushContactProfileView
{
    if ([_delegate respondsToSelector:@selector(pushContactMemberInfoVC)]) {
        [_delegate pushContactMemberInfoVC];
    }
}

@end
