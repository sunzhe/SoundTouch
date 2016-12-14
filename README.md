 *      一款对音频处理的软件, 包括: 音频解码 、音频变声、音频编码; 此软件以技术研究为主要目的 使用简单只需要引入 AudioConvert.h 即可;
 *    由于使用了苹果的音频解码库 会导致 CADebugPrintf.h 文件找不到,解决方式 清空工程文件 Preprocessor Macros 参数, 本软件Debug 模式的开启和关闭 在AudioDefine中手动控制

 * 功能: 
 *      1)常见音频格式解码 (输入音频格式: 常见音频格式均可)
 *      2)音频变声处理
 *      3)指定音频格式编码处理 (输出音频格式 MP3 WAV AMR)
 *
 * 系统类库: AVFoundation.framework 、AudioToolbox.framework
 *
 * 第三方类库: SoundTouch (变声处理库)、 lame (MP3编码库)
 *

主要使用框架 soundTouch （音频变声处理） SpeakHere （苹果官方音频解码库） lame （MP3 音频编码库  已处理成支持 arm64 x86_64) libopencore (arm,wav互转 支持 arm64 x86_64)