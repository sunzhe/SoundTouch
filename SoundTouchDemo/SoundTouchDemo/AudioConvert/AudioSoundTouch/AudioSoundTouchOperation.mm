//
//  AudioSoundTouchOperation.m
//  SoundTouchDemo
//
//  Created by chuliangliang on 15-1-29.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//

#import "AudioSoundTouchOperation.h"
#include "SoundTouch.h"
#include "WaveHeader.h"

@interface AudioSoundTouchOperation ()
{
    int audioSampleRate;     //采样率 <这里使用8000 原因: 录音是采样率:8000>
    int audioTempoChange;    //速度 <变速不变调>
    int audioPitch;          //音调
    int audioRate;           //声音速率
    int audioChannels;       //音频声道数

    id target;
    SEL action;

}
@property (nonatomic, strong) NSString *srcPath;
@property (nonatomic, strong) NSString *outputPath;
@end


@implementation AudioSoundTouchOperation
- (id)initWithTarget:(id)tar
              action:(SEL)ac
          sourcePath:(NSString *)srcPath
     audioOutputPath:(NSString *)outputParh
     audioSampleRate:(int)sampleRate
    audioTempoChange:(int)tempoChange
          audioPitch:(int)pitch
           audioRate:(int)rate
       audioChannels:(int)channels
{
    self = [super init];
    if (self) {
        target = tar;
        action = ac;
        
        self.srcPath = srcPath;
        self.outputPath = outputParh;
        
        audioSampleRate = sampleRate;
        audioTempoChange = tempoChange;
        audioPitch = pitch;
        audioRate = rate;
        audioChannels = channels;
    }
    return self;
}

- (void)main {
    BOOL isSuccess = YES;
    
    try {
        NSData *soundData = [NSData dataWithContentsOfFile:self.srcPath];
        soundtouch::SoundTouch mSoundTouch;
        mSoundTouch.setSampleRate(audioSampleRate); //采样率
        mSoundTouch.setChannels(audioChannels);       //设置声音的声道
        mSoundTouch.setTempoChange(audioTempoChange);    //这个就是传说中的变速不变调
        mSoundTouch.setPitchSemiTones(audioPitch); //设置声音的pitch (集音高变化semi-tones相比原来的音调)
        mSoundTouch.setRateChange(audioRate);     //设置声音的速率
        mSoundTouch.setSetting(SETTING_SEQUENCE_MS, 40);
        mSoundTouch.setSetting(SETTING_SEEKWINDOW_MS, 15); //寻找帧长
        mSoundTouch.setSetting(SETTING_OVERLAP_MS, 6);  //重叠帧长
        
        CNLog(@"sampleRate: %d tempoChangeValue:%d  pitchSemiTones:%d  rateChange:%d",audioSampleRate,audioTempoChange,audioPitch,audioRate);
        
        NSMutableData *soundTouchDatas = [[NSMutableData alloc] init];
        
        if (soundData != nil) {
            char *pcmData = (char *)soundData.bytes;
            int pcmSize = soundData.length;
            int nSamples = pcmSize / 2;
            mSoundTouch.putSamples((short *)pcmData, nSamples);
            short *samples = new short[pcmSize];
            int numSamples = 0;
            do {
                memset(samples, 0, pcmSize);
                //short samples[nSamples];
                numSamples = mSoundTouch.receiveSamples(samples, pcmSize);
                [soundTouchDatas appendBytes:samples length:numSamples*2];
                
            } while (numSamples > 0);
            delete [] samples;
        }
        
        
        NSMutableData *wavDatas = [[NSMutableData alloc] init];
        int fileLength = soundTouchDatas.length;
        void *header = createWaveHeader(fileLength, audioChannels, audioSampleRate, 16);
        [wavDatas appendBytes:header length:44];
        [wavDatas appendData:soundTouchDatas];
        
        BOOL isSave = [wavDatas writeToFile:self.outputPath atomically:YES];
        soundTouchDatas = nil;
        wavDatas = nil;
        isSuccess = isSave;
    } catch (NSException *exception) {
        CNLog(@"exception:%@",exception);
        isSuccess = NO;
    }
    
    if (!self.isCancelled) {
        [target performSelectorOnMainThread:action withObject:(isSuccess ? self.outputPath : nil) waitUntilDone:NO];
    }
    
}

@end
