//
//  ChatViewController.m
//  WeChat
//
//  Created by macmini on 14-5-6.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "ChatTableViewController.h"
#import "MessageFrame.h"
#import "MessageCell.h"
#import "ClientHelper.h"
#import "AppDelegate.h"
#import "SMessageDB.h"
#import "SFriendDB.h"

#import "ChatCacheFileUtil.h"
#import "VoiceConverter.h"

#import "SuperChatMemberInfoViewController.h"
#import "MemberDetailViewController.h"
#import "MemberInfoDisplayViewController.h"

#import "VoicePlayDevice.h"

#define CONNECT_TIMEOUT 15.0
#define WRITE_TIMEOUT 10.0
#define SHOWMSGBETWEENTIME 120.0

@interface ChatTableViewController ()<UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray  *_allMessagesFrame;
}
@end

@implementation ChatTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithMember:(Member *)member WithHostMember:(Member *)host;
{
    self = [super init];
    if (self) {
        _chatToMember = member;
        _hostMember = host;
        _isCurrentPresentView = NO;
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTableView)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = self.chatToMember.nickName;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self  action:@selector(pushToSuperChatMemberInfoView)];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] init];
    backItem.title = @"返回";
    self.navigationItem.backBarButtonItem = backItem;
    //[self.navigationController.navigationBar setTranslucent:YES];
    CGFloat inputViewHeight;
    
    if ([[[UIDevice currentDevice]systemVersion]floatValue]>=7) {
        inputViewHeight = 45.0f;
    }
    else{
        inputViewHeight = 40.0f;
    }
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    CGRect frame = [(AppDelegate *)[UIApplication sharedApplication].delegate viewFrame:self.navigationController withTabBarController:self.tabBarController];
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, frame.size.height-inputViewHeight);

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO;
    [self.view addSubview:self.tableView];
    [self.tableView addGestureRecognizer:_tapGestureRecognizer];

    _allMessagesFrame = [NSMutableArray array];
    if (_chatToMember.messageArr.count > 0) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSDate *previousTime = [NSDate dateWithTimeIntervalSince1970:0];
        for (Message *m in self.chatToMember.messageArr) {
            MessageFrame *messageFrame = [[MessageFrame alloc] init];
            NSDate *messageDate = [formatter dateFromString:m.time];
            NSTimeInterval i = [messageDate timeIntervalSinceDate:previousTime];
            messageFrame.showTime = i>SHOWMSGBETWEENTIME?true:false;
            messageFrame.message = m;
            messageFrame.hostMemberId = _hostMember.memberId;
            previousTime = messageDate;
            [_allMessagesFrame addObject:messageFrame];
        }

    }
}

-(CGFloat)allMessageFrameCellHeight
{
    CGFloat height = 0.0f;
    for (MessageFrame *mf in _allMessagesFrame) {
        height = height + [mf cellHeight];
    }
    return height;
}

-(void)notificationSetting
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addSendMessageToTableView:) name:@"TABLEVIEWRELOAD" object:nil];
}

-(void)initAudio{
    //    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
    
    //添加监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sensorStateChange:)
                                                 name:@"UIDeviceProximityStateDidChangeNotification"
                                               object:nil];
}

-(void)unInitAudio{
    //    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
    
    //添加监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
}

//处理监听触发事件
-(void)sensorStateChange:(NSNotificationCenter *)notification;
{
    //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗（省电啊）
    if ([[UIDevice currentDevice] proximityState] == YES)
    {
        NSLog(@"Device is close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
    }
    else
    {
        NSLog(@"Device is not close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bg_default.jpg"]];
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self notificationSetting];
    if (self.chatToMember.messageArr.count > 0) {
        if([super isMovingToParentViewController]){
            [self TableViewReloadData];
        }
    }
    _isCurrentPresentView = YES;
    
    SMessageDB *msgdb = [[SMessageDB alloc] init];
    [msgdb mergeNotReadMessageToReadMessageWithUid:_chatToMember.memberId WithContactUid:_hostMember.memberId];
    [msgdb close];
    _hostMember.messageNotReadCount = _hostMember.messageNotReadCount-_chatToMember.messageNotReadCount;
    _chatToMember.messageNotReadCount = 0;
}

- (void)viewWillDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];
    _isCurrentPresentView = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Checking if we are disappearing because of the back button
    
    if ([self isMovingFromParentViewController])
        
    {
        // In case that back button is pressed, insert your code here
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)pushToSuperChatMemberInfoView
{
    SuperChatMemberInfoViewController *superChatMemberInfoVC = [[SuperChatMemberInfoViewController alloc] initWithHostMember:_hostMember WithChatMember:_chatToMember];
    HomeViewController *homeVC = [[CommonUtil appDelegate] returnHomeViewController];
    superChatMemberInfoVC.delegate = homeVC;
    [self.navigationController pushViewController:superChatMemberInfoVC animated:YES];
}

#pragma mark 给数据源增加内容
- (void)addMessage:(Message *)msg{
    
    MessageFrame *mf = [[MessageFrame alloc] init];
    if (_chatToMember.messageArr.count > 0) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        Message *previousMsg = [self.chatToMember.messageArr objectAtIndex:self.chatToMember.messageArr.count-1];
        NSDate *previousTime = [fmt dateFromString:previousMsg.time];
        NSDate *messageDate = [fmt dateFromString:msg.time];
        NSTimeInterval i = [messageDate timeIntervalSinceDate:previousTime];
        mf.showTime = i>SHOWMSGBETWEENTIME?true:false;
    }else
    {
        mf.showTime = true;
    }
    mf.message = msg;
    mf.hostMemberId = _hostMember.memberId;

    [_chatToMember.messageArr addObject:msg];
    [_allMessagesFrame addObject:mf];
    
    SMessageDB *msgdb = [[SMessageDB alloc] init];
    if ([msg isValidate]) {
        [msgdb saveMessage:msg WithUid:_chatToMember.memberId WithContactUid:self.hostMember.memberId];
        _chatToMember.isSession = 1;
        SFriendDB *frienddb = [[SFriendDB alloc] init];
        [frienddb mergeWithUser:_chatToMember WithBelongUid:self.hostMember.memberId];
        [frienddb close];
    }
    [msgdb close];
    
    [self performSelectorOnMainThread:@selector(TableViewReloadData) withObject:nil waitUntilDone:NO];
}

-(void)addSendMessageToTableView:(NSNotification *)notification
{
    NSDictionary *dic = [notification object];
    NSInteger retcode = [[dic valueForKey:@"retcode"] integerValue];
    NSInteger msgsn = [[dic valueForKey:@"msgsn"] integerValue];
    NSLog(@"%ld, %ld",(long)retcode,(long)msgsn);
    if (msgsn < self.chatToMember.messageArr.count) {
        Message *message = [self.chatToMember.messageArr objectAtIndex:msgsn];
        if (message.state == MessageIsSend) {
            if (retcode == 0) {
                message.state = MessageSuccess;
            }else{
                message.state = MessageFailed;
            }
            
            [self performSelectorOnMainThread:@selector(updateMessageStateWithMessage:) withObject:message waitUntilDone:NO];
        }
    }
}

-(void)updateMessageStateWithMessage:(Message *)msg
{
    SMessageDB *msgdb = [[SMessageDB alloc] init];
    if ([msg isValidate]) {
        [msgdb mergeMessage:msg WithUid:self.chatToMember.memberId WithContactUid:self.hostMember.memberId];
    }
    [msgdb close];
    
    [self performSelectorOnMainThread:@selector(TableViewReloadData) withObject:nil waitUntilDone:NO];
}

-(void)TableViewReloadData
{
    [self.tableView reloadData];
    [self tableViewscrollToBottom];
}

-(void)tableViewscrollToBottom
{
    //滚动至当前行
    if (_allMessagesFrame.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_allMessagesFrame.count - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - tableView数据源方法

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _allMessagesFrame.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%ld",(long)indexPath.row];
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Message *message = [_chatToMember.messageArr objectAtIndex:indexPath.row];
    if (cell == nil) {
        cell = [[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                //Data processing
                dispatch_async(dispatch_get_main_queue(), ^{
                    //Update Interface
                    // 设置数据
                    cell.messageFrame = _allMessagesFrame[indexPath.row];
                    if (message.code == MessageCodeText) {
                        cell.delegate = self;
                        cell.index = indexPath.row;
                        cell.didTouchIcon = @selector(onClickHeadImage:);
                        if (message.contentType == MessageContentVoice) {
                            cell.didTouch = @selector(onSelect:);
                        }
                    }
                });
            }
        });
    }else{
        [cell markStateSettingWithMessage:message];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return [_allMessagesFrame[indexPath.row] cellHeight];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - 代理方法

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SCROLLDRAGGING" object:nil];
}

-(void)tapTableView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SCROLLDRAGGING" object:nil];
}


-(void)onSelect:(UIView*)sender{
    int n = sender.tag;
    Message *msg=[self.chatToMember.messageArr objectAtIndex:n];
    
    switch (msg.contentType) {
        case MessageContentVoice:{
            [self recordPlay:msg];
            break;
        }
        default:
            break;
    }
    msg = nil;
}

-(void)onClickHeadImage:(UIView*)sender{
    int n = sender.tag;
    Message *msg=[self.chatToMember.messageArr objectAtIndex:n];
    if (msg.type == MessageTypeMe) {
        MemberDetailViewController *memberDetailVC = [[MemberDetailViewController alloc] initWithHost:_hostMember WithAddMember:_hostMember];
        [self.navigationController pushViewController:memberDetailVC animated:YES];
    }else{
        MemberInfoDisplayViewController *memberInfoDisplayVC = [[MemberInfoDisplayViewController alloc] initWithChatMember:_chatToMember];
        HomeViewController *homeVC = [[CommonUtil appDelegate] returnHomeViewController];
        memberInfoDisplayVC.delegate = homeVC;
        [self.navigationController pushViewController:memberInfoDisplayVC animated:YES];
    }
}

-(void)recordPlay:(Message*)msg{
    NSArray *array = [msg.content componentsSeparatedByString:@"|"];
    if ((array != nil) && (array.count == 2)) {
        NSString *amrFullPath;
        if (msg.type == MessageTypeMe) {
            amrFullPath = [[[ChatCacheFileUtil sharedInstance] userDocPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[array objectAtIndex:0]]];
        }else if(msg.type == MessageTypeOther){
            NSRange range = [[array objectAtIndex:0] rangeOfString:@"/"];
            NSString *fileName = [[array objectAtIndex:0] substringFromIndex:range.location+range.length];
            amrFullPath = [[[ChatCacheFileUtil sharedInstance] userDocPath] stringByAppendingPathComponent:fileName];
            
            NSFileManager *fileManager = [NSFileManager defaultManager];

            if (![fileManager fileExistsAtPath:amrFullPath]) {
                NSString *fileUrl = [NSString stringWithFormat:@"%@/UpLoadFile/%@",BASEURL,[array objectAtIndex:0]];
                NSData *amrData = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileUrl]];
                [amrData writeToFile:amrFullPath atomically:YES];
            }
        }
        //[msg.fileData writeToFile:fullPath atomically:YES];
        NSString *wavPath = [VoiceConverter amrToWav:amrFullPath];
        audioPlayer = [VoicePlayDevice shareInstanceWithFilePath:wavPath];
        [audioPlayer setVolume:1];
        [audioPlayer prepareToPlay];
        [audioPlayer setDelegate:self];
        [audioPlayer play];
        
        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
        
        [[ChatCacheFileUtil sharedInstance] deleteWithContentPath:wavPath];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
}
@end
