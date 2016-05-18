//
//  ChatViewController.h
//  WeChat
//
//  Created by macmini on 14-5-6.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Member.h"
#import "Message.h"
#import "ZBMessageInputView.h"
#import <AVFoundation/AVFoundation.h>

@interface ChatTableViewController : UIViewController<AVAudioPlayerDelegate>{
    AVAudioPlayer *audioPlayer;
}
//@property (strong, nonatomic) IBOutlet UITextField *messageField;
//@property (strong, nonatomic) IBOutlet UIButton *speakBtn;
@property (strong, nonatomic) Member *chatToMember;
@property (strong, nonatomic) Member *hostMember;

@property (strong, nonatomic)  UITableView *tableView;
//@property (strong, nonatomic) FacePanelViewController *facePanelVC;
@property (nonatomic) BOOL isCurrentPresentView;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

//- (IBAction)voiceBtnClick:(UIButton *)sender;

//-(IBAction)faceBtnClick:(id)sender;
- (void)addMessage:(Message *)msg;
-(id)initWithMember:(Member *)member WithHostMember:(Member *)host;
-(void)TableViewReloadData;

-(void)updateMessageStateWithMessage:(Message *)msg;

-(CGFloat)allMessageFrameCellHeight;
-(void)tableViewscrollToBottom;
@end
