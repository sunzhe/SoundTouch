//
//  AudioEncodeOperation.h
//  SoundTouchDemo
//
//  Created by chuliangliang on 15-1-28.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//


/**
 * 说明
 * 此代码 对Lame 库 进行封装 对未编码音频文件进行mp3 编码
 * 由于 2015年2月1日之后 提交AppStore 的应用必须支持 arm64 所以对 lame 库进行了 处理 完美兼容 arm64
 * 这个类只做 MP3 编码处理
 **/
#import <Foundation/Foundation.h>
#import "AudioDefine.h"
@interface AudioEncodeOperation : NSOperation

- (id)initWithTarget:(id)tar action:(SEL)ac audioSrcPath:(NSString *)path;


/**
 * path : 输入音频路径
 * outputPath : 输出路径
 * srcSampeRate : 输入音频的采样率
 * outputSampleRate : 输出音频的采样率
 * channel : 声道数
 **/
- (id)initWithTarget:(id)tar
              action:(SEL)ac
        audioSrcPath:(NSString *)path
     audioOutputPath:(NSString *)outputPath
     audioSampleRate:(int)srcSampeRate
outputAudioSampleRate:(int)outputSampleRate
       audioChannels:(int)channel;
@end
