//
//  AudioDecodeOperation.m
//  SoundTouchDemo
//
//  Created by chuliangliang on 15-1-29.
//  Copyright (c) 2015年 chuliangliang. All rights reserved.
//

#import "AudioDecodeOperation.h"


// helpers
#import "CAXException.h"
#import "CAStreamBasicDescription.h"

#import <pthread.h>



@interface AudioDecodeOperation ()
{
    id my_target;
    SEL my_action;
    int audioChannel;
    Float64 sampleRate;
}
@property (strong, nonatomic) NSString *outputPath;
@property (strong, nonatomic) NSString *srcPath;

@end

@implementation AudioDecodeOperation
- (id)initWithSourcePath:(NSString *)spath
         audioOutputPath:(NSString *)opath
        outputSampleRate:(Float64)slr
           outputChannel:(int)ch
          callBackTarget:(id)target
            callFunction:(SEL)action
{
    self = [super init];
    if (self) {
        my_action = action;
        my_target = target;
        sampleRate = slr;
        self.outputPath = opath;
        self.srcPath = spath;
        
        audioChannel = ch;
    }
    return self;
}

- (void)main {
    
    CFURLRef sourceURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)self.srcPath, kCFURLPOSIXPathStyle, false);
    CFURLRef outputURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)self.outputPath, kCFURLPOSIXPathStyle, false);
    
    [self  doConvert:sourceURL outPuturl:outputURL outputFormat:kAudioFormatLinearPCM outputSampleRate:sampleRate mChannelsPerFrame:audioChannel];
}

- (OSStatus)doConvert:(CFURLRef )sourceURL outPuturl:(CFURLRef )outPutURL outputFormat:(OSType )outputFormat outputSampleRate:(Float64)slr mChannelsPerFrame:(int)mChannels
{
    ExtAudioFileRef sourceFile = 0;
    ExtAudioFileRef destinationFile = 0;
    Boolean         canResumeFromInterruption = true; // we can continue unless told otherwise
    OSStatus        error = noErr;
    
    BOOL isSuccess = YES; //是否处理成功
    
    CNLog(@"AudioDecode-Debug: DoConvertFile");
    
    try {
        CAStreamBasicDescription srcFormat, dstFormat;
        
        // open the source file
        XThrowIfError(ExtAudioFileOpenURL(sourceURL, &sourceFile), "ExtAudioFileOpenURL failed");
        
        // get the source data format
        UInt32 size = sizeof(srcFormat);
        XThrowIfError(ExtAudioFileGetProperty(sourceFile, kExtAudioFileProperty_FileDataFormat, &size, &srcFormat), "couldn't get source data format");
        
        CNLog(@"AudioDecode-Debug: Source file format: "); srcFormat.Print();
        
        // setup the output file format
        dstFormat.mSampleRate = (slr == 0 ? srcFormat.mSampleRate : slr); // set sample rate
        if (outputFormat == kAudioFormatLinearPCM) {
            // if PCM was selected as the destination format, create a 16-bit int PCM file format description
            dstFormat.mFormatID = outputFormat;
            dstFormat.mChannelsPerFrame = mChannels; //srcFormat.NumberChannels()
            dstFormat.mBitsPerChannel = 16;
            dstFormat.mBytesPerPacket = dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame;
            dstFormat.mFramesPerPacket = 1;
            dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger; // little-endian
        } else {
            // compressed format - need to set at least format, sample rate and channel fields for kAudioFormatProperty_FormatInfo
            dstFormat.mFormatID = outputFormat;
            dstFormat.mChannelsPerFrame =  (outputFormat == kAudioFormatiLBC ? 1 : mChannels); // srcFormat.NumberChannels() for iLBC num channels must be 1
            
            // use AudioFormat API to fill out the rest of the description
            size = sizeof(dstFormat);
            XThrowIfError(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &dstFormat), "couldn't create destination data format");
        }
        
        CNLog(@"AudioDecode-Debug: Destination file format: "); dstFormat.Print();
        
        // create the destination file
        XThrowIfError(ExtAudioFileCreateWithURL(outPutURL, kAudioFileCAFType, &dstFormat, NULL, kAudioFileFlags_EraseFile, &destinationFile), "ExtAudioFileCreateWithURL failed!");
        
        // set the client format - The format must be linear PCM (kAudioFormatLinearPCM)
        // You must set this in order to encode or decode a non-PCM file data format
        // You may set this on PCM files to specify the data format used in your calls to read/write
        CAStreamBasicDescription clientFormat;
        if (outputFormat == kAudioFormatLinearPCM) {
            clientFormat = dstFormat;
        } else {
            clientFormat.SetCanonical(srcFormat.NumberChannels(), true);
            clientFormat.mSampleRate = srcFormat.mSampleRate;
        }
        
        CNLog(@"AudioDecode-Debug: Client data format: "); clientFormat.Print();
        
        
        size = sizeof(clientFormat);
        XThrowIfError(ExtAudioFileSetProperty(sourceFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat), "couldn't set source client format");
        
        size = sizeof(clientFormat);
        XThrowIfError(ExtAudioFileSetProperty(destinationFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat), "couldn't set destination client format");
        
        // can the audio converter (which in this case is owned by an ExtAudioFile object) resume conversion after an interruption?
        AudioConverterRef audioConverter;
        
        size = sizeof(audioConverter);
        XThrowIfError(ExtAudioFileGetProperty(destinationFile, kExtAudioFileProperty_AudioConverter, &size, &audioConverter), "Couldn't get Audio Converter!");
        
        // this property may be queried at any time after construction of the audio converter (which in this case is owned by an ExtAudioFile object)
        // after setting the output format -- there's no clear reason to prefer construction time, interruption time, or potential resumption time but we prefer
        // construction time since it means less code to execute during or after interruption time
        UInt32 canResume = 0;
        size = sizeof(canResume);
        error = AudioConverterGetProperty(audioConverter, kAudioConverterPropertyCanResumeFromInterruption, &size, &canResume);
        if (noErr == error) {
            // we recieved a valid return value from the GetProperty call
            // if the property's value is 1, then the codec CAN resume work following an interruption
            // if the property's value is 0, then interruptions destroy the codec's state and we're done
            
            if (0 == canResume) canResumeFromInterruption = false;
            
            CNLog(@"AudioDecode-Debug: Audio Converter %s continue after interruption!\n", (canResumeFromInterruption == 0 ? "CANNOT" : "CAN"));
        } else {
            // if the property is unimplemented (kAudioConverterErr_PropertyNotSupported, or paramErr returned in the case of PCM),
            // then the codec being used is not a hardware codec so we're not concerned about codec state
            // we are always going to be able to resume conversion after an interruption
            
            if (kAudioConverterErr_PropertyNotSupported == error) {
                CNLog(@"AudioDecode-Debug: kAudioConverterPropertyCanResumeFromInterruption property not supported!\n");
            } else {
                CNLog(@"AudioDecode-Debug: AudioConverterGetProperty kAudioConverterPropertyCanResumeFromInterruption result %ld\n", error);
            }
            
            error = noErr;
        }
        
        // set up buffers
        UInt32 bufferByteSize = 32768;
        char srcBuffer[bufferByteSize];
        
        // keep track of the source file offset so we know where to reset the source for
        // reading if interrupted and input was not consumed by the audio converter
        SInt64 sourceFrameOffset = 0;
        
        //***** do the read and write - the conversion is done on and by the write call *****//
        CNLog(@"AudioDecode-Debug: Converting...\n");
        while (1) {
            AudioBufferList fillBufList;
            fillBufList.mNumberBuffers = 1;
            fillBufList.mBuffers[0].mNumberChannels = clientFormat.NumberChannels();
            fillBufList.mBuffers[0].mDataByteSize = bufferByteSize;
            fillBufList.mBuffers[0].mData = srcBuffer;
            
            // client format is always linear PCM - so here we determine how many frames of lpcm
            // we can read/write given our buffer size
            UInt32 numFrames;
            if (clientFormat.mBytesPerFrame > 0) // rids bogus analyzer div by zero warning mBytesPerFrame can't be 0 and is protected by an Assert
                numFrames = clientFormat.BytesToFrames(bufferByteSize); // (bufferByteSize / clientFormat.mBytesPerFrame);
            
            XThrowIfError(ExtAudioFileRead(sourceFile, &numFrames, &fillBufList), "ExtAudioFileRead failed!");
            if (!numFrames) {
                // this is our termination condition 转换完毕
                error = noErr;
                break;
            }
            sourceFrameOffset += numFrames;
            
            error = ExtAudioFileWrite(destinationFile, numFrames, &fillBufList);
            // if interrupted in the process of the write call, we must handle the errors appropriately  //意外中断 例如 来电话
            if (error) {
                isSuccess = NO;
                if (kExtAudioFileError_CodecUnavailableInputConsumed == error) {
                    
                    CNLog(@"AudioDecode-Debug: ExtAudioFileWrite kExtAudioFileError_CodecUnavailableInputConsumed error %ld\n", error);
                    
                    /*
                     Returned when ExtAudioFileWrite was interrupted. You must stop calling
                     ExtAudioFileWrite. If the underlying audio converter can resume after an
                     interruption (see kAudioConverterPropertyCanResumeFromInterruption), you must
                     wait for an EndInterruption notification from AudioSession, then activate the session
                     before resuming. In this situation, the buffer you provided to ExtAudioFileWrite was successfully
                     consumed and you may proceed to the next buffer
                     */
                    
                } else if (kExtAudioFileError_CodecUnavailableInputNotConsumed == error) {
                    
                    CNLog(@"AudioDecode-Debug: ExtAudioFileWrite kExtAudioFileError_CodecUnavailableInputNotConsumed error %ld\n", error);
                    
                    /*
                     Returned when ExtAudioFileWrite was interrupted. You must stop calling
                     ExtAudioFileWrite. If the underlying audio converter can resume after an
                     interruption (see kAudioConverterPropertyCanResumeFromInterruption), you must
                     wait for an EndInterruption notification from AudioSession, then activate the session
                     before resuming. In this situation, the buffer you provided to ExtAudioFileWrite was not
                     successfully consumed and you must try to write it again
                     */
                    
                    // seek back to last offset before last read so we can try again after the interruption
                    sourceFrameOffset -= numFrames;
                    XThrowIfError(ExtAudioFileSeek(sourceFile, sourceFrameOffset), "ExtAudioFileSeek failed!");
                    
                } else {
                    XThrowIfError(error, "ExtAudioFileWrite error!");
                }
            } // if
        } // while
        
    }
    catch (CAXException e) {
        isSuccess = NO;
#ifdef SOUNDTOUCH_DEBUG
        char buf[256];
        fprintf(stderr, "AudioDecode-Debug: Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
        error = e.mError;
#endif
    }
    
    // close
    if (destinationFile) ExtAudioFileDispose(destinationFile);
    if (sourceFile) ExtAudioFileDispose(sourceFile);
    if (!self.isCancelled) {
        //失败回调时 保存路径 设置为空
        [my_target performSelectorOnMainThread:my_action withObject:(isSuccess ? self.outputPath: nil) waitUntilDone:NO];
    }
    
    return error;
    
}

@end
