//
//  MessageCell.h
//  15-QQ聊天布局
//
//  Created by Liu Feng on 13-12-3.
//  Copyright (c) 2013年 Liu Feng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@class MessageFrame;
@interface MessageCell : UITableViewCell

@property (nonatomic, strong) MessageFrame *messageFrame;

@property (nonatomic, assign) id<AVAudioPlayerDelegate> delegate;
@property (nonatomic, assign) SEL didTouch;
@property (nonatomic, assign) SEL didTouchIcon;
@property (nonatomic) NSInteger index;

@property (nonatomic, strong) UIActivityIndicatorView *juhua;
@property (nonatomic, strong) UIImageView *messageSendFailedImageView;

-(void)markStateSettingWithMessage:(Message *)message;
@end
