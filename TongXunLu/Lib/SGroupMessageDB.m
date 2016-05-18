//
//  SGroupMessageDB.m
//  ylmm
//
//  Created by macmini on 14-7-1.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "SGroupMessageDB.h"
#define kGroupMessageTableName @"SGroupMessage"
@implementation SGroupMessageDB
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
    FMResultSet * set = [_db executeQuery:[NSString stringWithFormat:@"select count(*) from sqlite_master where type ='table' and name = '%@'",kGroupMessageTableName]];
    
    [set next];
    
    NSInteger count = [set intForColumnIndex:0];
    
    BOOL existTable = !!count;
    
    if (existTable) {
        // TODO:是否更新数据库
        NSLog(@"数据库已经存在");
    } else {
        // TODO: 插入新的数据库
        NSString * sql = @"CREATE TABLE SGroupMessage (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, groupid INTEGER, memberid INTEGER,contactmemberid INTEGER, icon VARCHAR(50),time VARCHAR(50), content VARCHAR(500),contentType INTEGER, type INTEGER, code INTEGER, state INTEGER, readstate INTEGER)";
        BOOL res = [_db executeUpdate:sql];
        if (!res) {
            NSLog(@"%@数据库创建失败",kGroupMessageTableName);
        } else {
            NSLog(@"%@数据库创建成功",kGroupMessageTableName);
        }
    }
}
/**
 * @brief 保存一条用户记录
 *
 * @param Message 需要保存的用户数据
 * @param otherUid 消息的从属otherUid
 */
- (void)saveGroupMessage:(GroupMessage *) message WithContactUid:(unsigned)otherUid
{
    NSMutableString * query = [NSMutableString stringWithFormat:@"INSERT INTO SGroupMessage"];
    NSMutableString * keys = [NSMutableString stringWithFormat:@" ("];
    NSMutableString * values = [NSMutableString stringWithFormat:@" ( "];
    NSMutableArray * arguments = [NSMutableArray arrayWithCapacity:10];
    
    [keys appendString:@"groupid,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%u",message.belongGroupId]];
    
    [keys appendString:@"memberid,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%u",message.memberId]];
    
    [keys appendString:@"contactmemberid,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%u",otherUid]];
    
    if (message.icon) {
        [keys appendString:@"icon,"];
        [values appendString:@"?,"];
        [arguments addObject:message.icon];
    }
    
    if (message.time) {
        [keys appendString:@"time,"];
        [values appendString:@"?,"];
        [arguments addObject:message.time];
    }
    
    if (message.content) {
        [keys appendString:@"content,"];
        [values appendString:@"?,"];
        [arguments addObject:message.content];
    }
    
    [keys appendString:@"contentType,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%d",message.contentType]];
    
    [keys appendString:@"type,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%d",message.type]];
    
    [keys appendString:@"code,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%d",message.code]];
    
    [keys appendString:@"state,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%d",message.state]];
    
    [keys appendString:@"readstate,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%d",message.readState]];
    
    
    [keys appendString:@")"];
    [values appendString:@")"];
    [query appendFormat:@" %@ VALUES%@",
     [keys stringByReplacingOccurrencesOfString:@",)" withString:@")"],
     [values stringByReplacingOccurrencesOfString:@",)" withString:@")"]];
    NSLog(@"%@",query);
    NSLog(@"插入一条数据");
    [_db executeUpdate:query withArgumentsInArray:arguments];
}

-(void)deleteGroupMessageWithGid:(unsigned)gid WithContactUid:(unsigned)otherUid
{
    NSString * query = [NSString stringWithFormat:@"DELETE FROM SGroupMessage WHERE groupid = '%u' and contactmemberid = '%u'",gid,otherUid];
    NSLog(@"删除一条数据");
    [_db executeUpdate:query];
}

- (void) mergeGroupMessage:(GroupMessage *)message WithContactUid:(unsigned)otherUid
{
    NSString * query = @"UPDATE SGroupMessage SET";
    NSMutableString * temp = [NSMutableString stringWithCapacity:100];
    // xxx = xxx;
    if (message.icon) {
        [temp appendFormat:@" icon = '%@',",message.icon];
    }
    if (message.time) {
        [temp appendFormat:@" time = '%@',",message.time];
    }
    
    if (message.content) {
        [temp appendFormat:@" content = '%@',",message.content];
    }
    
    [temp appendFormat:@" contentType = '%d',",message.contentType];
    [temp appendFormat:@" type = '%d',",message.type];
    [temp appendFormat:@" code = '%d',",message.code];
    [temp appendFormat:@" state = '%d',",message.state];
    [temp appendFormat:@" readstate = '%d',",message.readState];
    
    [temp appendString:@")"];
    query = [query stringByAppendingFormat:@"%@ WHERE groupid = '%u' and contactmemberid = '%u' and time = '%@' and memberid = '%u'",[temp stringByReplacingOccurrencesOfString:@",)" withString:@""],message.belongGroupId,otherUid,message.time,message.memberId];
    NSLog(@"%@",query);
    NSLog(@"修改一条数据");
    [_db executeUpdate:query];

}

-(void)mergeNotReadMessageToReadMessageWithGid:(unsigned)gid WithContactUid:(unsigned)otherUid
{
    NSString * query = [NSString stringWithFormat:@"UPDATE SGroupMessage SET readstate = '%d' WHERE groupid = '%u' and contactmemberid = '%u' and readstate = '%d'",MessageRead,gid,otherUid,MessageNotRead];
    NSInteger result = [_db executeUpdate:query];
    NSLog(@"更新了%ld条数据",(long)result);
}

-(NSMutableArray *)selectGroupMessageWithGid:(unsigned)gid WithContactUid:(unsigned)otherUid
{
    NSString * query =[NSString stringWithFormat: @"SELECT * FROM (SELECT * FROM SGroupMessage WHERE groupid = '%u' and contactmemberid = '%u' ORDER BY id DESC limit 100) AS temp ORDER BY id ASC",gid,otherUid];
    FMResultSet * rs = [_db executeQuery:query];
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:[rs columnCount]];
	while ([rs next]) {
        GroupMessage *message = [[GroupMessage alloc] init];
        message.belongGroupId = [rs intForColumn:@"groupid"];
        message.memberId = [rs intForColumn:@"memberid"];
        message.icon = [rs stringForColumn:@"icon"];
        message.time = [rs stringForColumn:@"time"];
        message.code = [rs intForColumn:@"code"];
        message.content = [rs stringForColumn:@"content"];
        message.contentType = [rs intForColumn:@"contentType"];
        message.type = [rs intForColumn:@"type"];
        message.state = [rs intForColumn:@"state"];
        message.readState = [rs intForColumn:@"readstate"];
        [array addObject:message];
	}
	[rs close];
    return array;
}

-(NSMutableArray *)selectImageGroupMessageWithGid:(unsigned)gid WithContactUid:(unsigned)otherUid
{
    NSString * query =[NSString stringWithFormat: @"SELECT * FROM (SELECT * FROM SGroupMessage WHERE groupid = '%u' and contactmemberid = '%u' ORDER BY id DESC limit 100) AS temp WHERE temp.contentType = '%u' ORDER BY id ASC",gid,otherUid,MessageContentImage];
    FMResultSet * rs = [_db executeQuery:query];
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:[rs columnCount]];
	while ([rs next]) {
        GroupMessage *message = [[GroupMessage alloc] init];
        message.belongGroupId = [rs intForColumn:@"groupid"];
        message.memberId = [rs intForColumn:@"memberid"];
        message.icon = [rs stringForColumn:@"icon"];
        message.time = [rs stringForColumn:@"time"];
        message.code = [rs intForColumn:@"code"];
        message.content = [rs stringForColumn:@"content"];
        message.contentType = [rs intForColumn:@"contentType"];
        message.type = [rs intForColumn:@"type"];
        message.state = [rs intForColumn:@"state"];
        message.readState = [rs intForColumn:@"readstate"];
        [array addObject:message];
	}
	[rs close];
    return array;
}

-(NSInteger)selectNotReadMessageCountWithGid:(unsigned)gid WithContactUid:(unsigned)otherUid
{
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM SGroupMessage WHERE groupid = '%u' and contactmemberid = '%u' and readstate = '%d'",gid,otherUid,MessageNotRead];
    NSLog(@"%@",query);
    FMResultSet * rs = [_db executeQuery:query];
    NSInteger result = 0;
    while ([rs next]) {
        result++;
    }
    [rs close];
    NSLog(@"查到%ld条数据",(long)result);
    return result;

}
-(NSInteger)selectNotReadMessageCountWithContactUid:(unsigned)uid
{
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM SGroupMessage WHERE contactmemberid = '%u' and  readstate = '%d'",uid,MessageNotRead];
    NSLog(@"%@",query);
    FMResultSet * rs = [_db executeQuery:query];
    NSInteger result = 0;
    while ([rs next]) {
        result++;
    }
    NSLog(@"查到%ld条数据",(long)result);
    return result;
}

-(void)close
{
    //[[SDBManager defaultDBManager] close];;
}
@end
