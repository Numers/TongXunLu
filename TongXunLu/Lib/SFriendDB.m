//
//  SFriendDB.m
//  ylmm
//
//  Created by macmini on 14-6-11.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "SFriendDB.h"
#import "SMessageDB.h"
#define kFriendTableName @"SFriend"
@implementation SFriendDB
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
- (void) createDataBase {
    FMResultSet * set = [_db executeQuery:[NSString stringWithFormat:@"select count(*) from sqlite_master where type ='table' and name = '%@'",kFriendTableName]];
    
    [set next];
    
    NSInteger count = [set intForColumnIndex:0];
    
    BOOL existTable = !!count;
    
    if (existTable) {
        // TODO:是否更新数据库
        NSLog(@"数据库已经存在");
    } else {
        // TODO: 插入新的数据库
        NSString * sql = @"CREATE TABLE SFriend (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, memberid INTEGER,belongmemberid INTEGER,nickname VARCHAR(50),loginname VARCHAR(50), headimage VARCHAR(100), isSession INTEGER,sessiondate TIMESTAMP)";
        BOOL res = [_db executeUpdate:sql];
        if (!res) {
            NSLog(@"%@数据库创建失败",kFriendTableName);
        } else {
            NSLog(@"%@数据库创建成功",kFriendTableName);
        }
    }
}

/**
 * @brief 保存一条用户记录
 *
 * @param user 需要保存的用户数据
 */
- (void) saveUser:(Member *) user WithBelongUid:(unsigned)belongUid{
    NSMutableString * query = [NSMutableString stringWithFormat:@"INSERT INTO SFriend"];
    NSMutableString * keys = [NSMutableString stringWithFormat:@" ("];
    NSMutableString * values = [NSMutableString stringWithFormat:@" ( "];
    NSMutableArray * arguments = [NSMutableArray arrayWithCapacity:7];
    
    [keys appendString:@"belongmemberid,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%u",belongUid]];
    
    [keys appendString:@"isSession,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%u",user.isSession]];
    
    if (user.sessionDate) {
        [keys appendString:@"sessiondate,"];
        [values appendString:@"?,"];
        [arguments addObject:[NSString stringWithFormat:@"%lf",user.sessionDate]];
    }
    
    if (user.memberId) {
        [keys appendString:@"memberid,"];
        [values appendString:@"?,"];
        [arguments addObject:[NSString stringWithFormat:@"%u",user.memberId]];
    }
    
    if (user.nickName) {
        [keys appendString:@"nickname,"];
        [values appendString:@"?,"];
        [arguments addObject:user.nickName];
    }
    
    if (user.loginName) {
        [keys appendString:@"loginname,"];
        [values appendString:@"?,"];
        [arguments addObject:user.loginName];
    }
    
    
    if (user.headImage) {
        [keys appendString:@"headimage,"];
        [values appendString:@"?,"];
        [arguments addObject:user.headImage];
    }
    
    [keys appendString:@")"];
    [values appendString:@")"];
    [query appendFormat:@" %@ VALUES%@",
     [keys stringByReplacingOccurrencesOfString:@",)" withString:@")"],
     [values stringByReplacingOccurrencesOfString:@",)" withString:@")"]];
    NSLog(@"%@",query);
    NSLog(@"插入一条数据");
    [_db executeUpdate:query withArgumentsInArray:arguments];
}

/**
 * @brief 删除一条用户数据
 *
 * @param uid 需要删除的用户的id
 */
- (void) deleteUserWithId:(unsigned) uid WithBelongUid:(unsigned)belongUid{
    NSString * query = [NSString stringWithFormat:@"DELETE FROM SFriend WHERE memberid = '%u' and belongmemberid = '%u'",uid,belongUid];
    NSLog(@"删除一条数据");
    [_db executeUpdate:query];
    
    SMessageDB *msgdb = [[SMessageDB alloc] init];
    [msgdb deleteMessageWithUid:uid WithContactUid:belongUid];
    [msgdb close];
}

/**
 * @brief 修改用户的信息
 *
 * @param user 需要修改的用户信息
 */
- (void) mergeWithUser:(Member *) user WithBelongUid:(unsigned)belongUid{
    if (!user.memberId) {
        return;
    }
    NSString * query = @"UPDATE SFriend SET";
    NSMutableString * temp = [NSMutableString stringWithCapacity:100];
    // xxx = xxx;
    if (user.headImage) {
        [temp appendFormat:@" headimage = '%@',",user.headImage];
    }
    
    if (user.nickName) {
        [temp appendFormat:@" nickname = '%@',",user.nickName];
    }
    
    if (user.loginName) {
        [temp appendFormat:@" loginname = '%@',",user.loginName];
    }
    
    if (user.sessionDate) {
        [temp appendFormat:@" sessiondate = '%lf',",user.sessionDate];
    }

    [temp appendFormat:@" isSession = '%@',",[NSString stringWithFormat:@"%u",user.isSession]];
    
    [temp appendString:@")"];
    query = [query stringByAppendingFormat:@"%@ WHERE memberid = '%u' and belongmemberid = '%u'",[temp stringByReplacingOccurrencesOfString:@",)" withString:@""],user.memberId,belongUid];
    NSLog(@"%@",query);
    NSLog(@"修改一条数据");
    [_db executeUpdate:query];
}

-(NSArray *)selectSessionUserWithBelongUid:(unsigned)belongUid
{
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM SFriend WHERE isSession = 1 and belongmemberid = '%u' ORDER BY sessiondate DESC",belongUid];
    FMResultSet * rs = [_db executeQuery:query];
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:[rs columnCount]];
	while ([rs next]) {
        Member *member = [[Member alloc] init];
        member.memberId = [rs intForColumn:@"memberid"];
        member.nickName = [rs stringForColumn:@"nickname"];
        member.loginName = [rs stringForColumn:@"loginname"];
        member.headImage = [rs stringForColumn:@"headimage"];
        member.isSession = [rs intForColumn:@"isSession"];
        member.sessionDate = [rs doubleForColumn:@"sessiondate"];
        SMessageDB *msgdb = [[SMessageDB alloc] init];
        member.messageArr = [msgdb selectMessageWithUid:member.memberId WithContactUid:belongUid];
        member.messageNotReadCount = [msgdb selectNotReadMessageCountWithUid:member.memberId WithContactUid:belongUid];
        [msgdb close];
        if ([member isValidate]) {
            [array addObject:member];
        }
	}
	[rs close];
    return array;
}

-(Member *)selectUserWithUid:(unsigned)uid WithBelongUid:(unsigned)belongUid
{
    Member *member = nil;
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM SFriend WHERE memberid = '%u' and belongmemberid = '%u'",uid,belongUid];
    FMResultSet * rs = [_db executeQuery:query];
    if ([rs next]) {
        member = [[Member alloc] init];
        member.memberId = [rs intForColumn:@"memberid"];
        member.nickName = [rs stringForColumn:@"nickname"];
        member.loginName = [rs stringForColumn:@"loginname"];
        member.headImage = [rs stringForColumn:@"headimage"];
        member.isSession = [rs intForColumn:@"isSession"];
        member.sessionDate = [rs doubleForColumn:@"sessiondate"];
        SMessageDB *msgdb = [[SMessageDB alloc] init];
        member.messageArr = [msgdb selectMessageWithUid:member.memberId WithContactUid:belongUid];
        member.messageNotReadCount = [msgdb selectNotReadMessageCountWithUid:member.memberId WithContactUid:belongUid];
        [msgdb close];
    }
	[rs close];
    return member;
}

-(NSArray *)selectAllUserWithBelongUid:(unsigned)belongUid
{
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM SFriend WHERE  belongmemberid = '%u'",belongUid];
    FMResultSet * rs = [_db executeQuery:query];
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:[rs columnCount]];
	while ([rs next]) {
        Member *member = [[Member alloc] init];
        member.memberId = [rs intForColumn:@"memberid"];
        member.nickName = [rs stringForColumn:@"nickname"];
        member.loginName = [rs stringForColumn:@"loginname"];
        member.headImage = [rs stringForColumn:@"headimage"];
        member.isSession = [rs intForColumn:@"isSession"];
        member.sessionDate = [rs doubleForColumn:@"sessiondate"];
        SMessageDB *msgdb = [[SMessageDB alloc] init];
        member.messageArr = [msgdb selectMessageWithUid:member.memberId WithContactUid:belongUid];
        member.messageNotReadCount = [msgdb selectNotReadMessageCountWithUid:member.memberId WithContactUid:belongUid];
        [msgdb close];
        if ([member isValidate]) {
            [array addObject:member];
        }
	}
	[rs close];
    return array;
}

-(BOOL)isExistMemberWithUid:(unsigned)uid WithBelongUid:(unsigned)belongUid
{
    NSString * query =[NSString stringWithFormat:@"SELECT * FROM SFriend WHERE memberid = '%u' and belongmemberid = '%u'",uid,belongUid];
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
