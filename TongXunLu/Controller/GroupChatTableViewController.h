//
//  GroupChatTableViewController.h
//  ylmm
//
//  Created by macmini on 14-7-1.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBMessageInputView.h"
#import <AVFoundation/AVFoundation.h>
#import "Group.h"
#import "Member.h"
#import "GroupMessage.h"

#import "protocal.h"

@interface GroupChatTableViewController : UIViewController<AVAudioPlayerDelegate>{
    AVAudioPlayer *g_audioPlayer;
}
@property (strong, nonatomic) Group *chatToGroup;
@property (strong, nonatomic) Member *hostMember;

@property (strong, nonatomic)  UITableView *g_tableView;
@property (nonatomic) BOOL g_isCurrentPresentView;

@property (nonatomic, assign) id<HomeViewDelegate> delegate;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

- (void)addMessage:(GroupMessage *)msg;
-(id)initWithGroup:(Group *)group WithHostMember:(Member *)host;
-(void)TableViewReloadData;
-(void)tableViewscrollToBottom;

-(void)navigationTitleValue:(NSString *)title;
-(void)updateGroupMessageStateWithMessage:(GroupMessage *)msg;
@end
