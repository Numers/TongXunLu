//
//  ChatViewRightItemsView.h
//  TongXunLu
//
//  Created by macmini on 14-12-8.
//  Copyright (c) 2014年 dhb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocal.h"

@interface ChatViewRightItemsView : UIView
@property (nonatomic, strong) UIButton *callBtn;
@property (nonatomic, strong) UIButton *profileBtn;
@property (nonatomic, assign) id<ETChatTableViewControllerDelegate> delegate;
@end
