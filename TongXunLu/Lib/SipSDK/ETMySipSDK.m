//
//  ETMySipSDK.m
//  SipDemo
//
//  Created by macmini on 14-12-3.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "ETMySipSDK.h"
#import "CallViewController.h"
static NSString *kVoipOverEdge = @"siphonOverEDGE";
#define kDelayToCall 10.0
static ETMySipSDK *etMySipSDK;
@implementation ETMySipSDK
+(ETMySipSDK *)shareSipSDK
{
    if (etMySipSDK == nil) {
        etMySipSDK = [[ETMySipSDK alloc] init];
    }
    return etMySipSDK;
}

-(void)startSipCallWithUserName:(NSString *)username WithPassWord:(NSString *)password WithServer:(NSString *)server WithRegTimeOut:(NSString *)regTimeOut WithProxyServer:(NSString *)proxyserver
{
    [self userDefaultsValueSettingWithUserName:username WithPassWord:password WithServer:server WithRegTimeOut:regTimeOut WithProxyServer:proxyserver];
    [self setUpSIP];
}

-(void)userDefaultsValueSettingWithUserName:(NSString *)username WithPassWord:(NSString *)password WithServer:(NSString *)server WithRegTimeOut:(NSString *)regTimeOut WithProxyServer:(NSString *)proxyserver
{
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:username forKey:@"username"];
    [userDef setObject:password forKey:@"password"];
    [userDef setObject:server forKey:@"server"];
    [userDef setObject:regTimeOut forKey:@"regTimeout"];
    [userDef setObject:proxyserver forKey:@"proxyServer"];
    [userDef synchronize];
}

- (void)initModel
{
    NSString *model = [[UIDevice currentDevice] model];
    isIpod = [model hasPrefix:@"iPod"];
    //NSLog(@"%@", model);
}

- (void)initUserDefaults
{
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt: 1800], @"regTimeout",
                          [NSNumber numberWithBool:NO], @"enableNat",
                          [NSNumber numberWithBool:NO], @"enableMJ",
                          [NSNumber numberWithInt: 5060], @"localPort",
                          [NSNumber numberWithInt: 4000], @"rtpPort",
                          [NSNumber numberWithInt: 15], @"kaInterval",
                          [NSNumber numberWithBool:NO], @"enableEC",
                          [NSNumber numberWithBool:YES], @"disableVad",
                          [NSNumber numberWithInt: 0], @"codec",
                          [NSNumber numberWithBool:NO], @"dtmfWithInfo",
                          [NSNumber numberWithBool:NO], @"enableICE",
                          [NSNumber numberWithInt: 0], @"logLevel",
                          [NSNumber numberWithBool:YES],  @"enableG711u",
                          [NSNumber numberWithBool:YES],  @"enableG711a",
                          [NSNumber numberWithBool:NO],   @"enableG722",
                          [NSNumber numberWithBool:NO],   @"enableG7221",
                          [NSNumber numberWithBool:NO],   @"enableG729",
                          [NSNumber numberWithBool:YES],  @"enableGSM",
                          [NSNumber numberWithBool:NO], @"keepAwake",
                          nil];
    
    [userDef registerDefaults:dict];
    [userDef synchronize];
}


-(void)setUpSIP
{
    _sip_acc_id = PJSUA_INVALID_ID;
    
    isConnected = FALSE;
    
    [self initModel];
    [self initUserDefaults];
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    if (![[userDef objectForKey: @"username"] length] ||
        ![[userDef objectForKey: @"server"] length])
    {
        launchDefault = NO;
    }
    else
    {
        NSString *server = [userDef stringForKey: @"proxyServer"];
        NSArray *array = [server componentsSeparatedByString:@","];
        NSEnumerator *enumerator = [array objectEnumerator];
        while (server = [enumerator nextObject])
            if ([server length])break;// {[server retain]; break;}
        //[enumerator release];
        // [array release];
        if (!server || [server length] < 1)
            server = [userDef stringForKey: @"server"];
        
        NSRange range = [server rangeOfString:@":"
                                      options:NSCaseInsensitiveSearch|NSBackwardsSearch];
        if (range.length > 0)
        {
            server = [server substringToIndex:range.location];
        }
        
        // Build GUI
        callViewController = [[CallViewController alloc] initWithNibName:nil bundle:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
        _hostReach = [Reachability reachabilityWithHostName: server];
        [_hostReach startNotifer];
        
        launchDefault = YES;
        [self performSelector:@selector(sipConnect) withObject:nil afterDelay:0.2];
        
        if ([userDef boolForKey:@"keepAwake"])
        {
//            [self keepAwakeEnabled];
        }
    }
}

-(void)displayError:(NSString *)error withTitle:(NSString *)title
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                     message:error
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"OK", @"SiphonApp")
                                           otherButtonTitles:nil];
    [alert show];
    //[alert release];
}


- (void) activateWWAN
{
    //NSURL * url = [[NSURL alloc] initWithString:[NSString stringWithCString:"http://www.anyurl.com"]];
    NSURL * url = [[NSURL alloc] initWithString:[NSString stringWithCString:"http://www.google.com"]];
    NSData * data = [NSData dataWithContentsOfURL:url];
}

- (BOOL)wakeUpNetwork
{
    BOOL overEDGE = FALSE;
    if (isIpod == FALSE)
    {
        overEDGE = [[NSUserDefaults standardUserDefaults] boolForKey:kVoipOverEdge];
    }
    NetworkStatus netStatus = [_hostReach currentReachabilityStatus];
    BOOL connectionRequired= [_hostReach connectionRequired];
    if ((overEDGE && netStatus == NotReachable) ||
        (!overEDGE && netStatus != ReachableViaWiFi))
        return NO;
    //if (overEDGE && netStatus == ReachableViaWWAN)
    if (connectionRequired)
    {
        [self activateWWAN];
    }
    
    return YES;
}
/***** SIP ********/
/* */
- (BOOL)sipStartup
{
    if (_app_config.pool)
        return YES;
    
    if (sip_startup(&_app_config) != PJ_SUCCESS)
    {
        return NO;
    }
    
    /** Call management **/
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processCallState:)
                                                 name: kSIPCallState object:nil];
    
    /** Registration management */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processRegState:)
                                                 name: kSIPRegState object:nil];
    
    return YES;
}

/* */
- (void)sipCleanup
{
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name: kSIPRegState
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSIPCallState
                                                  object:nil];
    [self sipDisconnect];
    
    if (_app_config.pool != NULL)
    {
        sip_cleanup(&_app_config);
    }
}

/* */
- (BOOL)sipConnect
{
    pj_status_t status;
    
    if (![self sipStartup])
        return FALSE;
    
    if ([self wakeUpNetwork] == NO)
        return NO;
    
    if (_sip_acc_id == PJSUA_INVALID_ID)
    {
        if ((status = sip_connect(_app_config.pool, &_sip_acc_id)) != PJ_SUCCESS)
        {
            return FALSE;
        }
    }
    
    return TRUE;
}

/* */
- (BOOL)sipDisconnect
{
    if ((_sip_acc_id != PJSUA_INVALID_ID) &&
        (sip_disconnect(&_sip_acc_id) != PJ_SUCCESS))
    {
        return FALSE;
    }
    
    _sip_acc_id = PJSUA_INVALID_ID;
    
    isConnected = FALSE;
    
    return TRUE;
}

- (NSString *)normalizePhoneNumber:(NSString *)number
{
    const char *phoneDigits = "22233344455566677778889999",
    *nb = [[number uppercaseString] UTF8String];
    int i, len = [number length];
    char *u, *c, *utf8String = (char *)calloc(sizeof(char), len+1);
    c = (char *)nb; u = utf8String;
    for (i = 0; i < len; ++c, ++i)
    {
        if (*c == ' ' || *c == '(' || *c == ')' || *c == '/' || *c == '-' || *c == '.')
            continue;
        /*    if (*c >= '0' && *c <= '9')
         {
         *u = *c;
         u++;
         }
         else*/ if (*c >= 'A' && *c <= 'Z')
         {
             *u = phoneDigits[*c - 'A'];
         }
         else
             *u = *c;
        u++;
    }
    NSString * norm = [[NSString alloc] initWithUTF8String:utf8String];
    free(utf8String);
    return norm;
}


/** FIXME plutôt à mettre dans l'objet qui gère les appels **/
-(void) dialup:(NSString *)phoneNumber number:(BOOL)isNumber
{
    pjsua_call_id call_id;
    pj_status_t status;
    NSString *number;
    
    UInt32 hasMicro, size;
    
    // Verify if microphone is available (perhaps we should verify in another place ?)
    size = sizeof(hasMicro);
    AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable,
                            &size, &hasMicro);
    if (!hasMicro)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Microphone Available", @"SiphonApp")
                                                        message:NSLocalizedString(@"Connect a microphone to phone", @"SiphonApp")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"SiphonApp")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (isNumber)
        number = [self normalizePhoneNumber:phoneNumber];
    else
        number = phoneNumber;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"removeIntlPrefix"])
    {
        number = [number stringByReplacingOccurrencesOfString:@"+"
                                                   withString:@""
                                                      options:0
                                                        range:NSMakeRange(0,1)];
    }
    else
    {
        NSString *prefix = [[NSUserDefaults standardUserDefaults] stringForKey:
                            @"intlPrefix"];
        if ([prefix length] > 0)
        {
            number = [number stringByReplacingOccurrencesOfString:@"+"
                                                       withString:prefix
                                                          options:0
                                                            range:NSMakeRange(0,1)];
        }
    }
    
    // Manage pause symbol
    NSArray * array = [number componentsSeparatedByString:@","];
    [callViewController setDtmfCmd:@""];
    if ([array count] > 1)
    {
        number = [array objectAtIndex:0];
        [callViewController setDtmfCmd:[array objectAtIndex:1]];
    }
    
    if (!isConnected && [self wakeUpNetwork] == NO)
    {
//        _phoneNumber = [[NSString stringWithString: number] retain];
        if (isIpod)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                 message:NSLocalizedString(@"You must enable Wi-Fi or SIP account to place a call.",@"SiphonApp")
                                                                delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"OK",@"SiphonApp")
                                                       otherButtonTitles:nil];
            [alertView show];
        }
        else
        {
        }
        return;
    }
    
    if ([self sipConnect])
    {
        NSRange range = [number rangeOfString:@"@"];
        if (range.location != NSNotFound)
        {
            status = sip_dial_with_uri(_sip_acc_id, [[NSString stringWithFormat:@"sip:%@", number] UTF8String], &call_id);
        }
        else
            status = sip_dial(_sip_acc_id, [number UTF8String], &call_id);
        if (status != PJ_SUCCESS)
        {
            // FIXME
            //[self displayStatus:status withTitle:nil];
            const pj_str_t *str = pjsip_get_status_text(status);
            NSString *msg = [[NSString alloc]
                             initWithBytes:str->ptr 
                             length:str->slen 
                             encoding:[NSString defaultCStringEncoding]];
            [self displayError:msg withTitle:@"registration error"];
        }
    }
}


- (void)processCallState:(NSNotification *)notification
{
#if 0
    NSNumber *value = [[ notification userInfo ] objectForKey: @"CallID"];
    pjsua_call_id callId = [value intValue];
#endif
    int state = [[[ notification userInfo ] objectForKey: @"State"] intValue];
    
    switch(state)
    {
        case PJSIP_INV_STATE_NULL: // Before INVITE is sent or received.
            return;
        case PJSIP_INV_STATE_CALLING: // After INVITE is sent.
#ifdef __IPHONE_3_0
            [UIDevice currentDevice].proximityMonitoringEnabled = YES;
#else
            self.proximitySensingEnabled = YES;
#endif
        case PJSIP_INV_STATE_INCOMING: // After INVITE is received.
            if (pjsua_call_get_count() == 1)
            {
                NSArray *arr = [UIApplication sharedApplication].windows;
                [[arr objectAtIndex:0] addSubview:callViewController.view];
                NSLog(@"来电话了");
            }
        case PJSIP_INV_STATE_EARLY: // After response with To tag.
        case PJSIP_INV_STATE_CONNECTING: // After 2xx is sent/received.
            break;
        case PJSIP_INV_STATE_CONFIRMED: // After ACK is sent/received.
#ifdef __IPHONE_3_0
            [UIDevice currentDevice].proximityMonitoringEnabled = YES;
#else
            self.proximitySensingEnabled = YES;
#endif
            break;
        case PJSIP_INV_STATE_DISCONNECTED:
#if 0
            self.idleTimerDisabled = NO;
#ifdef __IPHONE_3_0
            [UIDevice currentDevice].proximityMonitoringEnabled = NO;
#else
            self.proximitySensingEnabled = NO;
#endif
            if (pjsua_call_get_count() <= 1)
                [self performSelector:@selector(disconnected:)
                           withObject:nil afterDelay:1.0];
#endif
            break;
    }
    [callViewController processCall: [ notification userInfo ]];
}

- (void)callDisconnecting
{
    if (pjsua_call_get_count() <= 1)
        [self performSelector:@selector(disconnected:)
                   withObject:nil afterDelay:1.0];
}

- (void)outOfTimeToCall
{
    launchDefault = YES;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"dateOfCall"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"callURL"];
}


- (void)processRegState:(NSNotification *)notification
{
    //  const pj_str_t *str;
    //NSNumber *value = [[ notification userInfo ] objectForKey: @"AccountID"];
    //pjsua_acc_id accId = [value intValue];
    int status = [[[ notification userInfo ] objectForKey: @"Status"] intValue];
    
    switch(status)
    {
        case 200: // OK
            isConnected = TRUE;
            if (launchDefault == NO)
            {
                pjsua_call_id call_id;
                NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:@"dateOfCall"];
                NSString *url = [[NSUserDefaults standardUserDefaults] stringForKey:@"callURL"];
                if (date && [date timeIntervalSinceNow] < kDelayToCall)
                {
                    sip_dial_with_uri(_sip_acc_id, [url UTF8String], &call_id);
                }
                [self outOfTimeToCall];
            }
            break;
        case 403: // registration failed
        case 404: // not found
            //sprintf(TheGlobalConfig.accountError, "SIP-AUTH-FAILED");
            //break;
        case 503:
        case PJSIP_ENOCREDENTIAL:
            // This error is caused by the realm specified in the credential doesn't match the realm challenged by the server
            //sprintf(TheGlobalConfig.accountError, "SIP-REGISTER-FAILED");
            //break;
        default:
            isConnected = FALSE;
            //      [self sipDisconnect];
    }
} 

- (void) disconnected:(id)fp8
{
    [[callViewController view] removeFromSuperview];
}

- (app_config_t *)pjsipConfig
{
    return &_app_config;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability* curReach = [notification object];
    if ([curReach currentReachabilityStatus] == NotReachable)
    {
        [self sipDisconnect];
    }
    else
    {
        [self sipConnect];
    }
}

@end
