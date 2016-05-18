//
//  ETNewsViewController.h
//  TongXunLu
//
//  Created by teach on 14-9-1.
//  Copyright (c) 2014年 dhb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICSDrawerController.h"
@class Member;
@interface ETNewsViewController : UITableViewController<ICSDrawerControllerChild, ICSDrawerControllerPresenting>
{
    Member *host;
}

@property(nonatomic, strong) NSMutableArray *newsList;

-(id)initWithHostMember:(Member *)member;
@end
