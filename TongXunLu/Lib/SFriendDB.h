//
//  SFriendDB.h
//  ylmm
//
//  Created by macmini on 14-6-11.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"
#import "Member.h"

@interface SFriendDB : NSObject{
    FMDatabase * _db;
}

/**
 * @brief 创建数据库
 */
- (void) createDataBase;
/**
 * @brief 保存一条用户记录
 *
 * @param user 需要保存的用户数据
 */
- (void) saveUser:(Member *) user WithBelongUid:(unsigned)belongUid;

/**
 * @brief 删除一条用户数据
 *
 * @param uid 需要删除的用户的id
 */
- (void) deleteUserWithId:(unsigned) uid WithBelongUid:(unsigned)belongUid;

/**
 * @brief 修改用户的信息
 *
 * @param user 需要修改的用户信息
 */
- (void) mergeWithUser:(Member *) user WithBelongUid:(unsigned)belongUid;

-(NSArray *)selectSessionUserWithBelongUid:(unsigned)belongUid;

-(NSArray *)selectAllUserWithBelongUid:(unsigned)belongUid;

-(Member *)selectUserWithUid:(unsigned)uid WithBelongUid:(unsigned)belongUid;

-(BOOL)isExistMemberWithUid:(unsigned)uid WithBelongUid:(unsigned)belongUid;

-(void)close;
@end
