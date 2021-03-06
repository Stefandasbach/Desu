//
//  Modulater.h
//  Desu
//
//  Created by Bram Wasti on 9/13/14.
//  Copyright (c) 2014 bwasti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "Common.h"

@interface Modulater : NSObject

typedef struct {
    AudioStreamBasicDescription format;
    AudioQueueRef queue;
    AudioQueueBufferRef mBuffers[1];
    SInt64 currentPacket;
    long currIndex;
    unsigned long freq; // not to be used always
    long message[MESSAGE_LEN];

} PlayerState;

@property (nonatomic, assign) PlayerState playstate;

- (void)play;
- (void)playBeeps:(unsigned long)freq;
- (void)pause;
- (void)initializeAudio;
@end
