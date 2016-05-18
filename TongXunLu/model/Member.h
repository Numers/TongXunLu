//
//  Member.h
//  tongxunlu
//
//  Created by macmini on 14-5-12.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Member : NSObject
@property(copy, nonatomic) NSString *userId;
@property(copy, nonatomic) NSString *userName;
@property(copy, nonatomic) NSString *userPsd;
@property(copy, nonatomic) NSString *userSex;
@property(copy, nonatomic) NSString *email;
@property(copy, nonatomic) NSString *innerOffice_phone;
@property(copy, nonatomic) NSString *mob_publongphone;
@property(copy, nonatomic) NSString *mob_pubshortphone;
@property(copy, nonatomic) NSString *home_phone;
@property(copy, nonatomic) NSString *roleName;
@property(copy, nonatomic) NSString *groupName;
@property(copy, nonatomic) NSString *depName;

-(NSArray *)allContacts;
-(NSArray *)allSections;
@end
