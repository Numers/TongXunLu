//
//  FacePanelViewController.m
//  ylmm
//
//  Created by macmini on 14-5-29.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "ChatViewController.h"
#import "ClientHelper.h"
#import "Message.h"
#import "Member.h"
#import "ZBMessageManagerFaceView.h"

#import "AppDelegate.h"
#import "ChatCacheFileUtil.h"
#import "VoiceConverter.h"
#import "ChatRecorderView.h"
#import "UIView+Animation.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"

#import "SMessageDB.h"

#import "CustomMethod.h"
#import "OHAttributedLabel.h"
#import "MarkUpParser.h"

#import "MMProgressHUD.h"

#define maxRecordTime 60.0f


@interface ChatViewController ()<AVAudioRecorderDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
    double animationDuration;
    CGRect keyboardRect;
}

@end

@implementation ChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initilzer];
    animationDuration = 0.25;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollDragging:) name:@"SCROLLDRAGGING" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardWillShow:)
                                                name:UIKeyboardWillShowNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardWillHide:)
                                                name:UIKeyboardWillHideNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardChange:)
                                                name:UIKeyboardDidChangeFrameNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (![super isMovingFromParentViewController]){
        [self.messageToolView.messageInputTextView resignFirstResponder];
        [self messageToolAnimationWithMessageRect:CGRectZero withMessageInputViewRect:self.messageToolView.frame andDuration:animationDuration andState:ZBMessageViewStateShowNone];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -keyboard
- (void)keyboardWillHide:(NSNotification *)notification{

    keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
}

- (void)keyboardWillShow:(NSNotification *)notification{
    keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    animationDuration= [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
}

- (void)keyboardChange:(NSNotification *)notification{
    if ([[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y<CGRectGetHeight(self.view.frame)) {
        [self messageViewAnimationWithMessageRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:animationDuration
                                         andState:ZBMessageViewStateShowNone];
    }
}

#pragma mark - 按下Home键
- (void)applicationWillResignActive:(NSNotification *)notification
{
    NSLog(@"按理说是触发home按下");
    if ([audioRecorder isRecording]) {
        [self recordStop];
    }
}
#pragma mark - messageView animation
- (void)messageViewAnimationWithMessageRect:(CGRect)rect  withMessageInputViewRect:(CGRect)inputViewRect andDuration:(double)duration andState:(ZBMessageViewState)state{
    
    [UIView animateWithDuration:duration animations:^{
        self.messageToolView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame)-CGRectGetHeight(rect)-CGRectGetHeight(inputViewRect),CGRectGetWidth(self.view.frame),CGRectGetHeight(inputViewRect));
        CGRect frame = [(AppDelegate *)[UIApplication sharedApplication].delegate viewFrame:self.navigationController withTabBarController:self.tabBarController];
        self.tableView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.frame), CGRectGetHeight(frame)-CGRectGetHeight(rect)-CGRectGetHeight(inputViewRect));
        [self tableViewscrollToBottom];
        switch (state) {
            case ZBMessageViewStateShowFace:
            {
                self.faceView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame)-CGRectGetHeight(rect),CGRectGetWidth(self.view.frame),CGRectGetHeight(rect));
                
                self.shareMenuView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame),CGRectGetWidth(self.view.frame),CGRectGetHeight(self.shareMenuView.frame));
            }
                break;
            case ZBMessageViewStateShowNone:
            {
                 //self.tableView.frame = CGRectMake(0.0f, CGRectGetHeight(self.view.frame)-CGRectGetHeight(rect)-CGRectGetHeight(inputViewRect)-CGRectGetHeight(self.tableView.frame),CGRectGetWidth(self.tableView.frame), CGRectGetHeight(self.tableView.frame));
                
                self.faceView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame),CGRectGetWidth(self.view.frame),CGRectGetHeight(self.faceView.frame));
                
                self.shareMenuView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame),CGRectGetWidth(self.view.frame),CGRectGetHeight(self.shareMenuView.frame));
            }
                break;
            case ZBMessageViewStateShowShare:
            {
                self.shareMenuView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame)-CGRectGetHeight(rect),CGRectGetWidth(self.view.frame),CGRectGetHeight(rect));
                
                self.faceView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame),CGRectGetWidth(self.view.frame),CGRectGetHeight(self.faceView.frame));
            }
                break;
                
            default:
                break;
        }
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)messageToolAnimationWithMessageRect:(CGRect)rect  withMessageInputViewRect:(CGRect)inputViewRect andDuration:(double)duration andState:(ZBMessageViewState)state{
    
    [UIView animateWithDuration:duration animations:^{
        self.messageToolView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame)-CGRectGetHeight(rect)-CGRectGetHeight(inputViewRect),CGRectGetWidth(self.view.frame),CGRectGetHeight(inputViewRect));
        CGRect frame = [(AppDelegate *)[UIApplication sharedApplication].delegate viewFrame:self.navigationController withTabBarController:self.tabBarController];
        self.tableView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.frame), CGRectGetHeight(frame)-CGRectGetHeight(rect)-CGRectGetHeight(inputViewRect));
        switch (state) {
            case ZBMessageViewStateShowFace:
            {
                self.faceView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame)-CGRectGetHeight(rect),CGRectGetWidth(self.view.frame),CGRectGetHeight(rect));
                
                self.shareMenuView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame),CGRectGetWidth(self.view.frame),CGRectGetHeight(self.shareMenuView.frame));
            }
                break;
            case ZBMessageViewStateShowNone:
            {
                //self.tableView.frame = CGRectMake(0.0f, CGRectGetHeight(self.view.frame)-CGRectGetHeight(rect)-CGRectGetHeight(inputViewRect)-CGRectGetHeight(self.tableView.frame),CGRectGetWidth(self.tableView.frame), CGRectGetHeight(self.tableView.frame));
                
                self.faceView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame),CGRectGetWidth(self.view.frame),CGRectGetHeight(self.faceView.frame));
                
                self.shareMenuView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame),CGRectGetWidth(self.view.frame),CGRectGetHeight(self.shareMenuView.frame));
            }
                break;
            case ZBMessageViewStateShowShare:
            {
                self.shareMenuView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame)-CGRectGetHeight(rect),CGRectGetWidth(self.view.frame),CGRectGetHeight(rect));
                
                self.faceView.frame = CGRectMake(0.0f,CGRectGetHeight(self.view.frame),CGRectGetWidth(self.view.frame),CGRectGetHeight(self.faceView.frame));
            }
                break;
                
            default:
                break;
        }
        
    } completion:^(BOOL finished) {
        
    }];
}

-(void)tableViewFrameChangeWithMessageInputViewRect:(CGRect)inputViewRect andDuration:(double)duration
{
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = [(AppDelegate *)[UIApplication sharedApplication].delegate viewFrame:self.navigationController withTabBarController:self.tabBarController];
        self.tableView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.frame), CGRectGetHeight(frame)-CGRectGetHeight(self.view.frame)+self.messageToolView.frame.origin.y);
        [self tableViewscrollToBottom];
    } completion:^(BOOL finished) {
        
    }];
}
#pragma end

- (void)initilzer{
    [self shareMessageToolView];
    [self shareFaceView];
    [self shareShareMeun];
    
}

-(NSString *)messageInputViewTextByDelete:(NSString *)text
{
    NSString *name = nil;
    if ((text != nil) && (text.length > 0)) {
        NSString *expressionPlistPath = [[NSBundle mainBundle]pathForResource:@"expression" ofType:@"plist"];
        NSDictionary *expressionDic   = [[NSDictionary alloc]initWithContentsOfFile:expressionPlistPath];
        
        NSString *o_text = [CustomMethod transformString:text emojiDic:expressionDic];
        o_text = [NSString stringWithFormat:@"<font color='black' strokeColor='gray' face='Palatino-Roman'>%@",o_text];
        
        MarkUpParser *wk_markupParser = [[MarkUpParser alloc] init];
        NSMutableAttributedString* attString = [wk_markupParser attrStringFromMarkUp:o_text];
        NSString *aString = [attString string];
        NSString *temp = [aString substringFromIndex:aString.length-2];
        if ([temp isEqualToString:@"－ "]){
            NSRange range = [text rangeOfString:@"[" options:NSBackwardsSearch];
            if (range.length > 0) {
                name = [text substringToIndex:range.location];
            }
            
        }else{
            name = [text substringToIndex:text.length-1];
        }

    }
    return name;
}

-(void)shareMessageToolView
{
    if (!self.messageToolView) {
        CGFloat inputViewHeight;
        
        if ([[[UIDevice currentDevice]systemVersion]floatValue]>=7) {
            inputViewHeight = 45.0f;
        }
        else{
            inputViewHeight = 40.0f;
        }
        
        NSLog(@"%lf",self.view.frame.size.height);
        self.messageToolView = [[ZBMessageInputView alloc]initWithFrame:CGRectMake(0.0f,
                                                                                   self.view.frame.size.height - inputViewHeight,self.view.frame.size.width,inputViewHeight)];
        self.messageToolView.delegate = self;
        [self.view addSubview:self.messageToolView];
        self.previousTextViewContentHeight =  35.5f;
    }
}

- (void)shareFaceView{
    
    if (!self.faceView)
    {
        NSLog(@"%lf",CGRectGetHeight(self.view.frame));
        self.faceView = [[ZBMessageManagerFaceView alloc]initWithFrame:CGRectMake(0.0f,
                                                                                  CGRectGetHeight(self.view.frame), CGRectGetWidth(self.view.frame), 196)];
        self.faceView.delegate = self;
        [self.view addSubview:self.faceView];
        
    }
}

- (void)shareShareMeun
{
    if (!self.shareMenuView)
    {
        NSLog(@"%lf,%lf",CGRectGetHeight(self.view.frame),CGRectGetWidth(self.view.frame));
        self.shareMenuView = [[ZBMessageShareMenuView alloc]initWithFrame:CGRectMake(0.0f,
                                                                                     CGRectGetHeight(self.view.frame),
                                                                                     CGRectGetWidth(self.view.frame), 196)];
        [self.view addSubview:self.shareMenuView];
        self.shareMenuView.delegate = self;
        [self.shareMenuView ImageSetting];
        [self.shareMenuView reloadData];
    }
}

/*
 * 发送信息
 */
- (void)didSendTextAction:(ZBMessageTextView *)messageInputTextView{
    NSString *content = messageInputTextView.text;
    if ((content != nil) && (content.length > 0)) {
        messageInputTextView.text = @"";
        [self inputTextViewDidChange:messageInputTextView];
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        NSDate *date = [NSDate date];
        fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss"; // @"yyyy-MM-dd HH:mm:ss"
        NSString *time = [fmt stringFromDate:date];
        Message *message = [[Message alloc] init];
        message.memberId = self.chatToMember.memberId;
        message.content = content;
        message.contentType = MessageContentText;
        message.time = time;
        message.icon = self.hostMember.headImage;
        message.type = MessageTypeMe;
        message.code = MessageCodeText;
        message.state = MessageIsSend;
        message.readState = MessageRead;
        self.chatToMember.sessionDate = [date timeIntervalSince1970];
        [self addMessage:message];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MOVEMEMBERTOTOP" object:self.chatToMember];
        
        NSString *msg = [NSString stringWithFormat:@"{\"txt\":\"%@\",\"ct\":%u}",content,MessageContentText];
        NSInteger ret = [ClientHelper sendMessage:self.hostMember.memberId Token:[CommonUtil MyToken] ToUid:self.chatToMember.memberId Message:msg Msgsn:self.chatToMember.messageArr.count-1];
        if (ret<0) {
            message.state = MessageFailed;
            [self updateMessageStateWithMessage:message];
            [ClientHelper connectToHost];
        }
        NSLog(@"send");
    }
}

-(void)recordStart
{
    if(recording)
        return;
    
    [audioPlayer pause];
    recording=YES;
    
    NSDictionary *settings=[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithFloat:8000],AVSampleRateKey,
                            [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                            [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                            [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                            [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                            [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                            nil];
    
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    NSDate *now = [NSDate date];
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"yyyy_MM_dd"];
    NSString *temp = [NSString stringWithFormat:@"%u%lf",self.hostMember.memberId,[now timeIntervalSince1970]];
    NSString *fileName = [temp stringByAppendingString:@".wav"];
    amrFileName = [temp stringByAppendingString:@".amr"];
    NSString *fullPath = [[[ChatCacheFileUtil sharedInstance] userDocPath] stringByAppendingPathComponent:fileName];
    NSURL *url = [NSURL fileURLWithPath:fullPath];
    pathURL = url;
    
    NSError *error;
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:pathURL settings:settings error:&error];
    audioRecorder.delegate = self;
    
    [audioRecorder prepareToRecord];
    [audioRecorder setMeteringEnabled:YES];
    [audioRecorder peakPowerForChannel:0];
    [audioRecorder record];
    
    [self initRecordView];
    [UIView showView:recorderView
         animateType:AnimateTypeOfPopping
           finalRect:kRecorderViewRect
          completion:^(BOOL finish){
              if (finish){
                  [self startRecorderViewTimer];
              }
          }];
    //设置遮罩背景不可触摸
    [UIView setTopMaskViewCanTouch:NO];
}

-(void)recordStop
{
    if(!recording)
        return;
    _timeLen = audioRecorder.currentTime;
    [UIView hideViewByCompletion:^(BOOL finish){
        [self stopRecorderViewTimer];
    }];
    
    if ([audioRecorder isRecording]) {
        [audioRecorder stop];
        recording = NO;
    }
    
    if (_timeLen < 1) {
        [MMProgressHUD showWithStatus:nil];
        [MMProgressHUD dismissWithError:@"录音过短" afterDelay:2.0f];
        [[ChatCacheFileUtil sharedInstance] deleteWithContentPath:pathURL.path];
        return;
    }
    
    NSString *amrPath = [VoiceConverter wavToAmr:pathURL.path];
    Message *message = [[Message alloc] init];
    message.memberId = self.chatToMember.memberId;
    message.icon = self.hostMember.headImage;
    message.code = MessageCodeText;
    message.type = MessageTypeMe;
    message.content = [NSString stringWithFormat:@"%@|%d",amrFileName,[[NSNumber numberWithDouble:_timeLen] intValue]];
    message.contentType = MessageContentVoice;
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *now = [NSDate date];
    message.time = [fmt stringFromDate:now];
    message.readState = MessageRead;
    message.state = MessageIsSend;
    self.chatToMember.sessionDate = [now timeIntervalSince1970];
    [self addMessage:message];
    [[ChatCacheFileUtil sharedInstance] deleteWithContentPath:pathURL.path];
    //[[ChatCacheFileUtil sharedInstance] deleteWithContentPath:amrPath];
    
    NSLog(@"音频文件路径:%@\n%@",pathURL.path,amrPath);
    //    if (_timeLen<1) {
    //        [g_App showAlert:@"录的时间过短"];
    //        return;
    //    }
    //[self sendVoice:recordData];
    
    [self uploadVoiceFile:message WithFileName:amrFileName];
}

-(void)recordCancel
{
    if(!recording)
        return;
    if ([audioRecorder isRecording]) {
        [audioRecorder stop];
        recording = NO;
    }
    
    [UIView hideViewByCompletion:^(BOOL finish){
        [self stopRecorderViewTimer];
    }];
    [recorderView prepareToDelete:YES];
    
}


#pragma mark - 启动定时器
- (void)startRecorderViewTimer{
    recorderViewTimer = [NSTimer scheduledTimerWithTimeInterval:0.02f target:self selector:@selector(updateMeters) userInfo:nil repeats:YES];
}

#pragma mark - 停止定时器
- (void)stopRecorderViewTimer{
    if (recorderViewTimer && recorderViewTimer.isValid){
        [recorderViewTimer invalidate];
        recorderViewTimer = nil;
    }
     //[recorderView prepareToDelete:YES];
}
#pragma mark - 更新音频峰值
- (void)updateMeters{
    if (audioRecorder.isRecording){
        //更新峰值
        [audioRecorder updateMeters];
        [recorderView updateMetersByAvgPower:[audioRecorder averagePowerForChannel:0]];
        
        _timeLen = audioRecorder.currentTime;
        if(_timeLen>=maxRecordTime){
            [self recordStop];
        }
    }
}

-(void)uploadVoiceFile:(Message *)message WithFileName:(NSString *)name
{
    //上传头像
    NSString *amrFullPath = [[[ChatCacheFileUtil sharedInstance] userDocPath] stringByAppendingPathComponent:amrFileName];
    NSData *recordData = [NSData dataWithContentsOfFile:amrFullPath];
    if (recordData != nil) {
        NSString *urlStr = [NSString stringWithFormat:@"%@/YiXin/UploadFile",BASEURL];
        ASIFormDataRequest *request=[ASIFormDataRequest requestWithURL:[NSURL URLWithString:urlStr]];
        [request setData:recordData withFileName:name andContentType:@"amr" forKey:@"file"];
        [request setTimeOutSeconds:1000];
        
        [request setCompletionBlock:^{
            NSLog(@"%@",request.responseString);
            NSDictionary *rootDic=[request.responseString objectFromJSONString];
            int code = [[rootDic objectForKey:@"Code"] intValue];
            if (code == 1) {
                NSLog(@"上传成功");
                NSString *voiceAbsolutePath = [rootDic objectForKey:@"Data"];
                if (voiceAbsolutePath != nil) {
                    NSRange range = [voiceAbsolutePath rangeOfString:@"/UpLoadFile/"];
                    if (range.length > 0) {
                        NSString *path = [voiceAbsolutePath substringFromIndex:range.location+range.length];
                        NSString *serverPath = [path stringByAppendingString:[NSString stringWithFormat:@"|%d",[[NSNumber numberWithDouble:_timeLen] intValue]]];
                        NSString *sendContent = [NSString stringWithFormat:@"{\"txt\":\"%@\",\"ct\":%u}",serverPath,MessageContentVoice];
                        NSInteger ret = [ClientHelper sendMessage:self.hostMember.memberId Token:[CommonUtil MyToken] ToUid:self.chatToMember.memberId Message:sendContent Msgsn:self.chatToMember.messageArr.count-1];
                        if (ret<0) {
                            message.state = MessageFailed;
                            [self updateMessageStateWithMessage:message];
                            [ClientHelper connectToHost];
                        }
                    }
                }
            }else
            {
                NSLog(@"上传失败");
            }
            
        }];
        [request setFailedBlock:^{
            
        }];
        [request startAsynchronous];

    }
}

-(void)uploadImageFile:(UIImage *)image WithSendMessage:(Message *)message WithFileName:(NSString *)name
{
    //上传图片
    NSData *imageData = UIImageJPEGRepresentation(image,0.01);
    NSString *urlStr = [NSString stringWithFormat:@"%@/YiXin/UploadFile",BASEURL];
    ASIFormDataRequest *request=[ASIFormDataRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [request setData:imageData withFileName:name andContentType:@"jpeg" forKey:@"file"];
    [request setTimeOutSeconds:1000];
    
    [request setCompletionBlock:^{
        NSLog(@"%@",request.responseString);
        NSDictionary *rootDic=[request.responseString objectFromJSONString];
        int code = [[rootDic objectForKey:@"Code"] intValue];
        if (code == 1) {
            NSLog(@"上传成功");
            NSString *voiceAbsolutePath = [rootDic objectForKey:@"Data"];
            if (voiceAbsolutePath != nil) {
                NSRange range = [voiceAbsolutePath rangeOfString:@"/UpLoadFile/"];
                if (range.length > 0) {
                    NSString *path = [voiceAbsolutePath substringFromIndex:range.location+range.length];
                    NSString *serverPath = [path stringByAppendingString:@"|IMAGE"];
                    message.content = serverPath;
                    [self addMessage:message];
                    NSString *sendContent = [NSString stringWithFormat:@"{\"txt\":\"%@\",\"ct\":%u}",serverPath,MessageContentImage];
                    NSInteger ret = [ClientHelper sendMessage:self.hostMember.memberId Token:[CommonUtil MyToken] ToUid:self.chatToMember.memberId Message:sendContent Msgsn:self.chatToMember.messageArr.count-1];
                    if (ret < 0) {
                        message.state = MessageFailed;
                        [self updateMessageStateWithMessage:message];
                        [ClientHelper connectToHost];
                    }
                }
            }
        }else
        {
            NSLog(@"上传失败");
        }
        
    }];
    [request setFailedBlock:^{
        
    }];
    [request startAsynchronous];
    
}

-(void)imageUploadInitWithImage:(UIImage *)image
{
    NSDate *now = [NSDate date];
    NSString *temp = [NSString stringWithFormat:@"%u%lf",self.hostMember.memberId,[now timeIntervalSince1970]];
    NSString *fileName = [temp stringByAppendingString:@".jpeg"];
    
    Message *message = [[Message alloc] init];
    message.memberId = self.chatToMember.memberId;
    message.icon = self.hostMember.headImage;
    message.code = MessageCodeText;
    message.contentType = MessageContentImage;
    message.type = MessageTypeMe;
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    message.time = [fmt stringFromDate:now];
    message.readState = MessageRead;
    message.state = MessageIsSend;
    UIImage *uploadImage = [CommonUtil croppedImage:image];
    self.chatToMember.sessionDate = [now timeIntervalSince1970];
    [self uploadImageFile:uploadImage WithSendMessage:message WithFileName:fileName];

}

#pragma mark - 初始化录音界面
- (void)initRecordView{
    if (recorderView == nil)
        recorderView = (ChatRecorderView*)[[[NSBundle mainBundle]loadNibNamed:@"ChatRecorderView" owner:self options:nil] lastObject];
    //还原界面显示
    [recorderView restoreDisplay];
}

#pragma mark - AVAudioRecorder Delegate Methods
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"录音停止");
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder{
    NSLog(@"录音开始");
}
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags{
    NSLog(@"录音中断");
}

#pragma mark - ZBMessageInputView Delegate
- (void)didSelectedMultipleMediaAction:(BOOL)changed{
    
    if (changed)
    {
        [self messageViewAnimationWithMessageRect:self.shareMenuView.frame
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:animationDuration
                                         andState:ZBMessageViewStateShowShare];
    }
    else{
        [self messageViewAnimationWithMessageRect:keyboardRect
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:animationDuration
                                         andState:ZBMessageViewStateShowNone];
    }
    
}


- (void)didSendFaceAction:(BOOL)sendFace{
    if (sendFace) {
        [self messageViewAnimationWithMessageRect:self.faceView.frame
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:animationDuration
                                         andState:ZBMessageViewStateShowFace];
    }
    else{
        [self messageViewAnimationWithMessageRect:keyboardRect
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:animationDuration
                                         andState:ZBMessageViewStateShowNone];
    }
}

- (void)didChangeSendVoiceAction:(BOOL)changed{
    if (changed){
        [self messageViewAnimationWithMessageRect:keyboardRect
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:animationDuration
                                         andState:ZBMessageViewStateShowNone];
    }
    else{
        [self messageViewAnimationWithMessageRect:CGRectZero
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:animationDuration
                                         andState:ZBMessageViewStateShowNone];
    }
}

/*
 * 点击输入框代理方法
 */
- (void)inputTextViewWillBeginEditing:(ZBMessageTextView *)messageInputTextView{
    
}

- (void)inputTextViewDidBeginEditing:(ZBMessageTextView *)messageInputTextView
{
    [self messageViewAnimationWithMessageRect:keyboardRect
                     withMessageInputViewRect:self.messageToolView.frame
                                  andDuration:animationDuration
                                     andState:ZBMessageViewStateShowNone];
    
    if (!self.previousTextViewContentHeight)
    {
        self.previousTextViewContentHeight = messageInputTextView.contentSize.height;
    }
}

- (void)inputTextViewDidChange:(ZBMessageTextView *)messageInputTextView
{
    CGFloat maxHeight = [ZBMessageInputView maxHeight];
    CGSize size = [messageInputTextView sizeThatFits:CGSizeMake(CGRectGetWidth(messageInputTextView.frame), maxHeight)];
    CGFloat textViewContentHeight = size.height;
    
    // End of textView.contentSize replacement code
    BOOL isShrinking = textViewContentHeight <= self.previousTextViewContentHeight;
    CGFloat changeInHeight = textViewContentHeight - self.previousTextViewContentHeight;
    
    if(!isShrinking && self.previousTextViewContentHeight == maxHeight) {
        changeInHeight = 0;
    }
    else {
        changeInHeight = MIN(changeInHeight, maxHeight - self.previousTextViewContentHeight);
    }
    
    if(changeInHeight != 0.0f) {
        
        [UIView animateWithDuration:0.01f
                         animations:^{
                             
                             if(isShrinking) {
                                 // if shrinking the view, animate text view frame BEFORE input view frame
                                 [self.messageToolView adjustTextViewHeightBy:changeInHeight];
                             }
                             
                             CGRect inputViewFrame = self.messageToolView.frame;
                             self.messageToolView.frame = CGRectMake(0.0f,
                                                                     inputViewFrame.origin.y - changeInHeight,
                                                                     inputViewFrame.size.width,
                                                                     inputViewFrame.size.height + changeInHeight);
                             
                             if(!isShrinking) {
                                 [self.messageToolView adjustTextViewHeightBy:changeInHeight];
                             }
                         }
                         completion:^(BOOL finished) {
                             [self tableViewFrameChangeWithMessageInputViewRect:self.messageToolView.frame andDuration:0.01f];
                             
                         }];
        
        self.previousTextViewContentHeight = MIN(textViewContentHeight, maxHeight);
    }
}

/**
 *  按下录音按钮开始录音
 */
- (void)didStartRecordingVoiceAction
{
    NSLog(@"开始录制...");
    [self recordStart];
}

/**
 *  手指向上滑动取消录音
 */
- (void)didCancelRecordingVoiceAction
{
    NSLog(@"取消录制...");
    [self recordCancel];
}

/**
 *  松开手指完成录音
 */
- (void)didFinishRecoingVoiceAction
{
    NSLog(@"结束录制...");
    if ([audioRecorder isRecording]) {
        [self recordStop];
    }
}
#pragma end

#pragma mark - ZBMessageFaceViewDelegate
- (void)SendTheFaceStr:(NSString *)faceStr isDelete:(BOOL)dele
{
    if (dele) {
        self.messageToolView.messageInputTextView.text = [self messageInputViewTextByDelete:self.messageToolView.messageInputTextView.text];
    }else{
        self.messageToolView.messageInputTextView.text = [self.messageToolView.messageInputTextView.text stringByAppendingString:faceStr];
    }
    [self inputTextViewDidChange:self.messageToolView.messageInputTextView];
}

-(void)sendStr
{
    [self didSendTextAction:self.messageToolView.messageInputTextView];
}
#pragma end

#pragma mark - ZBMessageShareMenuView Delegate
- (void)didSelecteShareMenuItem:(ZBMessageShareMenuItem *)shareMenuItem atIndex:(NSInteger)index{
    switch (index) {
        case 0:
        {
            NSLog(@"点击第一个按钮。");
            UIImagePickerController *imgPicker=[[UIImagePickerController alloc]init];
            [imgPicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            [imgPicker setDelegate:self];
            [imgPicker setAllowsEditing:YES];
            [self presentViewController:imgPicker animated:YES completion:^{
            }];
        }

            break;
        case 1:
        {
            NSLog(@"点击第二个按钮。");
            UIImagePickerController *imgPicker=[[UIImagePickerController alloc]init];
            [imgPicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [imgPicker setDelegate:self];
            [imgPicker setAllowsEditing:YES];
            [self.navigationController presentViewController:imgPicker animated:YES completion:^{
            }];
        }
            break;
        case 2:
            NSLog(@"点击第三个按钮。");
            break;
        case 3:
            NSLog(@"点击第四个按钮。");
            break;
        default:
            break;
    }
}

#pragma mark ----------图片选择完成-------------
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage  * userImage= [info objectForKey:@"UIImagePickerControllerEditedImage"];
    
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [self messageViewAnimationWithMessageRect:CGRectZero
                         withMessageInputViewRect:self.messageToolView.frame
                                      andDuration:animationDuration
                                         andState:ZBMessageViewStateShowNone];
        [self imageUploadInitWithImage:userImage];
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

#pragma end

-(void)scrollDragging:(NSNotification *)notification
{
    [self.view endEditing:YES];
    [self messageToolAnimationWithMessageRect:CGRectZero
                     withMessageInputViewRect:self.messageToolView.frame
                                  andDuration:animationDuration
                                     andState:ZBMessageViewStateShowNone];
}

/*-(void)hiddenFacePaneView
{
    CATransition *animation = [CATransition animation];
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromBottom;
    animation.delegate = self;
    animation.duration = 0.3f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [self.view.layer addAnimation:animation forKey:@"fromBottom"];
    
    CGRect frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 59.0f - 64.0f, self.view.frame.size.width, 350);
    self.view.frame = frame;
    //CGAffineTransform pTransform = CGAffineTransformMakeTranslation(0, -100);
    //使视图使用这个变换
    //self.view.transform = pTransform;
}
-(void)showFacePaneView
{
    CATransition *animation = [CATransition animation];
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromTop;
    animation.delegate = self;
    animation.duration = 0.3f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.view.layer addAnimation:animation forKey:@"fromTop"];
    NSLog(@"%lf,%lf",self.view.frame.size.height,[UIScreen mainScreen].bounds.size.height);
    CGRect frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 350, self.view.frame.size.width, 350);
    //CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, facePanelVC.view.frame.size.height);
    self.view.frame = frame;

    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context]; // Begin animation
    [UIView setAnimationDuration:2.0f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.view cache:NO];//从左翻转
    [UIView setAnimationDelegate:self];
    [UIView commitAnimations]; // End animations
    CGRect statusBarViewRect = [[UIApplication sharedApplication] statusBarFrame];
    float heightPadding = statusBarViewRect.size.height + self.navigationController.navigationBar.frame.size.height;
    CGRect frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - self.view.frame.size.height - heightPadding, self.view.frame.size.width, self.view.frame.size.height);
    //CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, facePanelVC.view.frame.size.height);
    self.view.frame = frame;

}*/

#pragma mark - 文本框代理方法
#pragma mark 点击textField键盘的回车按钮
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    // 1、增加数据源
   /* NSString *content = textField.text;
    
    // 2、清空文本框内容
    _messageField.text = nil;
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    NSDate *date = [NSDate date];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss"; // @"yyyy-MM-dd HH:mm:ss"
    NSString *time = [fmt stringFromDate:date];
    Message *message = [[Message alloc] init];
    message.content = content;
    message.time = time;
    message.icon = hostMember.headImage;
    message.type = MessageTypeMe;
    message.state = MessageFailed;
    [self.delegate addMessage:message];
    [self.delegate sendMessage:message];*/
    return YES;
}
- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    NSLog(@"delete characters");
    return YES;
}

@end
