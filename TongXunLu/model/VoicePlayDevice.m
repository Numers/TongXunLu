//
//  VoicePlayDevice.m
//  ylmm
//
//  Created by macmini on 14-8-19.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import "VoicePlayDevice.h"

static AVAudioPlayer *audioPlayer;
@implementation VoicePlayDevice
+(AVAudioPlayer *)shareInstanceWithFilePath:(NSString *)filePath
{
    if (audioPlayer) {
        [audioPlayer stop];
    }
    [self initPlayerWithFileData:[NSData dataWithContentsOfFile:filePath]];
    return audioPlayer;
}

+(void)initPlayerWithFileData:(NSData *)fileData{
    //初始化播放器的时候如下设置
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                            sizeof(sessionCategory),
                            &sessionCategory);
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride);
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //默认情况下扬声器播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    audioSession = nil;
    
    NSError *error=nil;
    audioPlayer = [[AVAudioPlayer alloc] initWithData:fileData error:&error];
    if (error) {
        error=nil;
    }
}
@end
