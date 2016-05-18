//
//  GroupChatTableViewCell.h
//  ylmm
//
//  Created by macmini on 14-6-30.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Member;
@interface GroupChatSelectTableViewCell : UITableViewCell

@property(nonatomic) BOOL isSelected;
@property(nonatomic, strong) IBOutlet UIImageView *imgHeadImageView;
@property(nonatomic, strong) IBOutlet UILabel *lblNickName;
@property(nonatomic, strong) IBOutlet UIButton *radioButton;

-(void)setUpCellWithMember:(Member *)member;
@end
