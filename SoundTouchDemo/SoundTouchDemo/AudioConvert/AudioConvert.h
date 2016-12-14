//
//  AudioConvert.h
//  SoundTouchDemo
//
//  Created by chuliangliang on 15-1-29.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//
/**
 * 说明:
 *      一款对音频处理的软件, 包括: 音频解码 、音频变声、音频编码; 此软件以技术研究为主要目的 使用简单只需要引入 AudioConvert.h 即可;
 *    由于使用了苹果的音频解码库 会导致 CADebugPrintf.h 文件找不到,解决方式 清空工程文件 Preprocessor Macros 参数, 本软件Debug 模式的开启和关闭 在AudioDefine中手动控制
 * 版本:
 *      V3.0
 * 功能:
 *      1)常见音频格式解码 (输入音频格式: 常见音频格式均可)
 *      2)音频变声处理
 *      3)指定音频格式编码处理 (输出音频格式 MP3 WAV AMR)
 *
 * 系统类库: AVFoundation.framework 、AudioToolbox.framework
 *
 * 第三方类库: SoundTouch (变声处理库)、 lame (MP3编码库)
 *
 * 反馈及联系方式:
 *          QQ:949977202
 *          Email : chuliangliang300@sina.com
 * 更多资源 : http://blog.csdn.net/u011205774 (本博客 收录了一些cocos2dx 简单介绍 和使用实例)
 **/
typedef struct
{
    const char *sourceAuioPath;         //输入的音频路径         必选
    
    Float64    outputSampleRate;        //输出的采样率           建议设置 8000 (优点: 采样率 越低 处理速度越快 缺点: 声音效果:反之 但非专业检测 不明显)
    int        outputFormat;            //输出音频格式           可选 默认 AudioConvertOutputFormat_WAV  具体见AudioConvertOutputFormat
    int        outputChannelsPerFrame;  //输出文件的通道数        可选 默认  1 可选择 1 或者 2 注意 最后输出的音频格式为mp3 时 通道数必须是 2 否则会造成编码后的音频变速

    int        soundTouchTempoChange;   //速度 <变速不变调> 范围 -50 ~ 100
    int        soundTouchPitch;         //音调  范围 -12 ~ 12
    int        soundTouchRate;          //声音速率 范围 -50 ~ 100
    
} AudioConvertConfig;


// 输出文件格式
typedef NS_ENUM(NSInteger, AudioConvertOutputFormat) {
    AudioConvertOutputFormat_WAV = 1,
    AudioConvertOutputFormat_AMR,
    AudioConvertOutputFormat_MP3,
};

@protocol AudioConvertDelegate <NSObject>

@optional

/**
 * 是否只对音频文件进行解码 默认 NO 分快执行时 不会调用此方法
 * return YES : 只解码音频 并且回调 "对音频解码动作的回调"  NO : 对音频进行变声 不会 回调 "对音频解码动作的回调"
 **/
- (BOOL)audioConvertOnlyDecode;

/**
 * 是否只对音频文件进行编码 默认 YES 分快执行时 不会调用此方法
 * return YES : 需要编码音频 并且回调 "对音频编码动作的回调"  NO : 不对音频进行编码 不会回调 "变声处理结果的回调"
 **/
- (BOOL)audioConvertHasEnecode;


/**
 * 对音频解码动作的回调
 **/
- (void)audioConvertDecodeSuccess:(NSString *)audioPath;//解码成功
- (void)audioConvertDecodeFaild;                        //解码失败
- (void)audioConvertDecodeProgress:(float)progress;     //解码进度<暂未实现>


/**
 * 对音频变声动作的回调
 **/
- (void)audioConvertSoundTouchSuccess:(NSString *)audioPath;//变声成功
- (void)audioConvertSoundTouchFail;                         //变声失败
- (void)audioConvertSoundTouchProgress:(float)progress;     //变声进度进度<暂未实现>



/**
 * 对音频编码动作的回调
 **/
- (void)audioConvertEncodeSuccess:(NSString *)audioPath;//编码完成
- (void)audioConvertEncodeFaild;                        //编码失败
- (void)audioConvertEncodeProgress:(float)progress;     //编码进度<暂未实现>

@end

#import <Foundation/Foundation.h>
#import "AudioDecodeOperation.h"
#import "AudioSoundTouchOperation.h"
#import "AudioEncodeOperation.h"

#define  DOCMENT  [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define  OUTPUT_DECODEPATH  [NSString stringWithFormat:@"%@/AudioConvert/Decode",DOCMENT]           //解码音频存储位置
#define  OUTPUT_SOUNDTOUCHPATH  [NSString stringWithFormat:@"%@/AudioConvert/SoundTouch",DOCMENT]   //变声过的音频存储位置
#define  OUTPUT_ENCODETMPPATH  [NSString stringWithFormat:@"%@/AudioConvert/Encodetmp",DOCMENT]    //编码音频临时存储位置
#define  OUTPUT_ENCODEPATH  [NSString stringWithFormat:@"%@/AudioConvert/Encode",DOCMENT]           //编码音频存储位置


@interface AudioConvert : NSObject

+ (AudioConvert *)shareAudioConvert;

/**
 * 说明:
 *
 * 功能: 1)输入音频 ->  2)解码 ->  3)变声 ->  4)处理文件准备编码 -> 5)编码
 *
 * 注意: 
 *      一、如果 2)执行后会调用 "- (BOOL)audioConvertOnlyDecode;" 若返回yes 返回解码结果 此时音频格式为wav  并结束 否则继续 详见 - (BOOL)audioConvertOnlyDecode 说明
 *      二、如果 4)执行后会调用 "- (BOOL)audioConvertHasEnecode;" 若返回 NO 返回变声处理后的结果 此时音频格式为wav 并结束 否则继续 详见 - (BOOL)audioConvertHasEnecode 说明
 **/
- (void)audioConvertBegin:(AudioConvertConfig )config
     withCallBackDelegate:(id)aDelegate;


#pragma mark- 分块接口

/**
 * 说明: 音频解码入口 这里 将音频解码成 wav
 * 
 * 参数: sourceAudioPath      原始文件的路径
 *       aDelegate           回调对象
 **/
- (void)audioConvertBeginDecode:(NSString *)sourceAudioPath
           withCallBackDelegate:(id)aDelegate;

/**
 * 说明: 对已经解码的音频进行变声的入口
 *
 * 参数: sourceAudioPath     经过解码后的音频路径
 *      aDelegate           回调对象
 *      tempoChange         速度 <变速不变调>  范围 -50 ~ 100
 *      pitch               音调  范围 -12 ~ 12
 *      rate                声音速率 范围 -50 ~ 100
 **/
- (void)audioConvertBeginSoundTouch:(NSString *)sourceAudioPath
               withCallBackDelegate:(id)aDelegate
                   audioTempoChange:(int)tempoChange
                         audioPitch:(int)pitch
                          audioRate:(int)rate;


/**
 * 说明: 对未编码音频进行编码 如 wav -> MP3
 *
 * 参数: sourceAudioPath     输入音频路径
 *      aDelegate           代理回调
 *      sampleRate          输出采样率
 *      format              输出音频格式
 *      channels            输出音频通道数 如 MP3 通道是 必须是 2 否则会出现音频变速
 **/
- (void)audioConvertBeginEncode:(NSString *)sourceAudioPath
           withCallBackDelegate:(id)aDelegate
          audioOutputSampleRate:(Float64)sampleRate
              audioOutputFormat:(AudioConvertOutputFormat)format
    audioOutputChannelsPerFrame:(int)channels;


/**
 * 结束所有子线程 同时取消代理
 **/
- (void)cancelAllThread;
@end
