//
//  RecordInputView.h
//  InPutBoxView
//
//  Created by chuliangliang on 15-1-6.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//
//由于时间紧迫 有可能不是非常完美 欢迎大家指正
//
//QQ: 949977202
//Email: chuliangliang300@sina.com

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>

#define DefaultSubPath @"Voice" //默认 二级目录 可以修改自己想要的 例如 "文件夹1/文件夹2/文件夹3"

#define SampleRateKey 8000.0 //采样率
#define LinearPCMBitDepth 16 //采样位数 默认 16
#define NumberOfChannels 1  //通道的数目

@protocol RecorderDelegate <NSObject>
/**
 * 录音进行中
 * currentTime 录音时长
 **/
-(void)recorderCurrentTime:(NSTimeInterval)currentTime;

/**
 * 录音完成
 * filePath 录音文件保存路径
 * fileName 录音文件名
 * duration 录音时长
 **/
-(void)recorderStop:(NSString *)filePath voiceName:(NSString *)fileName duration:(NSTimeInterval)duration;

/**
 * 开始录音
 **/
-(void)recorderStart;
@end

@interface Recorder : NSObject<AVAudioRecorderDelegate>

@property (assign, nonatomic) id<RecorderDelegate> recorderDelegate;
@property(strong, nonatomic) NSString *filename,*filePath;
/**
 * 录音控件 单例对象
 **/
+(Recorder *)shareRecorder;


/**
 * 开始录音
 * //默认的录音存储的文件夹在 "Document/Voice/文件名(文件名示例: 2015-01-06_12:41).wav"
 * 录音的文件名 "2015-01-06_12:41"
 **/
-(void)startRecord;
/**
 * 停止录音
 **/
-(void)stopRecord;

/**
 * 获得峰值
 **/
-(float)getPeakPower;

/**
 * 是否可以录音
 **/
- (BOOL)canRecord;
@end
