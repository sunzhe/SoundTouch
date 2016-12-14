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

#import "Recorder.h"
#import "AudioDefine.h"

#ifdef SOUNDTOUCH_DEBUG
#define VSLog(log, ...) NSLog(log, ## __VA_ARGS__)
#else
#define VSLog(log, ...)
#endif
#define IOS7   ( [[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending )


@interface Recorder ()
{
    NSMutableArray *cacheDelegates;
    NSMutableArray *cacheURLs;
    NSTimer     *countDownTimer_;//定时器，每秒调用一次
}

@property(strong, nonatomic) AVAudioRecorder *audioRecorder;

@property(strong, nonatomic) NSMutableDictionary *cacheDic;

@end

@implementation Recorder
+(Recorder *)shareRecorder
{
    static Recorder *sharedRecorderInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedRecorderInstance = [[self alloc] init];
    });
    return sharedRecorderInstance;
}

-(BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if (IOS7)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                } else {
                    bCanRecord = NO;
                }
            }];
        }
    }
    
    return bCanRecord;
}


-(id)init
{
    self = [super init];
    if (self) {
        self.cacheDic = [NSMutableDictionary dictionaryWithCapacity:1];
        cacheDelegates = [[NSMutableArray alloc] init];
        cacheURLs = [[NSMutableArray alloc] init];
        [self resetTimerCount];
    }
    return self;
}

-(void)stopTimerCountRun
{
    if (countDownTimer_) {
        [countDownTimer_ invalidate];
        countDownTimer_ = nil;
    }
}
-(void)resetTimerCount
{
    [self stopTimerCountRun];
    countDownTimer_ = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timeCountDown) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:countDownTimer_ forMode:NSRunLoopCommonModes];
}
- (void)timeCountDown
{
    if (self.audioRecorder.isRecording) {
        //当前时间
        if ([self.recorderDelegate respondsToSelector:@selector(recorderCurrentTime:)]) {
            [self.recorderDelegate recorderCurrentTime:self.audioRecorder.currentTime];
        }
    }
}
#pragma mark - 广播停止录音
//停止录音
-(void)stopAVAudioRecord
{
    
}
-(void)startRecordWithFilePath:(NSString *)filePath
{
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error:nil];
    
    NSDictionary *recordSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: SampleRateKey],AVSampleRateKey, //采样率
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   [NSNumber numberWithInt:LinearPCMBitDepth],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                   [NSNumber numberWithInt: NumberOfChannels], AVNumberOfChannelsKey,//通道的数目,
                                   nil];
    
    
    NSURL *url = [NSURL fileURLWithPath:filePath];
    self.filePath = filePath;
    
    NSError *error = nil;
    if (self.audioRecorder) {
        if (self.audioRecorder.isRecording) {
            [self.audioRecorder stop];
        }
        self.audioRecorder = nil;
    }
    
    AVAudioRecorder *tmpRecord = [[ AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&error];
    self.audioRecorder = tmpRecord;
    self.audioRecorder.meteringEnabled = YES;
    self.audioRecorder.delegate = self;
    if ([self.audioRecorder prepareToRecord] == YES){
        self.audioRecorder.meteringEnabled = YES;
        [self.audioRecorder record];
        if ([self.recorderDelegate respondsToSelector:@selector(recorderStart)]) {
            [self.recorderDelegate recorderStart];
        }
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];//保持屏幕长亮
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
        
    }else {
        int errorCode = CFSwapInt32HostToBig ([error code]);
        VSLog(@"Error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode);
        
    }
}
-(void)startRecord
{
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(
                                                            NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    //录音文件名采用时间标记 例如"2015-01-06_12:41"
    self.filename = [self createFilename];
    NSString *soundFilePath = [docsDir
                               stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.wav",DefaultSubPath,self.filename]];
    
    [self createFilePath];
    [self startRecordWithFilePath:soundFilePath];
}

//创建录音文件名字
- (NSString *)createFilename {
    NSDate *date_ = [NSDate date];
    NSDateFormatter *dateformater = [[NSDateFormatter alloc] init];
    [dateformater setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    NSString *timeFileName = [dateformater stringFromDate:date_];
    return timeFileName;
}
//创建存储路径
-(void)createFilePath
{
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(
                                                            NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *savedImagePath = [docsDir
                                stringByAppendingPathComponent:DefaultSubPath];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:savedImagePath isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) )
    {
        [fileManager createDirectoryAtPath:savedImagePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}


-(void)stopRecord
{
    if (self.audioRecorder) {
        if ([self.recorderDelegate respondsToSelector:@selector(recorderStop:voiceName:duration:)]) {
            [self.recorderDelegate recorderStop:self.filePath voiceName:self.filename duration:self.audioRecorder.currentTime];
        }
        self.recorderDelegate = nil;
        [self.audioRecorder stop];
        
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:NO error:nil];
        [session setCategory:AVAudioSessionCategoryAmbient error:nil];
    }
}
-(float)getPeakPower
{
    [self.audioRecorder updateMeters];
    float linear = pow (10, [self.audioRecorder peakPowerForChannel:0] / 20);
    float linear1 = pow (10, [self.audioRecorder averagePowerForChannel:0] / 20);
    float Pitch = 0;
    if (linear1>0.03) {
        
        Pitch = linear1+.20;//pow (10, [audioRecorder averagePowerForChannel:0] / 20);//[audioRecorder peakPowerForChannel:0];
    }
    else {
        
        Pitch = 0.0;
    }
    float peakPowerForChannel = (linear + 160)/160;
    return peakPowerForChannel;
}
-(void)dealloc
{
    self.audioRecorder = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark -
#pragma mark AVAudioRecorderDelegate Methods
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];
    if (flag) {
        if ([self.recorderDelegate respondsToSelector:@selector(recorderStop:voiceName:duration:)]) {
            [self.recorderDelegate recorderStop:self.filePath voiceName:self.filename duration:self.audioRecorder.currentTime];
        }
        self.recorderDelegate = nil;
    }else{
        if ([self.recorderDelegate respondsToSelector:@selector(recorderStop:voiceName:duration:)]) {
            [self.recorderDelegate recorderStop:self.filePath voiceName:self.filename duration:self.audioRecorder.currentTime];
        }
        self.recorderDelegate = nil;
    }
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:NO error:nil];
    [session setCategory:AVAudioSessionCategoryAmbient error:nil];
}
-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];
    
    if ([self.recorderDelegate respondsToSelector:@selector(recorderStop:voiceName:duration:)]) {
        [self.recorderDelegate recorderStop:self.filePath voiceName:self.filename duration:self.audioRecorder.currentTime];
    }
    self.recorderDelegate = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:NO error:nil];
    [session setCategory:AVAudioSessionCategoryAmbient error:nil];
}

@end
