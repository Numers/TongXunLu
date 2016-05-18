//
//  SMessageDB.h
//  ylmm
//
//  Created by macmini on 14-6-6.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"
#import "Message.h"

@interface SMessageDB : NSObject{
    FMDatabase * _db;
}
/**
 * @brief 创建数据库
 */
- (void) createDataBase;
/**
 * @brief 保存一条用户记录
 *
 * @param Message 需要保存的用户数据
 * @param uid 消息的从属uid
 */
- (void)saveMessage:(Message *) message WithUid:(unsigned)uid WithContactUid:(unsigned)otherUid;

-(void)deleteMessageWithUid:(unsigned)uid WithContactUid:(unsigned)otherUid;

- (void) mergeMessage:(Message *)message WithUid:(unsigned)uid WithContactUid:(unsigned)otherUid;

-(void)mergeNotReadMessageToReadMessageWithUid:(unsigned)uid WithContactUid:(unsigned)otherUid;

-(NSMutableArray *)selectMessageWithUid:(unsigned)uid WithContactUid:(unsigned)otherUid;

-(NSMutableArray *)selectImageMessageWithUid:(unsigned)uid WithContactUid:(unsigned)otherUid;

-(NSInteger)selectNotReadMessageCountWithUid:(unsigned)uid WithContactUid:(unsigned)otherUid;
-(NSInteger)selectNotReadMessageCountWithContactUid:(unsigned)uid;

-(void)close;
@end
