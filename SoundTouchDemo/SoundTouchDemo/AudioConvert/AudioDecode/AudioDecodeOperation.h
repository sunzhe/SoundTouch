//
//  AudioDecodeOperation.h
//  SoundTouchDemo
//
//  Created by chuliangliang on 15-1-29.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioDefine.h"

@interface AudioDecodeOperation : NSOperation
- (id)initWithSourcePath:(NSString *)spath
         audioOutputPath:(NSString *)opath
        outputSampleRate:(Float64)slr
           outputChannel:(int)ch
          callBackTarget:(id)target
            callFunction:(SEL)action;
@end
