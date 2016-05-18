//
//  GroupChatSelectViewController.h
//  ylmm
//
//  Created by macmini on 14-6-30.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "protocal.h"
@class Member;
@interface GroupChatSelectViewController : UIViewController
{
    Member *host;
}
@property(nonatomic, strong) NSArray *friendList;
@property(nonatomic, strong) NSMutableArray *groupMemberList;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, assign) id<HomeViewDelegate> delegate;

-(id)initWithMember:(Member *)member;
@end
