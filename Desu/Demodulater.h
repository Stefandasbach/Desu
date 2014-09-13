//
//  Demodulater.h
//  Desu
//
//  Created by Bram Wasti on 9/13/14.
//  Copyright (c) 2014 bwasti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "Common.h"

@interface Demodulater : NSObject

typedef struct {
    AudioStreamBasicDescription format;
    AudioQueueRef queue;
    AudioQueueBufferRef mBuffers[3];
    SInt64 currentPacket;
    float *fBuffer;
} ListenerState;

@property (nonatomic, assign) ListenerState listener;

-(void)initializeListener;
-(void)listen;
-(void)pause;

@end
