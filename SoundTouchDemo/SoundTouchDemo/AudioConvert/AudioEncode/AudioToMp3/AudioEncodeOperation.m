//
//  AudioEncodeOperation.m
//  SoundTouchDemo
//
//  Created by chuliangliang on 15-1-28.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//

#import "AudioEncodeOperation.h"
#include "lame.h"
@interface AudioEncodeOperation ()
{
    id target;
    SEL action;
    
    int audioSampleRate;        //输入音频的采样率
    int audioOutputSampleRate;  //输出音频的采样率
    int audioChannels;          //音频声道数
 
}
@property (strong, nonatomic) NSString *audioSrcPath;
@property (strong, nonatomic) NSString *audioOutPath;
@end

@implementation AudioEncodeOperation


- (id)initWithTarget:(id)tar
              action:(SEL)ac
        audioSrcPath:(NSString *)path
     audioOutputPath:(NSString *)outputPath
     audioSampleRate:(int)srcSampeRate
outputAudioSampleRate:(int)outputSampleRate
       audioChannels:(int)channel
{
    self = [super init];
    if (self) {
        target = tar;
        action = ac;
        
        self.audioSrcPath = path;
        self.audioOutPath = outputPath;

        audioSampleRate = srcSampeRate;
        audioOutputSampleRate = outputSampleRate;
        audioChannels = channel;
    }
    return self;
}

- (id)initWithTarget:(id)tar action:(SEL)ac audioSrcPath:(NSString *)path
{
    self = [super init];
    if (self) {
        target = tar;
        action = ac;
        self.audioSrcPath = path;
        self.audioOutPath = [self createSavePath];
        
        audioSampleRate = 8000;
        audioOutputSampleRate = 22050;
        audioChannels = 2;

    }
    return self;
}





- (void)main {
    [self audioEncode_ToMp3];
}




- (void)audioEncode_ToMp3
{
    BOOL isSuccess = YES;
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([self.audioSrcPath cStringUsingEncoding:NSUTF8StringEncoding], "rb");  //source 被转换的音频文件位置
        if (pcm == NULL) {
            if (!self.isCancelled) {
                [target performSelectorOnMainThread:action withObject:nil waitUntilDone:NO];
            }
            return;
        }
        
        fseek(pcm, 4*1024, SEEK_CUR);                                         //skip file header
        FILE *mp3 = fopen([self.audioOutPath cStringUsingEncoding:NSUTF8StringEncoding], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, audioSampleRate);          //输入音频采样率
        lame_set_out_samplerate(lame, audioOutputSampleRate);   //输出音频采样率
        
        lame_set_num_channels(lame,audioChannels);              //输入音频声道数
        
        
        lame_set_VBR(lame, vbr_default);
    
        lame_init_params(lame);
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);

            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        CNLog(@"AudioEncode-Debug: %@",[exception description]);
        
        isSuccess = NO;
    }
    
    if (!self.isCancelled) {
        [target performSelectorOnMainThread:action withObject:(isSuccess ? self.audioOutPath : nil) waitUntilDone:NO];
    }
}


//创建文件存储路径
- (NSString *)createSavePath {
    //文件名使用 "voiceFile+当前时间的时间戳"
    NSString *fileName = [self createFileName];
    
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *wavfilepath = [NSString stringWithFormat:@"%@/SoundTouch/lame",documentDir];
    
    NSString *writeFilePath = [NSString stringWithFormat:@"%@/%@.mp3",wavfilepath, fileName];
    BOOL isExist =  [[NSFileManager defaultManager]fileExistsAtPath:writeFilePath];
    if (isExist) {
        //如果存在则移除 以防止 文件冲突
        NSError *err = nil;
        [[NSFileManager defaultManager]removeItemAtPath:writeFilePath error:&err];
    }
    
    BOOL isExistDic =  [[NSFileManager defaultManager]fileExistsAtPath:wavfilepath];
    if (!isExistDic) {
        [[NSFileManager defaultManager] createDirectoryAtPath:wavfilepath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return writeFilePath;
}

- (NSString *)createFileName {
    NSString *audio_ScrName = [self.audioSrcPath lastPathComponent];
    NSArray *audioSrcNameArr = [audio_ScrName componentsSeparatedByString:@"."];
    NSString *audioSrcName = [audioSrcNameArr firstObject];
    if (audioSrcName.length <= 0) {
        audioSrcName = [NSString stringWithFormat:@"voiceFile%lld",(long long)[NSDate timeIntervalSinceReferenceDate]];
    }
    return audioSrcName;
}

@end
