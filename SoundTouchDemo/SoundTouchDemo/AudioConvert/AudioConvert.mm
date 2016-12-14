//
//  AudioConvert.m
//  SoundTouchDemo
//
//  Created by chuliangliang on 15-1-29.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//
#import "AudioConvert.h"
#import "amrFileCodec.h"

const int SoundTouchSampleRate = 8000; //soundTouch 变声处理的 使用的采样率 目的 速度快

typedef NS_ENUM(NSInteger, AudioConvertType) {
    AudioConvertType_Decode = 110,//解码文件存储
    AudioConvertType_SoundTouch,  //变声文件存储
    AudioConvertType_Encode,      //编码文件储存
    AudioConvertType_TmpEncode,   //编码文件临时储存
};


@interface AudioConvert ()
{
    NSOperationQueue *audioQue;
    AudioConvertConfig myConfig;
    BOOL hasGo; //标记是否 分布进行 YES 不分步骤 NO 分步骤
    
    AudioConvertOutputFormat *outFormat; //输出文件格式
}
@property (assign, nonatomic) id<AudioConvertDelegate>delegate;
@property (retain, nonatomic) NSString *outFileName;
@property (retain, nonatomic) NSString *sourcePath;

@end

@implementation AudioConvert
static AudioConvert *audioConvert = nil;
+ (AudioConvert *)shareAudioConvert
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioConvert = [[AudioConvert alloc] init];
    });
    return audioConvert;
}

//==============================================================================
//TODO: 结束所有子线程
//==============================================================================
- (void)cancelAllThread
{
    if (audioQue) {
        self.delegate = nil;
        [audioQue cancelAllOperations];
    }
}

- (NSOperationQueue *)myAudioQue {
    if (!audioQue) {
        audioQue = [[NSOperationQueue alloc] init];
        audioQue.maxConcurrentOperationCount = 1;
    }
    return audioQue;
}

//==============================================================================
//TODO: 变声的完成流程入口
//==============================================================================

- (void)audioConvertBegin:(AudioConvertConfig )config withCallBackDelegate:(id)aDelegate
{
    myConfig = config;
    self.delegate = aDelegate;
    hasGo = YES;
    [self installation];
}

//==============================================================================
//TODO: 音频解码入口
//==============================================================================
- (void)audioConvertBeginDecode:(NSString *)sourceAudioPath withCallBackDelegate:(id)aDelegate
{
    
    AudioConvertConfig config;
    config.sourceAuioPath = (!sourceAudioPath || sourceAudioPath.length <= 0) ? [@"" UTF8String] : [sourceAudioPath UTF8String];
    myConfig = config;
    self.delegate = aDelegate;
    hasGo = NO;
    [self installation];

}

//==============================================================================
//TODO: 对已经解码的音频进行变声的入口
//==============================================================================
- (void)audioConvertBeginSoundTouch:(NSString *)sourceAudioPath withCallBackDelegate:(id)aDelegate
                   audioTempoChange:(int)tempoChange
                         audioPitch:(int)pitch
                          audioRate:(int)rate
{
    
    if (sourceAudioPath && sourceAudioPath.length <= 0) {
        if ([self.delegate respondsToSelector:@selector(audioConvertSoundTouchFail)]) {
            [self.delegate audioConvertSoundTouchFail];
        }
        return;
    }
    hasGo = NO;
    self.delegate = aDelegate;
    self.outFileName = [self getFileFirstName:sourceAudioPath];
    
    myConfig.soundTouchPitch = pitch;
    myConfig.soundTouchRate = rate;
    myConfig.soundTouchTempoChange = tempoChange;
 
    [self soundTouchBengin:sourceAudioPath];
}

//==============================================================================
//TODO: 对未编码的音频进行编码
//==============================================================================
- (void)audioConvertBeginEncode:(NSString *)sourceAudioPath
           withCallBackDelegate:(id)aDelegate
          audioOutputSampleRate:(Float64)sampleRate
              audioOutputFormat:(AudioConvertOutputFormat)format
    audioOutputChannelsPerFrame:(int)channels
{
    hasGo = NO;
    self.delegate = aDelegate;
    self.outFileName = [self getFileFirstName:sourceAudioPath];
    
    myConfig.outputFormat = format;
    myConfig.outputChannelsPerFrame = channels;
    myConfig.outputSampleRate = sampleRate;
    
    [self audioConvertStartEncode:sourceAudioPath];
}


- (void)installation {
    
    /**
     * 流程
     *      1、解码音频源 成指定 格式
     *      2、进行变声
     *      3 对音频进行指定格式编码 如果 需要编码成 MP3 需要将音频转为双通道 否则会导致 音频变速
     **/
    if (myConfig.sourceAuioPath == NULL || myConfig.sourceAuioPath[0] == '\0') {
        if ([self.delegate respondsToSelector:@selector(audioConvertDecodeFaild)]) {
            [self.delegate audioConvertDecodeFaild];
        }
        return;
    }
    
    NSString *sourcePath = [NSString stringWithUTF8String:myConfig.sourceAuioPath];
    self.outFileName = [self getFileFirstName:sourcePath];
    
    NSString *audioDecodeOutputPath = [self createSavePathWithType:AudioConvertType_Decode];
    AudioDecodeOperation *audioDecode = [[AudioDecodeOperation alloc] initWithSourcePath:sourcePath
                                                                         audioOutputPath:audioDecodeOutputPath
                                                                        outputSampleRate:SoundTouchSampleRate
                                                                           outputChannel:1
                                                                          callBackTarget:self
                                                                            callFunction:@selector(didDecode:)];
    [[self myAudioQue] cancelAllOperations];
    [[self myAudioQue] addOperation:audioDecode];
    
}

//==============================================================================
//TODO: 音频解码回调 单声道解码处理
//==============================================================================
- (void)didDecode:(NSString *)tmpPath
{
    if (!tmpPath) {
        //解码失败
        if ([self.delegate respondsToSelector:@selector(audioConvertDecodeFaild)]) {
            [self.delegate audioConvertDecodeFaild];
        }
        return;
    }
    
    BOOL isOnlyAudioDecode = NO;
    if (hasGo && [self.delegate respondsToSelector:@selector(audioConvertOnlyDecode)]) {
        isOnlyAudioDecode = [self.delegate audioConvertOnlyDecode];
    }else {
        isOnlyAudioDecode = YES;
    }
    
    if (isOnlyAudioDecode) {
        //解码成功 回调
        if ([self.delegate respondsToSelector:@selector(audioConvertDecodeSuccess:)]) {
            [self.delegate audioConvertDecodeSuccess:tmpPath];
        }
    }else {
        [self soundTouchBengin:tmpPath];
    }
}

//==============================================================================
//TODO: 音频变声
//==============================================================================
- (void)soundTouchBengin:(NSString *)filePath {
    
    NSString *soundParh = [self createSavePathWithType:AudioConvertType_SoundTouch];
    AudioSoundTouchOperation *soundTouch = [[AudioSoundTouchOperation alloc] initWithTarget:self
                                                                                     action:@selector(soundTouchFinish:)
                                                                                 sourcePath:filePath audioOutputPath:soundParh
                                                                            audioSampleRate:SoundTouchSampleRate
                                                                           audioTempoChange:myConfig.soundTouchTempoChange
                                                                                 audioPitch:myConfig.soundTouchPitch
                                                                                  audioRate:myConfig.soundTouchRate
                                                                              audioChannels:1];
    [[self myAudioQue] cancelAllOperations];
    [[self myAudioQue] addOperation:soundTouch];
    
}
//变声回调
- (void)soundTouchFinish:(NSString *)stPath {
    if (!stPath) {
        //变声失败
        if ([self.delegate respondsToSelector:@selector(audioConvertSoundTouchFail)]) {
            [self.delegate audioConvertSoundTouchFail];
        }
        return;
    }
    
    BOOL hasAuidoEncode = YES;
    if (hasGo && [self.delegate respondsToSelector:@selector(audioConvertHasEnecode)]) {
        hasAuidoEncode = [self.delegate audioConvertHasEnecode];
    }else {
        hasAuidoEncode = NO;
    }
    
    if (!hasAuidoEncode) {
        //变声成功
        if ([self.delegate respondsToSelector:@selector(audioConvertSoundTouchSuccess:)]) {
            [self.delegate audioConvertSoundTouchSuccess:stPath];
        }
        return;
    }
    
    //开始编码
    [self audioConvertStartEncode:stPath];
}

//==============================================================================
// TODO: 音频 编码 总入口
//==============================================================================
- (void)audioConvertStartEncode:(NSString *)sourcePath {
    
    if (!sourcePath && sourcePath.length <= 0) {
        if ([self.delegate respondsToSelector:@selector(audioConvertEncodeFaild)]) {
            [self.delegate audioConvertEncodeFaild];
        }
        return;
    }
    
    int outputType = myConfig.outputFormat;
    switch (outputType) {
        case AudioConvertOutputFormat_WAV:
        {
            [self audioConvertDecodeToWav:sourcePath];
        }
            break;
        case AudioConvertOutputFormat_MP3:
        {
            [self audioConvertDecodoDoubleChannel:sourcePath];
        }
            break;
        case AudioConvertOutputFormat_AMR:
        {
            [self audioConvertDecodeToAmr:sourcePath];
        }
            break;
            
        default:
            break;
    }
}


//==============================================================================
// TODO: 音频 编码 <AMR>
//==============================================================================
- (void)audioConvertDecodeToAmr:(NSString *)sourcePath {
    NSString *path = sourcePath;
    
    NSString *amrSavePath = [self createSavePathWithType:AudioConvertType_Encode];
    int result = EncodeWAVEFileToAMRFile([path cStringUsingEncoding:NSUTF8StringEncoding], [amrSavePath cStringUsingEncoding:NSUTF8StringEncoding], 1, 16);
    if (result)
    {
        if ([self.delegate respondsToSelector:@selector(audioConvertEncodeSuccess:)]) {
            [self.delegate  audioConvertEncodeSuccess:amrSavePath];
        }
    }else {
        if ([self.delegate respondsToSelector:@selector(audioConvertEncodeFaild)]) {
            [self.delegate  audioConvertEncodeFaild];
        }

    }
}

//==============================================================================
// TODO: 音频 编码 <WAV>
//==============================================================================
- (void)audioConvertDecodeToWav:(NSString *)sourcePath
{
    //处理方式 为 直接转化 不需要 编码因为 wav 本身就是未编码音频
    NSString *audioEncodePath = [self createSavePathWithType:AudioConvertType_Encode];
    AudioDecodeOperation *audioDecode = [[AudioDecodeOperation alloc] initWithSourcePath:sourcePath
                                                                         audioOutputPath:audioEncodePath
                                                                        outputSampleRate:myConfig.outputSampleRate
                                                                           outputChannel:myConfig.outputChannelsPerFrame
                                                                          callBackTarget:self
                                                                            callFunction:@selector(audioconvertEncodeFinish:)];
    [[self myAudioQue] cancelAllOperations];
    [[self myAudioQue] addOperation:audioDecode];

}

//==============================================================================
// TODO: 音频 编码 <mp3>
//==============================================================================

//mp3 比较特殊 需要的 音频必须是 通道数必须为 2 否则 导致 音频变速
- (void)audioConvertDecodoDoubleChannel:(NSString *)audioPath {
    
    NSString *audioEncodeTmpPath = [self createSavePathWithType:AudioConvertType_TmpEncode];
    AudioDecodeOperation *audioDecode = [[AudioDecodeOperation alloc] initWithSourcePath:audioPath
                                                                         audioOutputPath:audioEncodeTmpPath
                                                                        outputSampleRate:myConfig.outputSampleRate
                                                                           outputChannel:2
                                                                          callBackTarget:self
                                                                            callFunction:@selector(audioconvertDecodoDoubleChannelFinish:)];
    [[self myAudioQue] cancelAllOperations];
    [[self myAudioQue] addOperation:audioDecode];


}
//MP3 编码前的 处理 回调
- (void)audioconvertDecodoDoubleChannelFinish:(NSString *)audioPath {
    if (!audioPath) {
        //失败 这个失败 是 对 MP3 文件 编码之前的 解码操作 如果失败 回调 编码失败 代理
        if ([self.delegate respondsToSelector:@selector(audioConvertEncodeFaild)]) {
            [self.delegate audioConvertEncodeFaild];
        }
        return;
    }
    //真正的编码正式开始了
    NSString *audioEncodeOutputPath = [self createSavePathWithType:AudioConvertType_Encode];
    AudioEncodeOperation *enCode = [[AudioEncodeOperation alloc] initWithTarget:self
                                                                         action:@selector(audioconvertEncodeFinish:)
                                                                   audioSrcPath:audioPath
                                                                audioOutputPath:audioEncodeOutputPath
                                                                audioSampleRate:(int)myConfig.outputSampleRate
                                                          outputAudioSampleRate:(int)myConfig.outputSampleRate
                                                                  audioChannels:2];
    
    [[self myAudioQue] cancelAllOperations];
    [[self myAudioQue] addOperation:enCode];

}

// mp3 、wav 编码 回调
- (void)audioconvertEncodeFinish:(NSString *)audioPath {
    if (!audioPath) {
        // 编码失败
        if ([self.delegate respondsToSelector:@selector(audioConvertEncodeFaild)]) {
            [self.delegate audioConvertEncodeFaild];
        }
        return;
    }
    
    //编码成功
    if ([self.delegate respondsToSelector:@selector(audioConvertEncodeSuccess:)]) {
        [self.delegate audioConvertEncodeSuccess:audioPath];
    }
}


//==============================================================================
//TODO: 文件路径创建与获取
//==============================================================================
- (NSString *)getFileFirstName:(NSString *)filePath {
    NSString *srcName = [filePath lastPathComponent];
    NSArray *srcNameArr = [srcName componentsSeparatedByString:@"."];
    NSString *firstName = [srcNameArr firstObject];
    if (!firstName && firstName.length <= 0) {
        firstName = @"audioFile";
    }
    return firstName;
}

#pragma mark - 文件路径创建与获取
//获取文件名 文件名使用 "输入文件名.文件类型拓展"
- (NSString *)getoutFileNameWith:(AudioConvertType )atype {
    
    NSString *firstName = self.outFileName;
    NSString *lastName = @"";
    NSString *fileName = @"";
    
    if (atype == AudioConvertType_Encode) {
        int type = myConfig.outputFormat;
        switch (type) {
            case AudioConvertOutputFormat_MP3:
                lastName = @"mp3";
                break;
            case AudioConvertOutputFormat_AMR:
                lastName = @"amr";
                break;
            case AudioConvertOutputFormat_WAV:
                lastName = @"wav";
                break;
            default:
                break;
        }
    }else if (atype == AudioConvertType_TmpEncode) {
        lastName = @"tmp";
    }else {
        lastName = @"wav";
    }
    if (lastName.length > 0) {
        fileName = [NSString stringWithFormat:@"%@.%@",firstName,lastName];
    }else {
        fileName = firstName;
    }
    return fileName;
}


//获取输出路径
- (NSString *)getAudioOutPutPathWith:(AudioConvertType )type {
    
    NSString *outPath = @"";
    switch (type) {
        case AudioConvertType_Decode:
            outPath = OUTPUT_DECODEPATH;
            break;
          case AudioConvertType_SoundTouch:
            outPath = OUTPUT_SOUNDTOUCHPATH;
            break;
            case AudioConvertType_Encode:
            outPath = OUTPUT_ENCODEPATH;
            break;
        case AudioConvertType_TmpEncode:
            outPath = OUTPUT_ENCODETMPPATH;
            break;
        default:
            break;
    }
    return outPath;
}



//创建文件存储路径
- (NSString *)createSavePathWithType:(AudioConvertType )type {
    NSString *dicPath = [self getAudioOutPutPathWith:type];
    NSString *fileName = [self getoutFileNameWith:type];
    NSString *outputPath = [NSString stringWithFormat:@"%@/%@",dicPath,fileName];
    
    BOOL isExistDic =  [[NSFileManager defaultManager]fileExistsAtPath:dicPath];
    if (!isExistDic) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dicPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    BOOL isExist =  [[NSFileManager defaultManager]fileExistsAtPath:outputPath];
    if (isExist) {
        //如果存在则移除 以防止 文件冲突
        NSError *err = nil;
        [[NSFileManager defaultManager]removeItemAtPath:outputPath error:&err];
    }
    return outputPath;
}

@end
