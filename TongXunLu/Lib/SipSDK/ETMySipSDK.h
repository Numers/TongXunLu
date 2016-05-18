//
//  ETMySipSDK.h
//  SipDemo
//
//  Created by macmini on 14-12-3.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#import "Reachability.h"
#import "call.h"
#import "pjsua.h"
@class CallViewController;
@interface ETMySipSDK : NSObject
{
    app_config_t _app_config; // pointer ???
    BOOL isConnected;
    BOOL isIpod;
    
    pjsua_acc_id  _sip_acc_id;
    
    CallViewController    *callViewController;
    
@private
    BOOL launchDefault;
    Reachability *_hostReach;
}

+(ETMySipSDK *)shareSipSDK;
-(void)startSipCallWithUserName:(NSString *)username WithPassWord:(NSString *)password WithServer:(NSString *)server WithRegTimeOut:(NSString *)regTimeOut WithProxyServer:(NSString *)proxyserver;
-(void) dialup:(NSString *)phoneNumber number:(BOOL)isNumber;
- (void)callDisconnecting;
@end
