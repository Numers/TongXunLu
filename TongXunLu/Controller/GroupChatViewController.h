//
//  GroupChatViewController.h
//  ylmm
//
//  Created by macmini on 14-7-2.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupChatTableViewController.h"
#import "ZBMessageInputView.h"
#import "ZBMessageShareMenuView.h"
#import "ZBMessageManagerFaceView.h"

#import <AVFoundation/AVFoundation.h>
#define kRecorderViewRect       CGRectMake([UIScreen mainScreen].bounds.size.width/2-80, [UIScreen mainScreen].bounds.size.height/2-120, 160, 160)
//#define kCancelOriginY          ([[UIScreen mainScreen]bounds].size.height-70)
@class ChatRecorderView;

@interface GroupChatViewController : GroupChatTableViewController<UITextFieldDelegate,ZBMessageInputViewDelegate,ZBMessageShareMenuViewDelegate,ZBMessageManagerFaceViewDelegate>
{
    BOOL g_recording;
    
    AVAudioRecorder *g_audioRecorder;
	NSURL *g_pathURL;
    NSString *g_amrFileName;
    
    NSTimeInterval g_timeLen;
    
    ChatRecorderView *g_recorderView;
    NSTimer *g_recorderViewTimer;
    CGPoint g_curTouchPoint;      //触摸点
    BOOL g_canNotSend;
    CGFloat g_curCount;           //当前计数,初始为0
}

@property (nonatomic,strong) ZBMessageInputView *g_messageToolView;

@property (nonatomic,strong) ZBMessageManagerFaceView *g_faceView;

@property (nonatomic,strong) ZBMessageShareMenuView *g_shareMenuView;

@property (nonatomic,assign) CGFloat g_previousTextViewContentHeight;

- (void)messageViewAnimationWithMessageRect:(CGRect)rect  withMessageInputViewRect:(CGRect)inputViewRect andDuration:(double)duration andState:(ZBMessageViewState)state;

@end
