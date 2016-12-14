/*
 ReadMe.strings
 
 Created by chuliangliang on 15-1-14.
 Copyright (c) 2014年 aikaola. All rights reserved.
 */
/**
 * 说明:
 *      一款对音频处理的软件, 包括: 音频解码 、音频变声、音频编码; 此软件以技术研究为主要目的
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

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DotimeManage.h"



#import "AudioConvert.h"

@interface ViewController : UIViewController<DotimeManageDelegate>
{
    UIButton *sayBeginBtn;
    UIButton *sayEndBtn;
    UIButton *reSayEndBtn;
    UIButton *playBtn;
    UIButton *audioBtn;
    UIButton *audiDencodeButton;
    AVAudioPlayer *audioPalyer;
    
    
    /*
     * 初始值 均为0
     */
    int tempoChangeNum;
    int pitchSemiTonesNum;
    int rateChangeNum;
    DotimeManage *timeManager;
    
    
}


@property (retain, nonatomic) IBOutlet UILabel *tempoChangeLabel;
@property (retain, nonatomic) IBOutlet UISlider *tempoChangeSlide;
- (IBAction)tempoChangeValue:(id)sender;


@property (retain, nonatomic) IBOutlet UILabel *pitchSemitonesLabel;
@property (retain, nonatomic) IBOutlet UISlider *pitchSemitonesSlide;
- (IBAction)pitchSemitonesValue:(id)sender;


@property (retain, nonatomic) IBOutlet UILabel *rateChangeLabel;
@property (retain, nonatomic) IBOutlet UISlider *rateChangeSlide;
- (IBAction)rateChangeValue:(id)sender;


@property (retain, nonatomic) IBOutlet UILabel *countDownLabel;


@property (retain, nonatomic) IBOutlet UISegmentedControl *segController;
- (IBAction)segChanged:(UISegmentedControl *)sender;
@end
