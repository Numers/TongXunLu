//
//  SGroupDB.h
//  ylmm
//
//  Created by macmini on 14-7-1.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"
#import "Group.h"

@interface SGroupDB : NSObject{
    FMDatabase * _db;
}


/**
 * @brief 创建数据库
 */
- (void) createDataBase;
/**
 * @brief 保存一条群组记录
 *
 * @param group 需要保存的群组数据
 */
- (void) saveGroup:(Group *) group;

/**
 * @brief 删除一条群组数据
 *
 * @param group 需要删除的群组
 */
- (void) deleteGroup:(Group *)group;

/**
 * @brief 修改群组的信息
 *
 * @param group 需要修改的群组信息
 */
- (void) mergeGroup:(Group *)group;

-(NSMutableArray *)selectSessionGroupWithBelongUid:(unsigned)belongUid;

-(NSMutableArray *)selectAllGroupWithBelongId:(unsigned)belongUid;

-(Group *)selectGroupWithGid:(unsigned)gid WithBelongUid:(unsigned)belongUid;

-(BOOL)isExistGroupWithGid:(unsigned)gid WithBelongUid:(unsigned)belongUid;

-(void)close;
@end
