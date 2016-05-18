//
//  SMessageDB.m
//  ylmm
//
//  Created by macmini on 14-6-6.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "SMessageDB.h"
#define kMessageTableName @"SMessage"
@implementation SMessageDB
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
    FMResultSet * set = [_db executeQuery:[NSString stringWithFormat:@"select count(*) from sqlite_master where type ='table' and name = '%@'",kMessageTableName]];
    
    [set next];
    
    NSInteger count = [set intForColumnIndex:0];
    
    BOOL existTable = !!count;
    
    if (existTable) {
        // TODO:是否更新数据库
        NSLog(@"数据库已经存在");
    } else {
        // TODO: 插入新的数据库
        NSString * sql = @"CREATE TABLE SMessage (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, memberid INTEGER,contactmemberid INTEGER, icon VARCHAR(50),time VARCHAR(50), content VARCHAR(500),contentType INTEGER, type INTEGER, code INTEGER, state INTEGER, readstate INTEGER)";
        BOOL res = [_db executeUpdate:sql];
        if (!res) {
            NSLog(@"%@数据库创建失败",kMessageTableName);
        } else {
            NSLog(@"%@数据库创建成功",kMessageTableName);
        }
    }

}
/**
 * @brief 保存一条用户记录
 *
 * @param Message 需要保存的用户数据
 * @param uid 消息的从属uid
 */
- (void) saveMessage:(Message *) message WithUid:(unsigned)uid WithContactUid:(unsigned)otherUid
{
    NSMutableString * query = [NSMutableString stringWithFormat:@"INSERT INTO SMessage"];
    NSMutableString * keys = [NSMutableString stringWithFormat:@" ("];
    NSMutableString * values = [NSMutableString stringWithFormat:@" ( "];
    NSMutableArray * arguments = [NSMutableArray arrayWithCapacity:9];
    
    [keys appendString:@"memberid,"];
    [values appendString:@"?,"];
    [arguments addObject:[NSString stringWithFormat:@"%u",uid]];
    
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

-(void)deleteMessageWithUid:(unsigned)uid WithContactUid:(unsigned)otherUid
{
    NSString * query = [NSString stringWithFormat:@"DELETE FROM SMessage WHERE memberid = '%u' and contactmemberid = '%u'",uid,otherUid];
    NSLog(@"删除一条数据");
    [_db executeUpdate:query];
}

- (void) mergeMessage:(Message *)message WithUid:(unsigned)uid WithContactUid:(unsigned)otherUid
{
    NSString * query = @"UPDATE SMessage SET";
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
    query = [query stringByAppendingFormat:@"%@ WHERE memberid = '%u' and contactmemberid = '%u' and time = '%@'",[temp stringByReplacingOccurrencesOfString:@",)" withString:@""],uid,otherUid,message.time];
    NSLog(@"%@",query);
    NSLog(@"修改一条数据");
    [_db executeUpdate:query];

}

-(void)mergeNotReadMessageToReadMessageWithUid:(unsigned)uid WithContactUid:(unsigned)otherUid
{
    NSString * query = [NSString stringWithFormat:@"UPDATE SMessage SET readstate = '%d' WHERE memberid = '%u' and contactmemberid = '%u' and readstate = '%d'",MessageRead,uid,otherUid,MessageNotRead];
    NSInteger result = [_db executeUpdate:query];
    NSLog(@"更新了%ld条数据",(long)result);
}

-(NSMutableArray *)selectMessageWithUid:(unsigned)uid WithContactUid:(unsigned)otherUid
{
    NSString * query =[NSString stringWithFormat: @"SELECT * FROM (SELECT * FROM SMessage WHERE memberid = '%u' and contactmemberid = '%u' ORDER BY id DESC limit 100) AS temp ORDER BY id ASC",uid,otherUid];
    FMResultSet * rs = [_db executeQuery:query];
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:[rs columnCount]];
	while ([rs next]) {
        Message *message = [[Message alloc] init];
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

-(NSMutableArray *)selectImageMessageWithUid:(unsigned)uid WithContactUid:(unsigned)otherUid
{
    NSString * query =[NSString stringWithFormat: @"SELECT * FROM (SELECT * FROM SMessage WHERE memberid = '%u' and contactmemberid = '%u' ORDER BY id DESC limit 100) AS temp WHERE temp.contentType = '%u' ORDER BY id ASC",uid,otherUid,MessageContentImage];
    FMResultSet * rs = [_db executeQuery:query];
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:[rs columnCount]];
	while ([rs next]) {
        Message *message = [[Message alloc] init];
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

-(NSInteger)selectNotReadMessageCountWithUid:(unsigned)uid WithContactUid:(unsigned)otherUid
{
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM SMessage WHERE memberid = '%u' and contactmemberid = '%u' and readstate = '%d'",uid,otherUid,MessageNotRead];
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
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM SMessage WHERE contactmemberid = '%u' and  readstate = '%d'",uid,MessageNotRead];
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
