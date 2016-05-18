//
//  FacePanelViewController.h
//  ylmm
//
//  Created by macmini on 14-5-29.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatTableViewController.h"
#import "ZBMessageInputView.h"
#import "ZBMessageShareMenuView.h"
#import "ZBMessageManagerFaceView.h"

#import <AVFoundation/AVFoundation.h>
#define kRecorderViewRect       CGRectMake([UIScreen mainScreen].bounds.size.width/2-80, [UIScreen mainScreen].bounds.size.height/2-120, 160, 160)
//#define kCancelOriginY          ([[UIScreen mainScreen]bounds].size.height-70)
@class Message;
@class ChatRecorderView;

@interface  ChatViewController: ChatTableViewController<UITextFieldDelegate,ZBMessageShareMenuViewDelegate,ZBMessageManagerFaceViewDelegate,ZBMessageInputViewDelegate>
{
    BOOL recording;
    
    AVAudioRecorder *audioRecorder;
	NSURL *pathURL;
    NSString *amrFileName;
    
    NSTimeInterval _timeLen;
    
    ChatRecorderView *recorderView;
    NSTimer *recorderViewTimer;
    CGPoint curTouchPoint;      //触摸点
    BOOL canNotSend;
    CGFloat curCount;           //当前计数,初始为0
}

@property (nonatomic,strong) ZBMessageInputView *messageToolView;

@property (nonatomic,strong) ZBMessageManagerFaceView *faceView;

@property (nonatomic,strong) ZBMessageShareMenuView *shareMenuView;

@property (nonatomic,assign) CGFloat previousTextViewContentHeight;

//@property(assign, nonatomic) id<ChatViewDelegate> delegate;

- (void)messageViewAnimationWithMessageRect:(CGRect)rect  withMessageInputViewRect:(CGRect)inputViewRect andDuration:(double)duration andState:(ZBMessageViewState)state;
@end
