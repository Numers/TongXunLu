//
//  VoicePlayDevice.h
//  ylmm
//
//  Created by macmini on 14-8-19.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface VoicePlayDevice : NSObject
+(AVAudioPlayer *)shareInstanceWithFilePath:(NSString *)filePath;
@end
