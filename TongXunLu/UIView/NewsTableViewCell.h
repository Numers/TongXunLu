//
//  ActivityTableViewCell.h
//  TongXunLu
//
//  Created by teach on 14-8-31.
//  Copyright (c) 2014年 dhb. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Activity;
@interface ActivityTableViewCell : UITableViewCell
@property(nonatomic, strong) IBOutlet UILabel *lblTitle;
@property(nonatomic, strong) IBOutlet UILabel *lblPublishTime;
@property(nonatomic, strong) IBOutlet UILabel *lblContent;
@property(nonatomic, strong) IBOutlet UIImageView *imgNewActivity;

-(void)setUpCellWithActivity:(Activity *)activity;
@end
