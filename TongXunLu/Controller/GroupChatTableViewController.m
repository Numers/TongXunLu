//
//  GroupChatTableViewController.m
//  ylmm
//
//  Created by macmini on 14-7-1.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "GroupChatTableViewController.h"
#import "GroupMessageFrame.h"
#import "GroupMessageCell.h"
#import "ClientHelper.h"
#import "AppDelegate.h"
#import "SGroupMessageDB.h"
#import "SGroupDB.h"

#import "SFriendDB.h"
#import "ModelConvert.h"

#import "GroupMemberInfoDisplayViewController.h"
#import "MemberDetailViewController.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"

#import "ChatCacheFileUtil.h"
#import "VoiceConverter.h"

#import "GroupSuperChatInfoViewController.h"

#import "protocal.h"

#import "VoicePlayDevice.h"

#define CONNECT_TIMEOUT 15.0
#define WRITE_TIMEOUT 10.0
#define SHOWMSGBETWEENTIME 120.0

@interface GroupChatTableViewController ()<UITableViewDataSource, UITableViewDelegate>

@end

@implementation GroupChatTableViewController
{
    NSMutableArray  *_allGroupMessagesFrame;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithGroup:(Group *)group WithHostMember:(Member *)host
{
    self = [super init];
    if (self) {
        _chatToGroup = group;
        _hostMember = host;
        _g_isCurrentPresentView = NO;
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTableView)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self  action:@selector(pushToGroupSuperChatInfoView)];
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] init];
    backItem.title = @"返回";
    [self.navigationItem setBackBarButtonItem: backItem];
    //[self.navigationController.navigationBar setTranslucent:YES];
    CGFloat inputViewHeight;
    
    if ([[[UIDevice currentDevice]systemVersion]floatValue]>=7) {
        inputViewHeight = 45.0f;
    }
    else{
        inputViewHeight = 40.0f;
    }
    
    self.g_tableView = [[UITableView alloc] init];
    self.g_tableView.delegate = self;
    self.g_tableView.dataSource = self;
    CGRect frame = [(AppDelegate *)[UIApplication sharedApplication].delegate viewFrame:self.navigationController withTabBarController:self.tabBarController];
    self.g_tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, frame.size.height-inputViewHeight);
    
    self.g_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.g_tableView.allowsSelection = NO;
    [self.view addSubview:self.g_tableView];
    [self.g_tableView addGestureRecognizer:_tapGestureRecognizer];
    
    _allGroupMessagesFrame = [NSMutableArray array];
    if (_chatToGroup.groupMessage.count > 0) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSDate *previousTime = [NSDate dateWithTimeIntervalSince1970:0];
        for (GroupMessage *m in _chatToGroup.groupMessage) {
            GroupMessageFrame *messageFrame = [[GroupMessageFrame alloc] init];
            NSDate *messageDate = [formatter dateFromString:m.time];
            NSTimeInterval i = [messageDate timeIntervalSinceDate:previousTime];
            messageFrame.showTime = i>SHOWMSGBETWEENTIME?true:false;
            messageFrame.message = m;
            messageFrame.hostMemberId = _chatToGroup.belongMemberId;
            previousTime = messageDate;
            [_allGroupMessagesFrame addObject:messageFrame];
        }
        
    }
}

-(void)notificationSetting
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addSendGroupMessageToTableView:) name:@"TABLEVIEWRELOAD" object:nil];
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
    self.navigationItem.title = _chatToGroup.groupName;
    self.g_tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self notificationSetting];
    if (_chatToGroup.groupMessage.count > 0) {
        if([self isMovingToParentViewController]){
            [self TableViewReloadData];
        }
    }
    _g_isCurrentPresentView = YES;
    
    SGroupMessageDB *groupMessagedb = [[SGroupMessageDB alloc] init];
    [groupMessagedb mergeNotReadMessageToReadMessageWithGid:_chatToGroup.groupId WithContactUid:_hostMember.memberId];
    [groupMessagedb close];
    _hostMember.messageNotReadCount = _hostMember.messageNotReadCount-_chatToGroup.messageNotReadCount;
    _chatToGroup.messageNotReadCount = 0;
}

- (void)viewWillDisappear:(BOOL)animated

{
    [super viewWillDisappear:animated];
    _g_isCurrentPresentView = NO;
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

-(void)navigationTitleValue:(NSString *)title
{
    self.navigationItem.title = title;
}

#pragma mark 给数据源增加内容
- (void)addMessage:(GroupMessage *)msg{
    
    GroupMessageFrame *mf = [[GroupMessageFrame alloc] init];
    if (_chatToGroup.groupMessage.count > 0) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        GroupMessage *previousMsg = [_chatToGroup.groupMessage objectAtIndex:_chatToGroup.groupMessage.count-1];
        NSDate *previousTime = [fmt dateFromString:previousMsg.time];
        NSDate *messageDate = [fmt dateFromString:msg.time];
        NSTimeInterval i = [messageDate timeIntervalSinceDate:previousTime];
        mf.showTime = i>SHOWMSGBETWEENTIME?true:false;
    }else
    {
        mf.showTime = true;
    }
    mf.message = msg;
    mf.hostMemberId = _chatToGroup.belongMemberId;
    
    [_chatToGroup.groupMessage addObject:msg];
    [_allGroupMessagesFrame addObject:mf];
    
    SGroupMessageDB *msgdb = [[SGroupMessageDB alloc] init];
    if ([msg isValidate]) {
        [msgdb saveGroupMessage:msg WithContactUid:_hostMember.memberId];
        _chatToGroup.isSession = 1;
        SGroupDB *groupdb = [[SGroupDB alloc] init];
        [groupdb mergeGroup:_chatToGroup];
        [groupdb close];
    }
    [msgdb close];
    
    [self performSelectorOnMainThread:@selector(TableViewReloadData) withObject:nil waitUntilDone:NO];
}

-(void)addSendGroupMessageToTableView:(NSNotification *)notification
{
    NSDictionary *dic = [notification object];
    NSInteger retcode = [[dic valueForKey:@"retcode"] integerValue];
    NSInteger msgsn = [[dic valueForKey:@"msgsn"] integerValue];
    NSLog(@"%ld, %ld",(long)retcode,(long)msgsn);
    if (msgsn < _chatToGroup.groupMessage.count) {
        GroupMessage *message = [_chatToGroup.groupMessage objectAtIndex:msgsn];
        if (message.state == MessageIsSend) {
            if (retcode == 0) {
                message.state = MessageSuccess;
            }else{
                message.state = MessageFailed;
            }
            [self updateGroupMessageStateWithMessage:message];
        }
    }
}

-(void)updateGroupMessageStateWithMessage:(GroupMessage *)message
{
    SGroupMessageDB *msgdb = [[SGroupMessageDB alloc] init];
    if ([message isValidate]) {
        [msgdb mergeGroupMessage:message WithContactUid:_hostMember.memberId];
    }
    [msgdb close];
    [self performSelectorOnMainThread:@selector(TableViewReloadData) withObject:nil waitUntilDone:NO];

}

-(void)TableViewReloadData
{
    [self.g_tableView reloadData];
    [self tableViewscrollToBottom];
}

-(void)tableViewscrollToBottom
{
    //滚动至当前行
    if (_allGroupMessagesFrame.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_allGroupMessagesFrame.count - 1 inSection:0];
        [self.g_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - tableView数据源方法

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _allGroupMessagesFrame.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%ld",(long)indexPath.row];
    GroupMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    GroupMessage *message = [_chatToGroup.groupMessage objectAtIndex:indexPath.row];
    if (cell == nil) {
        cell = [[GroupMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                //Data processing
                dispatch_async(dispatch_get_main_queue(), ^{
                    //Update Interface
                    // 设置数据
                    cell.messageFrame = _allGroupMessagesFrame[indexPath.row];
                    if (message.code == MessageCodeGroupText) {
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
    
    return [_allGroupMessagesFrame[indexPath.row] cellHeight];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - 代理方法

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GROUPSCROLLDRAGGING" object:nil];
}

-(void)tapTableView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GROUPSCROLLDRAGGING" object:nil];
}

-(void)onSelect:(UIView*)sender{
    int n = sender.tag;
    GroupMessage *msg=[_chatToGroup.groupMessage objectAtIndex:n];
    
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
    GroupMessage *msg=[_chatToGroup.groupMessage objectAtIndex:n];
    GroupMember *groupMember = nil;
    for(GroupMember *gMember in _chatToGroup.groupMember)
    {
        if (gMember.memberId == msg.memberId) {
            groupMember = gMember;
            break;
        }
    }
    
    if (groupMember == nil) {
        groupMember = [self requestGroupMemberWithUid:msg.memberId WithGid:msg.belongGroupId];
    }
    [self pushMemberInfoWithGroupMember:groupMember];
}

-(void)pushMemberInfoWithGroupMember:(GroupMember *)gMember
{
    if (gMember != nil) {
        SFriendDB *frienddb = [[SFriendDB alloc] init];
        Member *member = [frienddb selectUserWithUid:gMember.memberId WithBelongUid:_hostMember.memberId];
        if (member != nil) {
            [self pushToGroupMemberInfoDisplayViewControllerWithMember:member];
        }else{
            member = [ModelConvert groupMemberConvertToMember:gMember];
            if (member != nil) {
                [self pushToMemberDetailViewControllerWithMember:member WithHost:_hostMember];
            }
        }
    }
}

-(void)pushToGroupMemberInfoDisplayViewControllerWithMember:(Member *)member
{
    if (member != nil) {
        GroupMemberInfoDisplayViewController *groupMemberInfoDisplayVC = [[GroupMemberInfoDisplayViewController alloc] initWithMember:member];
        HomeViewController *homeVC = [[CommonUtil appDelegate] returnHomeViewController];
        groupMemberInfoDisplayVC.delegate = homeVC;
        [self.navigationController pushViewController:groupMemberInfoDisplayVC animated:YES];
    }
}

-(void)pushToMemberDetailViewControllerWithMember:(Member *)member WithHost:(Member *)host
{
    MemberDetailViewController *memberDetailVC = [[MemberDetailViewController alloc] initWithHost:host WithAddMember:member];
    [self.navigationController pushViewController:memberDetailVC animated:YES];
}

-(GroupMember *)requestGroupMemberWithUid:(unsigned)uid WithGid:(unsigned)gid
{
    GroupMember *member = nil;
    NSString *urlStr = [NSString stringWithFormat:@"%@/YiXin/GetUserById?userid=%u",BASEURL,uid];
    ASIFormDataRequest *request=[ASIFormDataRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        NSLog(@"%@",request.responseString);
        NSDictionary *rootDic=[request.responseString objectFromJSONString];
        int code=[[rootDic objectForKey:@"Code"]intValue];
        if (code==1) {
            NSDictionary *dic = [rootDic objectForKey:@"Data"];
            member = [[GroupMember alloc] init];
            member.groupId = gid;
            member.memberId = [[dic objectForKey:@"Yu_id"] unsignedIntValue];
            member.nickName = [dic objectForKey:@"Yu_NickName"];
            member.headImage = [member groupMemberHeadImageAbsoluteUrlString:[dic objectForKey:@"Yu_HeadPic"]];
            member.loginName = [dic objectForKey:@"Yu_LoginName"];
        }
        else{
            
        }
    }
    
    return member;
}

-(void)recordPlay:(GroupMessage*)msg{
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
        g_audioPlayer = [VoicePlayDevice shareInstanceWithFilePath:wavPath];
        [g_audioPlayer setVolume:1];
        [g_audioPlayer prepareToPlay];
        [g_audioPlayer setDelegate:self];
        [g_audioPlayer play];
        
        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
        
        [[ChatCacheFileUtil sharedInstance] deleteWithContentPath:wavPath];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
}

-(void)pushToGroupSuperChatInfoView
{
    GroupSuperChatInfoViewController *groupSuperChatInfoVC = [[GroupSuperChatInfoViewController alloc] initWithGroup:_chatToGroup];
    [self.navigationController pushViewController:groupSuperChatInfoVC animated:YES];
}

#pragma GroupChatTableViewControllerDelegate
-(void)pushToHomeViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)pushToHomeViewControllerWithMember:(Member *)member
{
    [self.navigationController popViewControllerAnimated:NO];
    [_delegate pushChatViewControllerWithChatMember:member];
}
@end
