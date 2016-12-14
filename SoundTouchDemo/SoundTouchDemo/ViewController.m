/*
 ReadMe.strings
 
 Created by chuliangliang on 15-1-14.
 Copyright (c) 2014年 aikaola. All rights reserved.
 */

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
 **/#import "ViewController.h"
#import "Recorder.h"



#import "SVProgressHUD.h"

@interface ViewController () <AVAudioPlayerDelegate,AudioConvertDelegate>
{
    BOOL isPlayRecoder; //是否播放的是录音
    AudioConvertOutputFormat outputFormat; //输出音频格式
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    sayBeginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sayBeginBtn.backgroundColor = [UIColor redColor];
    [sayBeginBtn setTitle:@"开始录音" forState:UIControlStateNormal];
    sayBeginBtn.frame = CGRectMake(10, screenRect.size.height-90, 300, 30);
    [sayBeginBtn addTarget:self action:@selector(buttonSayBegin:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sayBeginBtn];
    
    sayEndBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sayEndBtn.backgroundColor = [UIColor greenColor];
    [sayEndBtn setTitle:@"停止录音" forState:UIControlStateNormal];
    sayEndBtn.frame = CGRectMake(10, screenRect.size.height-90, 300, 30);
    [sayEndBtn addTarget:self action:@selector(buttonSayEnd:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sayEndBtn];
    sayEndBtn.hidden = YES;
    
    playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playBtn.backgroundColor = [UIColor blueColor];
    [playBtn setTitle:@"播放效果" forState:UIControlStateNormal];
    playBtn.frame = CGRectMake(10, screenRect.size.height-90, 300, 30);
    [playBtn addTarget:self action:@selector(buttonPlay:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playBtn];
    playBtn.hidden = YES;
    
    
    reSayEndBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    reSayEndBtn.backgroundColor = [UIColor purpleColor];
    [reSayEndBtn setTitle:@"重新录音/停止播放" forState:UIControlStateNormal];
    reSayEndBtn.frame = CGRectMake(10, screenRect.size.height- 50, 300, 30);
    [reSayEndBtn addTarget:self action:@selector(buttonReSayBegin) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reSayEndBtn];

    
    audioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    audioBtn.backgroundColor = [UIColor blueColor];
    [audioBtn setTitle:@"播放文件" forState:UIControlStateNormal];
    audioBtn.frame = CGRectMake(10, screenRect.size.height-140, 300, 30);
    [audioBtn addTarget:self action:@selector(buttonPlayFlie:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:audioBtn];
    
    
    self.segController.selectedSegmentIndex = 0;
    outputFormat = AudioConvertOutputFormat_WAV;
    
    CGRect tmpRect = self.countDownLabel.frame;
    tmpRect.origin.y = screenRect.size.height - 140 - tmpRect.size.height;
    self.countDownLabel.frame = tmpRect;
    
    UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(16,
                                                                  self.segController.frame.origin.y + self.segController.frame.size.height,
                                                                  screenRect.size.width - 32,
                                                                  self.countDownLabel.frame.origin.y - (self.segController.frame.origin.y + self.segController.frame.size.height))];
    msgLabel.textColor = [UIColor redColor];
    msgLabel.textAlignment = NSTextAlignmentCenter;
    msgLabel.numberOfLines = 0;
    msgLabel.text = @"变声过程时间长短取决于音频文件的采样率请耐心等待\n注意: 目前输入音频的格式已经支持大部分常用的音频格式,输出音频目前只支持 wav、mp3、amr 更多音频格式在以后会陆续增加😊";
    msgLabel.font = [UIFont systemFontOfSize:10.0f];
    [self.view insertSubview:msgLabel atIndex:0];
    [msgLabel release];
    
    tempoChangeNum = 0;
    pitchSemiTonesNum= 0;
    rateChangeNum = 0;
    
    timeManager = [DotimeManage DefaultManage];
    [timeManager setDelegate:self];
    

}

//处理音频文件
- (void)buttonPlayFlie:(UIButton *)btn
{
    [self stopAudio];
    [[Recorder shareRecorder] stopRecord];

    [audioBtn setTitle:@"文件处理中..." forState:UIControlStateNormal];
    isPlayRecoder = NO;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeNone];
    
    NSString *p =  [[NSBundle mainBundle] pathForResource:@"一生无悔高安" ofType:@"mp3"];
    AudioConvertConfig dconfig;
    dconfig.sourceAuioPath = [p UTF8String];
    dconfig.outputFormat = outputFormat;
    dconfig.outputChannelsPerFrame = 1;
    dconfig.outputSampleRate = 22050;
    dconfig.soundTouchPitch = pitchSemiTonesNum;
    dconfig.soundTouchRate = rateChangeNum;
    dconfig.soundTouchTempoChange = tempoChangeNum;
    [[AudioConvert shareAudioConvert] audioConvertBegin:dconfig withCallBackDelegate:self];


}


 //时间改变
- (void)TimerActionValueChange:(int)time
{
    
    if (time == 30) {
        
        [timeManager stopTimer];
        
        sayBeginBtn.hidden = YES;
        sayEndBtn.hidden = YES;
        playBtn.hidden = NO;
        reSayEndBtn.hidden = NO;
        
        [[Recorder shareRecorder] stopRecord];
    }
    if (time > 30) time = 30;
    
    self.countDownLabel.text = [NSString stringWithFormat:@"时间: %02d",time];

}

//重置 页面/ 数据
- (void)buttonReSayBegin
{
    
    sayBeginBtn.hidden = NO;
    sayEndBtn.hidden = YES;
    playBtn.hidden = YES;
    self.countDownLabel.text = @"时间";
    [self stopAudio];
    [SVProgressHUD dismiss];
    
    [[AudioConvert shareAudioConvert] cancelAllThread];
}

//开始录音
- (void)buttonSayBegin:(id)sender
{
    //录音
    [self stopAudio];
    
    sayBeginBtn.hidden = YES;
    sayEndBtn.hidden = NO;
    playBtn.hidden = YES;
    reSayEndBtn.hidden = YES;
    
    [timeManager setTimeValue:30];
    [timeManager startTime];

    [[Recorder shareRecorder] startRecord];
}


//录音结束
- (void)buttonSayEnd:(id)sender
{
    [timeManager stopTimer];
    
    sayBeginBtn.hidden = YES;
    sayEndBtn.hidden = YES;
    playBtn.hidden = NO;
    reSayEndBtn.hidden = NO;
  
    [[Recorder shareRecorder] stopRecord];
}

//录音播放
- (void)buttonPlay:(UIButton *)sender
{
    NSLog(@"播放音效");
    [self stopAudio];
    isPlayRecoder = YES;
    [playBtn setTitle:@"处理中..." forState:UIControlStateNormal];

    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeNone];
    
    NSString *p =  [Recorder shareRecorder].filePath;
    AudioConvertConfig dconfig;
    dconfig.sourceAuioPath = [p UTF8String];
    dconfig.outputFormat = outputFormat;
    dconfig.outputChannelsPerFrame = 1;
    dconfig.outputSampleRate = 22050;
    dconfig.soundTouchPitch = pitchSemiTonesNum;
    dconfig.soundTouchRate = rateChangeNum;
    dconfig.soundTouchTempoChange = tempoChangeNum;
    [[AudioConvert shareAudioConvert] audioConvertBegin:dconfig withCallBackDelegate:self];
    
}


#pragma mark - 变声参数...
- (IBAction)tempoChangeValue:(UISlider *)sender {
    int value = (int)sender.value;
    self.tempoChangeLabel.text = [NSString stringWithFormat:@"setTempoChange: %d",value];
    tempoChangeNum = value;
}


- (IBAction)pitchSemitonesValue:(UISlider *)sender {
    int value = (int)sender.value;
    self.pitchSemitonesLabel.text = [NSString stringWithFormat:@"setPitchSemiTones: %d",value];
    pitchSemiTonesNum = value;

}
- (IBAction)rateChangeValue:(UISlider *)sender {
    
    int value = (int)sender.value;
    self.rateChangeLabel.text = [NSString stringWithFormat:@"setRateChange: %d",value];
    rateChangeNum = value;

}



//播放
- (void)playAudio:(NSString *)path {
    
    NSString *audioName = [path lastPathComponent];
                           
    if ([audioName rangeOfString:@"amr"].location != NSNotFound) {
        UIAlertView *aler = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"输出音频: %@ \n iOS 设备不能直接播放amr 格式音频",audioName] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [aler show];
        [aler release];
        [SVProgressHUD dismiss];
        [self stopAudio];
        return;
    }else {
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"文件名: %@",audioName ]];
    }

    
    if (!isPlayRecoder) {
        [audioBtn setTitle:@"播放文件中..." forState:UIControlStateNormal];
    }else {
        [playBtn setTitle:@"播放效果中..." forState:UIControlStateNormal];
    }
    NSURL *url = [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSError *err = nil;
    if (audioPalyer) {
        [audioPalyer stop];
        audioPalyer = nil;
    }
    audioPalyer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    audioPalyer.delegate = self;
    [audioPalyer play];
}
//停止播放
- (void)stopAudio {
    if (audioPalyer) {
        [audioPalyer stop];
        audioPalyer = nil;
    }
    [audioBtn setTitle:@"播放文件" forState:UIControlStateNormal];
    [playBtn setTitle:@"播放效果" forState:UIControlStateNormal];
}

#pragma mak - 播放回调代理
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"恢复音效按钮");
    
    [audioBtn setTitle:@"播放文件" forState:UIControlStateNormal];
    [playBtn setTitle:@"播放效果" forState:UIControlStateNormal];
}




#pragma mark - AudioConvertDelegate
- (BOOL)audioConvertOnlyDecode
{
    return  NO;
}
- (BOOL)audioConvertHasEnecode
{
    return YES;
}


/**
 * 对音频解码动作的回调
 **/
- (void)audioConvertDecodeSuccess:(NSString *)audioPath {
    //解码成功
    [self playAudio:audioPath];
}
- (void)audioConvertDecodeFaild
{
    //解码失败
    [SVProgressHUD showErrorWithStatus:@"解码失败"];
    [self stopAudio];
}


/**
 * 对音频变声动作的回调
 **/
- (void)audioConvertSoundTouchSuccess:(NSString *)audioPath
{
    //变声成功
    [self playAudio:audioPath];
}


- (void)audioConvertSoundTouchFail
{
    //变声失败
    [SVProgressHUD showErrorWithStatus:@"变声失败"];
    [self stopAudio];
}




/**
* 对音频编码动作的回调
**/

- (void)audioConvertEncodeSuccess:(NSString *)audioPath
{
    //编码完成
    [self playAudio:audioPath];
}

- (void)audioConvertEncodeFaild
{
    //编码失败
    [SVProgressHUD showErrorWithStatus:@"编码失败"];
    [self stopAudio];
}


- (IBAction)segChanged:(UISegmentedControl *)sender {
   
    int selectIndex = (int)sender.selectedSegmentIndex;
    switch (selectIndex) {
        case 0:
            outputFormat = AudioConvertOutputFormat_WAV;
            break;
        case 1:
            outputFormat = AudioConvertOutputFormat_MP3;
            break;
        case 2:
            outputFormat = AudioConvertOutputFormat_AMR;
            break;
        default:
            break;
    }
}
@end
