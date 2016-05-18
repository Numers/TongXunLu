//
//  Member.m
//  tongxunlu
//
//  Created by macmini on 14-5-12.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "Member.h"

@implementation Member

-(NSArray *)allContacts
{
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    Member *one = [[Member alloc] init];
    one.userId = @"10000";
    one.userName = @"aa";
    one.userPsd = @"12345";
    one.userSex = @"男";
    one.email = @"12345@qq.com";
    one.innerOffice_phone = @"123456";
    one.mob_publongphone = @"13067906924";
    one.mob_pubshortphone = @"598339";
    one.home_phone = @"057128867897";
    one.roleName = @"行政主管";
    one.groupName = @"行知学院";
    one.depName = @"行政部";
    [mutableArray addObject:one];
    
    Member *three = [[Member alloc] init];
    three.userId = @"10000";
    three.userName = @"cc";
    three.userPsd = @"12345";
    three.userSex = @"男";
    three.email = @"12345@qq.com";
    three.innerOffice_phone = @"123456";
    three.mob_publongphone = @"13067906924";
    three.mob_pubshortphone = @"598339";
    three.home_phone = @"057128867897";
    three.roleName = @"行政主管";
    three.groupName = @"行知学院";
    three.depName = @"行政部";
    [mutableArray addObject:three];
    
    Member *two = [[Member alloc] init];
    two.userId = @"10001";
    two.userName = @"bb";
    two.userPsd = @"12345";
    two.userSex = @"女";
    two.email = @"12353@qq.com";
    two.innerOffice_phone = @"123276";
    two.mob_publongphone = @"13067906924";
    two.mob_pubshortphone = @"598386";
    two.home_phone = @"057128867857";
    two.roleName = @"教授";
    two.groupName = @"行知学院";
    two.depName = @"研发部";
    [mutableArray addObject:two];
    
    Member *four = [[Member alloc] init];
    four.userId = @"10001";
    four.userName = @"dd";
    four.userPsd = @"12345";
    four.userSex = @"女";
    four.email = @"12353@qq.com";
    four.innerOffice_phone = @"123276";
    four.mob_publongphone = @"13067906924";
    four.mob_pubshortphone = @"598386";
    four.home_phone = @"057128867857";
    four.roleName = @"教授";
    four.groupName = @"行知学院";
    four.depName = @"研发部";
    [mutableArray addObject:four];
    
    return [NSArray arrayWithArray:mutableArray];
}
-(NSArray *)allSections
{
    NSArray *array = [NSArray arrayWithObjects:@"研发部",@"行政部", nil];
    return array;
}
@end
