//
//  GroupChatSelectViewController.m
//  ylmm
//
//  Created by macmini on 14-6-30.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "GroupChatSelectViewController.h"
#import "AppDelegate.h"
#import "GroupChatSelectTableViewCell.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"
#import "CommonUtil.h"

#import "SFriendDB.h"
#import "SGroupDB.h"
#import "Group.h"
#import "GroupMember.h"
#import "GroupMessage.h"
#import "MMProgressHUD.h"

@interface GroupChatSelectViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    BOOL isRegNib;
}
@end

@implementation GroupChatSelectViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithMember:(Member *)member
{
    self = [super init];
    if (self) {
        host = member;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    CGRect frame = [(AppDelegate *)[UIApplication sharedApplication].delegate viewFrame:self.navigationController withTabBarController:self.tabBarController];
    self.tableView.frame = frame;
    [self.view addSubview:self.tableView];
    
    
    _groupMemberList = [[NSMutableArray alloc] init];
    SFriendDB *frienddb = [[SFriendDB alloc] init];
    _friendList = [frienddb selectAllUserWithBelongUid:host.memberId];
    [frienddb close];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    isRegNib = NO;
    [self navigationControllerSetting];
}

-(void)navigationControllerSetting
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)]];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(done)]];
    self.navigationItem.title = @"发起群聊";
    [self navigationControllerRightBarItemEnableSetting];
}

-(void)navigationControllerRightBarItemEnableSetting
{
    if (_groupMemberList.count == 0) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = @"确定";
    }else{
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@"确定(%d)",_groupMemberList.count];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)creatGroup
{
    NSString *users = @"";
    NSInteger i;
    for(i=0;i<_groupMemberList.count;i++){
        Member *member = [_groupMemberList objectAtIndex:i];
        if (member != nil) {
            users = [users stringByAppendingString:[NSString stringWithFormat:@"%u,",member.memberId]];
        }
    }
    users = [users stringByAppendingString:[NSString stringWithFormat:@"%u",host.memberId]];
    NSString *urlStr = [NSString stringWithFormat:@"%@/YiXin/NewGroups?uid=%u&users=%@&vkey=%@",BASEURL,host.memberId,users,[CommonUtil md5WithUid:host.memberId]];
    NSLog(@"%@",urlStr);
    [MMProgressHUD showWithTitle:@"创建群组" status:@"创建中..." ];
    ASIFormDataRequest *request=[ASIFormDataRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [request setCompletionBlock:^{
        NSLog(@"%@",request.responseString);
        NSDictionary *rootDic=[request.responseString objectFromJSONString];
        int code=[[rootDic objectForKey:@"Code"]intValue];
        if (code==1) {
            [MMProgressHUD dismissWithSuccess:@"创建成功" title:@"创建群组" afterDelay:0.75f];
            NSDictionary *dataDic = [rootDic objectForKey:@"Data"];
            Group *group = [[Group alloc] init];
            group.groupId = [[dataDic objectForKey:@"Giid"] unsignedIntValue];
            group.belongMemberId = host.memberId;
            group.groupName =  [dataDic objectForKey:@"Giname"];
            group.groupHeadImage = [group groupHeadImageAbsoluteUrlString:[dataDic objectForKey:@"Giheadpic"]];
            group.isSession = 1;
            group.sessionDate = [[NSDate date] timeIntervalSince1970];
            group.groupOwner = [[dataDic objectForKey:@"Giower"] unsignedIntValue];
            
            NSString *messageContent = [NSString stringWithFormat:@"%@邀请了",host.nickName];
            NSInteger index = 0;
            for(Member *m in _groupMemberList){
                GroupMember *gMember = [[GroupMember alloc] init];
                gMember.groupId = group.groupId;
                gMember.memberId = m.memberId;
                gMember.nickName = m.nickName;
                gMember.loginName = m.loginName;
                gMember.headImage = m.headImage;
                [group.groupMember addObject:gMember];
                
                if (index == _groupMemberList.count-1) {
                    messageContent  = [messageContent stringByAppendingString:[NSString stringWithFormat:@"%@",gMember.nickName]];
                }else{
                    messageContent  = [messageContent stringByAppendingString:[NSString stringWithFormat:@"%@,",gMember.nickName]];
                }
                index++;
            }
            messageContent  = [messageContent stringByAppendingString:@"加入群聊"];
            //添加自己
            GroupMember *gMe = [[GroupMember alloc] init];
            gMe.groupId = group.groupId;
            gMe.memberId = host.memberId;
            gMe.nickName = host.nickName;
            gMe.loginName = host.loginName;
            gMe.headImage = host.headImage;
            [group.groupMember addObject:gMe];
            
            GroupMessage *groupMessage = [[GroupMessage alloc] init];
            groupMessage.belongGroupId = group.groupId;
            groupMessage.memberId = group.groupOwner;
            groupMessage.icon = host.headImage;
            groupMessage.time = [CommonUtil TimeStrWithInterval:group.sessionDate];
            groupMessage.content = messageContent;
            groupMessage.contentType = MessageContentText;
            groupMessage.type = MessageTypeMe;
            groupMessage.code = MessageCodeGroupText;
            groupMessage.state = MessageSuccess;
            groupMessage.readState = MessageNotRead;
            [group.groupMessage addObject:groupMessage];
            group.messageNotReadCount++;
            host.messageNotReadCount++;
            
            SGroupDB *groupdb = [[SGroupDB alloc] init];
            Group *g = [groupdb selectGroupWithGid:group.groupId WithBelongUid:host.memberId];
            if (g == nil){
                if ([group isValidate]) {
                    if (![groupdb isExistGroupWithGid:group.groupId WithBelongUid:group.belongMemberId]) {
                        [groupdb saveGroup:group];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ACCEPTGROUP" object:group userInfo:nil];
                    }
                }
            }
            [self dismissViewControllerAnimated:YES completion:nil];

        }
        else{
            
        }
        
    }];
    [request setFailedBlock:^{
        
    }];
    [request startAsynchronous];
    
}

#pragma tableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _friendList.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"GroupChatSelectTableViewCell";
    if (!isRegNib) {
        [tableView registerNib:[UINib nibWithNibName:@"GroupChatSelectTableViewCell" bundle:nil] forCellReuseIdentifier:identifier];
        isRegNib = YES;
    }
    
    GroupChatSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[GroupChatSelectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            //Data processing
            Member *member = (Member *)[_friendList objectAtIndex:indexPath.row];
            dispatch_async(dispatch_get_main_queue(), ^{
                //Update Interface
                [cell setUpCellWithMember:member];
                cell.isSelected = NO;
            });
        }
    });
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GroupChatSelectTableViewCell *cell = (GroupChatSelectTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    Member *member = [_friendList objectAtIndex:indexPath.row];
    if (cell.isSelected) {
        cell.isSelected = NO;
        [_groupMemberList removeObject:member];
    }else{
        cell.isSelected = YES;
        [_groupMemberList addObject:member];
    }
    [self navigationControllerRightBarItemEnableSetting];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 63.0f;
}

#pragma Event
-(void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)done
{
    if (_groupMemberList.count == 1) {
        [self dismissViewControllerAnimated:YES completion:^{
            Member *m = [_groupMemberList objectAtIndex:0];
            [self.delegate pushChatViewControllerWithChatMember:m];
        }];
    }else{
        [self creatGroup];
    }
}
@end
