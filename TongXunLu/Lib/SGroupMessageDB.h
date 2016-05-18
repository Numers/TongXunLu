//
//  SGroupMessageDB.h
//  ylmm
//
//  Created by macmini on 14-7-1.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"
#import "GroupMessage.h"

@interface SGroupMessageDB : NSObject{
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
 * @param otherUid 消息的从属otherUid
 */
- (void)saveGroupMessage:(GroupMessage *) message WithContactUid:(unsigned)otherUid;

-(void)deleteGroupMessageWithGid:(unsigned)gid WithContactUid:(unsigned)otherUid;

- (void) mergeGroupMessage:(GroupMessage *)message WithContactUid:(unsigned)otherUid;

-(void)mergeNotReadMessageToReadMessageWithGid:(unsigned)gid WithContactUid:(unsigned)otherUid;

-(NSMutableArray *)selectGroupMessageWithGid:(unsigned)gid WithContactUid:(unsigned)otherUid;

-(NSMutableArray *)selectImageGroupMessageWithGid:(unsigned)gid WithContactUid:(unsigned)otherUid;

-(NSInteger)selectNotReadMessageCountWithGid:(unsigned)gid WithContactUid:(unsigned)otherUid;
-(NSInteger)selectNotReadMessageCountWithContactUid:(unsigned)uid;

-(void)close;

@end
