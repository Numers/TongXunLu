//
//  Notify.h
//  TongXunLu
//
//  Created by teach on 14-8-31.
//  Copyright (c) 2014年 dhb. All rights reserved.
//
typedef enum {
    NotifyRead = true,
    NotifyUnRead = false
} NotifyReadState;
#import <Foundation/Foundation.h>

@interface Notify : NSObject
@property(nonatomic, copy) NSString *messageId;
//@property(nonatomic, copy) NSString *label;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *publicTime;
@property(nonatomic, copy) NSString *content;
@property(nonatomic) NotifyReadState readState;
@end
