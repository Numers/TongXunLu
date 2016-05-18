//
//  GroupChatTableViewCell.m
//  ylmm
//
//  Created by macmini on 14-6-30.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "GroupChatSelectTableViewCell.h"
#import "Member.h"
#import "UIImageView+WebCache.h"

@implementation GroupChatSelectTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

-(void)setUpCellWithMember:(Member *)member
{
    if (_imgHeadImageView == nil) {
        _imgHeadImageView = [[UIImageView alloc] init];
    }
    [_imgHeadImageView setImageWithURL:[NSURL URLWithString:member.headImage] placeholderImage:[UIImage imageNamed:@"Download_Fail@2x.png"]];
    
    if (_lblNickName == nil) {
        _lblNickName = [[UILabel alloc] init];
    }
    [_lblNickName setText:member.nickName];
    
    if (_radioButton == nil) {
        _radioButton = [[UIButton alloc] init];
    }
    
    if (_isSelected) {
        [_radioButton setImage:[UIImage imageNamed:@"CellBlueSelected@2x.png"] forState:UIControlStateNormal];
    }else{
        [_radioButton setImage:[UIImage imageNamed:@"CellNotSelected@2x.png"] forState:UIControlStateNormal];
    }

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setIsSelected:(BOOL)isSelected
{
    if (isSelected) {
        [_radioButton setImage:[UIImage imageNamed:@"CellBlueSelected@2x.png"] forState:UIControlStateNormal];
    }else{
        [_radioButton setImage:[UIImage imageNamed:@"CellNotSelected@2x.png"] forState:UIControlStateNormal];
    }
    _isSelected = isSelected;
}

@end
