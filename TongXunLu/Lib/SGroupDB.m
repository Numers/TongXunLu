//
//  SGroupDB.m
//  ylmm
//
//  Created by macmini on 14-7-1.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "SGroupDB.h"
#import "SGroupMessageDB.h"
#import "SGroupMemberDB.h"
#define kGroupTableName @"SGroup"

@implementation SGroupDB
- (id) init {
    self = [super init];
    if (self) {
        //========== 首先查看有没有建立message的数据库，如果未建立，则建立数据库=========
        _db = [SDBManager defaultDBManager].dataBase;
        
    }
    return self;
}

/**
 * @brief 创建数据库
 */
- (void) createDataBase
{
    FMResultSet * set = [_db executeQuery:[NSString stringWithFormat:@"select count(*) from sqlite_master where type ='table' and name = '%@'",kGroupTableName]];
    
    [set next];
    
    NSInteger count = [set intForColumnIndex:0];
    
    BOOL existTable = !!count;
    
    if (existTable) {
        // TODO:是否更新数据库
        NSLog(@"数据库已经存在");
    } else {
        // TODO: 插入新的数据库
        NSString * sql = @"CREATE TABLE SGroup (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, groupid INTEGER,belongmemberid INTEGER, groupname VARCHAR(50),groupheadimage VARCHAR(50),isSession INTEGER,sessiondate TIMESTAMP, groupowner INTEGER)";
        BOOL res = [_db executeUpdate:sql];
        if (!res) {
            NSLog(@"%@数据库创建失败",kGroupTableName);
        } else {
            NSLog(@"%@数据库创建成功",kGroupTableName);
        }
    }
}
/**
 * @brief 保存一条群组记录
 *
 * @param group 需要保存的群组数据
 */
- (void) saveGroup:(Group *) group
{
    NSMutableString * query = [NSMutableString stringWithFormat:@"INSERT INTO SGroup"];
    NSMutableString * keys = [NSMutableString stringWithFormat:@" ("];
    NSMutableString * values = [NSMutableString stringWithFormat:@" ( "];
    NSMutableArray * arguments = [NSMutableArray arrayWithCapacity:3];
    
    if (group.groupId) {
        [keys appendString:@"groupid,"];
        [values appendString:@"?,"];
        [arguments addObject:[NSString stringWithFormat:@"%u",group.groupId]];
    }
    
    if (group.belongMemberId) {
        [keys appendString:@"belongmemberid,"];
        [values appendString:@"?,"];
        [arguments addObject:[NSString stringWithFormat:@"%u",group.belongMemberId]];
    }
    
    if (group.groupName) {
        [keys appendString:@"groupname,"];
        [values appendString:@"?,"];
        [arguments addObject:group.groupName];
    }
    
    if (group.sessionDate) {
        [keys appendString:@"sessiondate,"];
        [values appendString:@"?,"];
        [arguments addObject:[NSString stringWithFormat:@"%lf",group.sessionDate]];
    }
    
    if (group.groupHeadImage) {
        [keys appendString:@"groupheadimage,"];
        [values appendString:@"?,"];
        [arguments addObject:group.groupHeadImage];
    }
    
    if (group.groupOwner) {
        [keys appendString:@"groupowner,"];
        [values appendString:@"?,"];
        [arguments addObject:[NSString stringWithFormat:@"%u",group.groupOwner]];
    }
    
    [keys appendString:@"isSession,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%u",group.isSession]];

    [keys appendString:@")"];
    [values appendString:@")"];
    [query appendFormat:@" %@ VALUES%@",
     [keys stringByReplacingOccurrencesOfString:@",)" withString:@")"],
     [values stringByReplacingOccurrencesOfString:@",)" withString:@")"]];
    NSLog(@"%@",query);
    NSLog(@"插入一条数据");
    [_db executeUpdate:query withArgumentsInArray:arguments];
    
    if (group.groupMember.count > 2) {
        SGroupMemberDB *groupMemberdb = [[SGroupMemberDB alloc] init];
        for(GroupMember *gm in group.groupMember){
            if (![groupMemberdb isExistGroupMemberWithUid:gm.memberId WithGid:gm.groupId]) {
                [groupMemberdb saveGroupMember:gm];
            }
        }
        [groupMemberdb close];
    }
    
    if (group.groupMessage.count > 0) {
        SGroupMessageDB *groupMessagedb = [[SGroupMessageDB alloc] init];
        for(GroupMessage *gmsg in group.groupMessage){
            [groupMessagedb saveGroupMessage:gmsg WithContactUid:group.belongMemberId];
        }
        [groupMessagedb close];
    }
}

/**
 * @brief 删除一条群组数据
 *
 * @param group 需要删除的群组
 */
- (void) deleteGroup:(Group *)group
{
    NSString * query = [NSString stringWithFormat:@"DELETE FROM SGroup WHERE groupid = '%u' and belongmemberid = '%u'",group.groupId,group.belongMemberId];
    NSLog(@"删除一条数据");
    [_db executeUpdate:query];
    
    if (group.groupMember.count > 0) {
        SGroupMemberDB *groupMemberdb = [[SGroupMemberDB alloc] init];
        for(GroupMember *gm in group.groupMember){
            [groupMemberdb deleteGroupMember:gm];
        }
        [groupMemberdb close];
    }
    
    if (group.groupMessage.count > 0) {
        SGroupMessageDB *groupMessagedb = [[SGroupMessageDB alloc] init];
        [groupMessagedb deleteGroupMessageWithGid:group.groupId WithContactUid:group.belongMemberId];
        [groupMessagedb close];
    }

}

/**
 * @brief 修改群组的信息
 *
 * @param group 需要修改的群组信息
 */
- (void) mergeGroup:(Group *)group
{
    NSString * query = @"UPDATE SGroup SET";
    NSMutableString * temp = [NSMutableString stringWithCapacity:100];
    // xxx = xxx;
    if (group.groupName) {
        [temp appendFormat:@" groupname = '%@',",group.groupName];
    }
    
    if (group.sessionDate) {
        [temp appendFormat:@" sessiondate = '%lf',",group.sessionDate];
    }
    
    if (group.groupHeadImage) {
        [temp appendFormat:@" groupheadimage = '%@',",group.groupHeadImage];
    }
    
    [temp appendFormat:@" isSession = '%@',",[NSString stringWithFormat:@"%u",group.isSession]];

    [temp appendString:@")"];
    query = [query stringByAppendingFormat:@"%@ WHERE groupid = '%u' and belongmemberid = '%u'",[temp stringByReplacingOccurrencesOfString:@",)" withString:@""],group.groupId,group.belongMemberId];
    NSLog(@"%@",query);
    NSLog(@"修改一条数据");
    [_db executeUpdate:query];

}

-(NSMutableArray *)selectSessionGroupWithBelongUid:(unsigned)belongUid
{
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM SGroup WHERE isSession = 1 and belongmemberid = '%u' ORDER BY sessiondate DESC",belongUid];
    FMResultSet * rs = [_db executeQuery:query];
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:[rs columnCount]];
	while ([rs next]) {
        Group *group = [[Group alloc] init];
        group.groupId = [rs intForColumn:@"groupid"];
        group.belongMemberId = [rs intForColumn:@"belongmemberid"];
        group.groupName = [rs stringForColumn:@"groupname"];
        group.isSession = [rs intForColumn:@"isSession"];
        group.sessionDate = [rs doubleForColumn:@"sessiondate"];
        group.groupHeadImage = [rs stringForColumn:@"groupheadimage"];
        group.groupOwner = [rs intForColumn:@"groupowner"];
        SGroupMemberDB *groupMemberdb = [[SGroupMemberDB alloc] init];
        group.groupMember = [groupMemberdb selectAllGroupMemberWithGid:group.groupId];
        [groupMemberdb close];
        SGroupMessageDB *groupMessagedb = [[SGroupMessageDB alloc] init];
        group.groupMessage = [groupMessagedb selectGroupMessageWithGid:group.groupId WithContactUid:belongUid];
        group.messageNotReadCount = [groupMessagedb selectNotReadMessageCountWithGid:group.groupId WithContactUid:belongUid];
        [groupMessagedb close];
        if ([group isValidate]) {
            [array addObject:group];
        }
	}
	[rs close];
    return array;

}

-(NSMutableArray *)selectAllGroupWithBelongId:(unsigned)belongUid
{
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM SGroup WHERE belongmemberid = '%u' ORDER BY id DESC",belongUid];
    FMResultSet * rs = [_db executeQuery:query];
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:[rs columnCount]];
	while ([rs next]) {
        Group *group = [[Group alloc] init];
        group.groupId = [rs intForColumn:@"groupid"];
        group.belongMemberId = [rs intForColumn:@"belongmemberid"];
        group.groupName = [rs stringForColumn:@"groupname"];
        group.isSession = [rs intForColumn:@"isSession"];
        group.sessionDate = [rs doubleForColumn:@"sessiondate"];
        group.groupHeadImage = [rs stringForColumn:@"groupheadimage"];
        group.groupOwner = [rs intForColumn:@"groupowner"];
        SGroupMemberDB *groupMemberdb = [[SGroupMemberDB alloc] init];
        group.groupMember = [groupMemberdb selectAllGroupMemberWithGid:group.groupId];
        [groupMemberdb close];
        SGroupMessageDB *groupMessagedb = [[SGroupMessageDB alloc] init];
        group.groupMessage = [groupMessagedb selectGroupMessageWithGid:group.groupId WithContactUid:belongUid];
        group.messageNotReadCount = [groupMessagedb selectNotReadMessageCountWithGid:group.groupId WithContactUid:belongUid];
        [groupMessagedb close];
        if ([group isValidate]) {
            [array addObject:group];
        }
	}
	[rs close];
    return array;
}

-(Group *)selectGroupWithGid:(unsigned)gid WithBelongUid:(unsigned)belongUid
{
    Group *group = nil;
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM SGroup WHERE groupid = '%u' and belongmemberid = '%u'",gid,belongUid];
    FMResultSet * rs = [_db executeQuery:query];
    if ([rs next]) {
        group = [[Group alloc] init];
        group.groupId = [rs intForColumn:@"groupid"];
        group.belongMemberId = [rs intForColumn:@"belongmemberid"];
        group.groupName = [rs stringForColumn:@"groupname"];
        group.isSession = [rs intForColumn:@"isSession"];
        group.sessionDate = [rs doubleForColumn:@"sessiondate"];
        group.groupHeadImage = [rs stringForColumn:@"groupheadimage"];
        group.groupOwner = [rs intForColumn:@"groupowner"];
        SGroupMemberDB *groupMemberdb = [[SGroupMemberDB alloc] init];
        group.groupMember = [groupMemberdb selectAllGroupMemberWithGid:group.groupId];
        [groupMemberdb close];
        SGroupMessageDB *groupMessagedb = [[SGroupMessageDB alloc] init];
        group.groupMessage = [groupMessagedb selectGroupMessageWithGid:group.groupId WithContactUid:belongUid];
        group.messageNotReadCount = [groupMessagedb selectNotReadMessageCountWithGid:group.groupId WithContactUid:belongUid];
        [groupMessagedb close];
    }
	[rs close];
    return group;
}

-(BOOL)isExistGroupWithGid:(unsigned)gid WithBelongUid:(unsigned)belongUid
{
    NSString * query =[NSString stringWithFormat:@"SELECT * FROM SGroup WHERE groupid = '%u' and belongmemberid = '%u'",gid,belongUid];
    FMResultSet * rs = [_db executeQuery:query];
    BOOL isExist =  rs.next;
    [rs close];
    return isExist;
}

-(void)close
{
    //[[SDBManager defaultDBManager] close];;
}
@end
