//
//  Message.h
//  15-QQ聊天布局
//
//  Created by Liu Feng on 13-12-3.
//  Copyright (c) 2013年 Liu Feng. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    
    MessageTypeMe = 0, // 自己发的
    MessageTypeOther = 1 //别人发得
    
} MessageType;

typedef enum {
    MessageCodeText = 1,//文本
    MessageCodeAddFriend = 10,//添加好友
    MessageCodeAcceptFriend = 11,//接受好友请求
    MessageCodeRemoveFriend = 12,//移除好友
    MessageCodeGroupText = 2,//群消息
//    MessageCodeAddGroupMember = 13,//添加群组成员
//    MessageCodeRemoveGroupMember = 14//移除群组成员
} MessageCode;

typedef enum {
    
    MessageSuccess = 1, //发送或接收成功
    MessageFailed = 0, //发送或接收失败
    MessageIsSend = 2 //正在发送
    
} MessageState;

typedef enum {
    
    MessageRead = 0, // 已读
    MessageNotRead = 1 //未读
    
} MessageReadState;

typedef enum {
    
    MessageContentText = 0, // 消息是文本内容
    MessageContentVoice = 1, //消息是语音
    MessageContentImage = 2, //消息是图片
    MessageContentRemoveGroupMember = 3,//移除群组成员
    MessageContentCreateGroup = 4,//创建群
    MessageContentMergeGroupName = 5,//修改群名称
    MessageContentAddGroupMember = 6,//添加群组成员
    MessageContentRedPacket = 8//发红包
} MessageContentType;

@interface Message : NSObject

@property(nonatomic) unsigned memberId; //所属的成员
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, copy) NSString *content;//文本
@property (nonatomic) MessageContentType contentType;//文本类型

@property (nonatomic, assign) MessageType type;
@property (nonatomic, assign) MessageCode code;
@property (nonatomic) MessageState state;
@property (nonatomic) MessageReadState readState;


@property (nonatomic, copy) NSDictionary *dict;


-(BOOL)isValidate;
-(NSString *)fullPathString:(NSString *)absolutePath;
//-(MessageContentType)messageContentType;
-(NSString *)fulltThumbnailsPath;
-(NSString *)fullServerImagePath;
@end
