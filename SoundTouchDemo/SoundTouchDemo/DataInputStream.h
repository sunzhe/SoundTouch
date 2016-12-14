//
//  DataInputStream.h
//  SoundTouchDemo
//
//  Created by hejinlai on 13-6-14.
//  Copyright (c) 2013年 yunzhisheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataInputStream : NSObject
{
    NSData *data;
    NSInteger length;
}


//
- (id)initWithData:(NSData *)data;

//
+ (id)dataInputStreamWithData:(NSData *)aData;

// 从输入流读取 char 值。
- (int8_t)readChar;

//从输入流读取 short 值。
- (int16_t)readShort;

//从输入流读取 int 值。
- (int32_t)readInt;

//从输入流读取 long 值。
- (int64_t)readLong;

//从输入流读取 NSString 字符串。
- (NSString *)readUTF;

@end
