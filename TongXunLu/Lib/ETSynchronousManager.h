//
//  ETSynchronousManager.h
//  TongXunLu
//
//  Created by macmini on 14-12-9.
//  Copyright (c) 2014年 dhb. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Member;
@interface ETSynchronousManager : NSObject
{
    Member *host;
    NSTimer *timer_Notify;
    NSTimer *timer_Announce;
    NSTimer *timer_Activity;
    NSTimer *timer_News;
}
@property(nonatomic) NSInteger *refreshCount_Notify;
@property(nonatomic) NSInteger *refreshCount_Announce;
@property(nonatomic) NSInteger *refreshCount_Activity;
@property(nonatomic) NSInteger *refreshCount_News;

+(ETSynchronousManager *)defaultManager;
-(void)setUpWithMember:(Member *)member;
-(void)uploadNotify;
-(void)uploadAnnounce;
-(void)uploadActivity;
-(void)uploadNews;
-(void)start;
-(void)stop;
@end
