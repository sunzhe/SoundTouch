//
//  AudioSoundTouchOperation.h
//  SoundTouchDemo
//
//  Created by chuliangliang on 15-1-29.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioDefine.h"

@interface AudioSoundTouchOperation : NSOperation

/**
 * audioSampleRate;     //采样率
 * audioTempoChange;    //速度 <变速不变调>
 * audioPitch;          //音调
 * audioRate;           //声音速率
 * audioChannels;       //音频声道数
 **/
- (id)initWithTarget:(id)tar
              action:(SEL)ac
          sourcePath:(NSString *)srcPath
     audioOutputPath:(NSString *)outputParh
     audioSampleRate:(int)sampleRate
    audioTempoChange:(int)tempoChange
          audioPitch:(int)pitch
           audioRate:(int)rate
       audioChannels:(int)channels;

@end
