//
//  Demodulater.m
//  Desu
//
//  Created by Bram Wasti on 9/13/14.
//  Copyright (c) 2014 bwasti. All rights reserved.
//

#import "Demodulater.h"

@implementation Demodulater


float goertzel_mag(int numSamples,int TARGET_FREQUENCY,int SAMPLING_RATE, float* data)
{
    int     k,i;
    float   floatnumSamples;
    float   omega,sine,cosine,coeff,q0,q1,q2,magnitude,real,imag;

    float   scalingFactor = numSamples / 2.0;

    floatnumSamples = (float) numSamples;
    k = (int) (0.5 + ((floatnumSamples * TARGET_FREQUENCY) / SAMPLING_RATE));
    omega = (2.0 * M_PI * k) / floatnumSamples;
    sine = sin(omega);
    cosine = cos(omega);
    coeff = 2.0 * cosine;
    q0=0;
    q1=0;
    q2=0;

    for(i=0; i<numSamples; i++)
    {
        q0 = coeff * q1 - q2 + data[i];
        q2 = q1;
        q1 = q0;
    }

    // calculate the real and imaginary results
    // scaling appropriately
    real = (q1 - q2 * cosine) / scalingFactor;
    imag = (q2 * sine) / scalingFactor;

    magnitude = sqrtf(real*real + imag*imag);
    return magnitude;
}

void bufferDecoder(void * inUserData,
                       AudioQueueRef inAQ,
                       AudioQueueBufferRef inBuffer,
                       const AudioTimeStamp * inStartTime,
                       UInt32 inNumPackets,
                       const AudioStreamPacketDescription * inPacketDesc
                       )
{
    ListenerState *listener = (ListenerState *)inUserData;
    long numSamples = inBuffer->mAudioDataByteSize / listener->format.mBytesPerPacket - 1;
    short *samples = inBuffer->mAudioData;
    for (long i = 0; i < numSamples; i++) {
        listener->fBuffer[i] = samples[i] / (float)SHRT_MAX;
    }
    goertzel_mag(numSamples, 19000, SR, listener->fBuffer);
    return;
}

-(void)initializeListener {
    _listener.fBuffer = calloc(SR, sizeof(float));
}

-(void)listen {
    OSStatus status = noErr;
    status = AudioQueueNewInput(&_listener.format,
                                bufferDecoder,
                                &_listener,
                                NULL,
                                NULL,
                                0,
                                &_listener.queue);
}

@end
