//
//  ActivityTableViewCell.m
//  TongXunLu
//
//  Created by teach on 14-8-31.
//  Copyright (c) 2014年 dhb. All rights reserved.
//

#import "ActivityTableViewCell.h"
#import "Activity.h"

@implementation ActivityTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setUpCellWithActivity:(Activity *)activity
{
    _lblTitle.text = activity.title;
    _lblContent.text = activity.content;
    _lblPublishTime.text = activity.publicTime;
    if (activity.readState == ActivityUnRead) {
        [_imgNewActivity setHidden:NO];
    }else{
        [_imgNewActivity setHidden:YES];
    }
}

@end
