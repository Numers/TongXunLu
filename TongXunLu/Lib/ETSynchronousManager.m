//
//  ETSynchronousManager.m
//  TongXunLu
//
//  Created by macmini on 14-12-9.
//  Copyright (c) 2014年 dhb. All rights reserved.
//

#import "ETSynchronousManager.h"
#import "SNotifyDB.h"
#import "SAnnounceDB.h"
#import "SActivityDB.h"
#import "SNewsDB.h"

#import "Member.h"

#import "ASIFormDataRequest.h"
#import "JSONKit.h"
#import "CommonUtil.h"
static ETSynchronousManager *etSyschrounousManager;
@implementation ETSynchronousManager
+(ETSynchronousManager *)defaultManager
{
    if (etSyschrounousManager == nil) {
        etSyschrounousManager = [[ETSynchronousManager alloc] init];
    }
    return etSyschrounousManager;
}

-(void)start
{
    timer_Notify = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(uploadNotify) userInfo:nil repeats:YES];
    [timer_Notify fire];
    
    timer_Announce = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(uploadAnnounce) userInfo:nil repeats:YES];
    [timer_Announce fire];
    
    timer_Activity = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(uploadActivity) userInfo:nil repeats:YES];
    [timer_Activity fire];
    
    timer_News = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(uploadNews) userInfo:nil repeats:YES];
    [timer_News fire];
}

-(void)stop
{
    [timer_Notify invalidate];
    timer_Notify = nil;
    
    [timer_Announce invalidate];
    timer_Announce = nil;
    
    [timer_Activity invalidate];
    timer_Activity = nil;
    
    [timer_News invalidate];
    timer_News = nil;
}

-(void)setUpWithMember:(Member *)member
{
    host = member;
    _refreshCount_Activity = 0;
    _refreshCount_Announce = 0;
    _refreshCount_News = 0;
    _refreshCount_Notify = 0;
}

-(void)setRefreshCount_Activity:(NSInteger *)refreshCount_Activity
{
    _refreshCount_Activity = refreshCount_Activity;
    [self uploadActivity];
}

-(void)setRefreshCount_Announce:(NSInteger *)refreshCount_Announce
{
    _refreshCount_Announce = refreshCount_Announce;
    [self uploadAnnounce];
}

-(void)setRefreshCount_News:(NSInteger *)refreshCount_News
{
    _refreshCount_News = refreshCount_News;
    [self uploadNews];
}

-(void)setRefreshCount_Notify:(NSInteger *)refreshCount_Notify
{
    _refreshCount_Notify = refreshCount_Notify;
    [self uploadNotify];
}

-(void)uploadNotify
{
    SNotifyDB *notifydb = [[SNotifyDB alloc] init];
    if (_refreshCount_Notify == 0) {
        [notifydb deleteNotifyWithBelongUid:host.userId];
    }
    _refreshCount_Notify ++;
    NSInteger from = [notifydb selectNotifyCountWithBelongUid:host.userId];
    NSString *url = [NSString stringWithFormat:@"%@?userid=%@&password=%@&from=%u&size=10&label=通知&group_name=%@&device=%@",KMY_Notify_And_Announcement_BaseLink,host.userId,host.userPsd,from,host.groupName,DeviceUUID];
    NSString *encodedUrl = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:encodedUrl]];
    [request setTimeOutSeconds:15];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        NSString *responseStr = [request responseString];
        NSDictionary *dic = [responseStr objectFromJSONString];
        NSDictionary *resultDic = [dic objectForKey:@"result"];
        NSInteger code = [[resultDic objectForKey:@"code"] integerValue];
        if (code == 100) {
            NSDictionary *dataDic = [dic objectForKey:@"data"];
            NSArray *dataArr = [dataDic objectForKey:@"array"];
            SNotifyDB *notifydb = [[SNotifyDB alloc] init];
            @try {
                for (id m in dataArr) {
                    Notify *notify = [[Notify alloc] init];
                    notify.publicTime = [m objectForKey:@"publishTime"];
                    notify.title = [m objectForKey:@"title"];
                    notify.messageId = [m objectForKey:@"messageId"];
                    notify.content = [m objectForKey:@"content"];
                    notify.readState = [[m objectForKey:@"isread"] boolValue];
                    if (![notifydb isExistNotifyWithMessageId:notify.messageId WithBelongUid:host.userId]) {
                        [notifydb saveNotify:notify WithBelongUid:host.userId];
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@",exception.description);
            }
            @finally {
                
            }
            [notifydb close];
        }else{
            NSLog(@"加载失败...");
        }
    }else{
        NSLog(@"网络错误");
    }
}

-(void)uploadAnnounce
{
    SAnnounceDB *announcedb = [[SAnnounceDB alloc] init];
    if (_refreshCount_Announce == 0) {
        [announcedb deleteAnnouncementWithBelongUid:host.userId];
    }
    _refreshCount_Announce ++;
    NSInteger from = [announcedb selectAnnouncementCountWithBelongUid:host.userId];
    NSString *url = [NSString stringWithFormat:@"%@?userid=%@&password=%@&from=%u&size=10&label=公告&group_name=%@&device=%@",KMY_Notify_And_Announcement_BaseLink,host.userId,host.userPsd,from,host.groupName,DeviceUUID];
    NSString *encodedUrl = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:encodedUrl]];
    [request setTimeOutSeconds:15];
    [request setCompletionBlock:^{
        NSString *responseStr = [request responseString];
        NSDictionary *dic = [responseStr objectFromJSONString];
        NSDictionary *resultDic = [dic objectForKey:@"result"];
        NSInteger code = [[resultDic objectForKey:@"code"] integerValue];
        if (code == 100) {
            NSDictionary *dataDic = [dic objectForKey:@"data"];
            NSArray *dataArr = [dataDic objectForKey:@"array"];
            @try {
                for (id m in dataArr) {
                    Announcement *announcement = [[Announcement alloc] init];
                    announcement.publicTime = [m objectForKey:@"publishTime"];
                    announcement.title = [m objectForKey:@"title"];
                    announcement.messageId = [m objectForKey:@"messageId"];
                    announcement.content = [m objectForKey:@"content"];
                    announcement.readState = [[m objectForKey:@"isread"] boolValue];
                    
                    if (![announcedb isExistAnnouncementWithMessageId:announcement.messageId WithBelongUid:host.userId]) {
                        [announcedb saveAnnouncement:announcement WithBelongUid:host.userId];
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@",exception.description);
            }
            @finally {
                
            }
        }else{
            NSLog(@"加载失败...");
        }
    }];
    [request setFailedBlock:^{
        NSLog(@"网络错误");
    }];
    [request startAsynchronous];
}

-(void)uploadActivity
{
    SActivityDB *activitydb = [[SActivityDB alloc] init];
    if (_refreshCount_Activity == 0) {
        [activitydb deleteActivityWithBelongUid:host.userId];
    }
    _refreshCount_Activity ++;
    NSInteger from = [activitydb selectActivityCountWithBelongUid:host.userId];
    NSString *url = [NSString stringWithFormat:@"%@?userid=%@&password=%@&from=%u&size=10&group_name=%@&device=%@",KMY_Activity_BaseLink,host.userId,host.userPsd,from,host.groupName,DeviceUUID];
    NSString *encodedUrl = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:encodedUrl]];
    [request setTimeOutSeconds:15];
    [request setCompletionBlock:^{
        NSString *responseStr = [request responseString];
        NSDictionary *dic = [responseStr objectFromJSONString];
        NSDictionary *resultDic = [dic objectForKey:@"result"];
        NSInteger code = [[resultDic objectForKey:@"code"] integerValue];
        if (code == 100) {
            NSDictionary *dataDic = [dic objectForKey:@"data"];
            NSArray *dataArr = [dataDic objectForKey:@"array"];
            @try {
                for (id m in dataArr) {
                    Activity *activity = [[Activity alloc] init];
                    activity.startTime = [m objectForKey:@"startTime"];
                    activity.endTime = [m objectForKey:@"endTime"];
                    activity.publicTime = [m objectForKey:@"publishTime"];
                    activity.title = [m objectForKey:@"title"];
                    activity.messageId = [m objectForKey:@"messageId"];
                    activity.content = [m objectForKey:@"content"];
                    activity.readState = [[m objectForKey:@"isread"] boolValue];
                    if (![activitydb isExistActivityWithMessageId:activity.messageId WithBelongUid:host.userId]) {
                        [activitydb saveActivity:activity WithBelongUid:host.userId];
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@",exception.description);
            }
            @finally {
                
            }
        }else{
            NSLog(@"加载失败...");
        }
    }];
    [request setFailedBlock:^{
        NSLog(@"网络错误");
    }];
    [request startAsynchronous];
}

-(void)uploadNews
{
    SNewsDB *newsdb = [[SNewsDB alloc] init];
    if (_refreshCount_News == 0) {
        [newsdb deleteNewsWithBelongUid:host.userId];
    }
    _refreshCount_News ++;
    NSInteger from = [newsdb selectNewsCountWithBelongUid:host.userId];
    NSString *url = [NSString stringWithFormat:@"%@?userid=%@&password=%@&from=%u&size=10&label=新闻&group_name=%@&device=%@",KMY_Notify_And_Announcement_BaseLink,host.userId,host.userPsd,from,host.groupName,DeviceUUID];
    NSString *encodedUrl = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:encodedUrl]];
    [request setTimeOutSeconds:15];
    [request setCompletionBlock:^{
        NSString *responseStr = [request responseString];
        NSDictionary *dic = [responseStr objectFromJSONString];
        NSDictionary *resultDic = [dic objectForKey:@"result"];
        NSInteger code = [[resultDic objectForKey:@"code"] integerValue];
        if (code == 100) {
            NSDictionary *dataDic = [dic objectForKey:@"data"];
            NSArray *dataArr = [dataDic objectForKey:@"array"];
            @try {
                for (id m in dataArr) {
                    News *news = [[News alloc] init];
                    news.publicTime = [m objectForKey:@"publishTime"];
                    news.title = [m objectForKey:@"title"];
                    news.messageId = [m objectForKey:@"messageId"];
                    news.content = [m objectForKey:@"content"];
                    news.readState = [[m objectForKey:@"isread"] boolValue];
                    if (![newsdb isExistNewsWithMessageId:news.messageId WithBelongUid:host.userId]) {
                        [newsdb saveNews:news WithBelongUid:host.userId];
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@",exception.description);
            }
            @finally {
                
            }
        }else{
            NSLog(@"加载失败...");
        }
    }];
    [request setFailedBlock:^{
        NSLog(@"网络错误");
    }];
    [request startAsynchronous];
}
@end
