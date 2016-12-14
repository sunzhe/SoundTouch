//
//  AudioDefine.h
//  SoundTouchDemo
//
//  Created by chuliangliang on 15-2-10.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//

#ifndef SoundTouchDemo_AudioDefine_h
#define SoundTouchDemo_AudioDefine_h

#warning 由于使用了苹果的音频解码库 导致 Preprocessor Macros 参数清空 这里手动开启Debug 发布时需要及时改正

#define SOUNDTOUCH_DEBUG 1

#ifdef SOUNDTOUCH_DEBUG
#define CNLog(log, ...) NSLog(log, ## __VA_ARGS__)
#else
#define CNLog(log, ...)
#endif

#endif
