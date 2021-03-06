//
//  WQPlaySound.h
//  ylmm
//
//  Created by macmini on 14-6-26.
//  Copyright (c) 2014年 YiLiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface WQPlaySound : NSObject{
    SystemSoundID soundID;
}
/**
 *  @brief  为播放震动效果初始化
 *
 *  @return self
 */
-(id)initForPlayingVibrate;

/**
 *  @brief  为播放系统音效初始化(无需提供音频文件)
 *
 *  @param resourceName 系统音效名称
 *  @param type 系统音效类型
 *
 *  @return self
 */
-(id)initForPlayingSystemSoundEffectWith:(NSString *)resourceName ofType:(NSString *)type;

/**
 *  @brief  为播放特定的音频文件初始化（需提供音频文件）
 *
 *  @param filename 音频文件名（加在工程中）
 *
 *  @return self
 */
-(id)initForPlayingSoundEffectWith:(NSString *)filename;

/**
 *  @brief  为播放特定的音频文件初始化（无需提供音频文件）
 *
 *  @param soundId 系统音频文件Id
 *
 *  @return self
 */
-(id)initForPlayingSoundWith:(SystemSoundID)soundId;

/**
 *  @brief  播放音效
 */
-(void)play;
@end
