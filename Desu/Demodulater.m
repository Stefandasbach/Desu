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

bool determineSpike(unsigned long freq, long numSamples, float* buffer, long sweep, float cutoff) {
    unsigned long i;
    float *mag = calloc(sweep, sizeof(float));
    for (i = 0; i < sweep; ++i) {
        mag[i] = goertzel_mag(numSamples, freq + i*10 - sweep/2, SR, buffer);
        NSLog(@"[%lu] %f", i, mag[i]);
    }
    
    long maxFreq = 0;
    float maxMag = 0;
    float totalMag = 0.0;
    
    for (i = 0; i < sweep; ++i) {
        totalMag += mag[i];
        if (mag[i] > maxMag) {
            maxFreq = i*10 + freq - sweep/2;
            maxMag = mag[i];
        }
    }
    
    float averageMag = totalMag / sweep;
    
    NSLog(@"max freq is %lu at %f, avg is %f", maxFreq, maxMag, averageMag);
    if ((abs(maxFreq - freq) < 40) && (maxFreq > cutoff * averageMag)) {
        return YES;
    } else {
        return NO;
    }
}

void bufferDecoder(void * inUserData,
                       AudioQueueRef inAQ,
                       AudioQueueBufferRef inBuffer,
                       const AudioTimeStamp * inStartTime,
                       UInt32 inNumPackets,
                       const AudioStreamPacketDescription * inPacketDesc
                       )
{
    NSLog(@"decoding");

    ListenerState *listener = (ListenerState *)inUserData;
    long numSamples = inBuffer->mAudioDataByteSize / listener->format.mBytesPerPacket - 1;
    short *samples = inBuffer->mAudioData;
    for (long i = 0; i < numSamples; i++) {
        listener->fBuffer[i] = samples[i] / (float)SHRT_MAX;
    }
    
    if (determineSpike(HI_FREQ, numSamples, listener->fBuffer, 100, 2.0)) {
        NSLog(@"1");
    } else if (determineSpike(LOW_FREQ, numSamples, listener->fBuffer, 100, 2.0)){
        NSLog(@"0");
    }

    AudioQueueEnqueueBuffer(listener->queue, inBuffer, 0, NULL);

    return;
}

-(void)initializeListener {
    NSLog(@"Initiliazing listener");
    _listener.format.mFormatID = kAudioFormatLinearPCM;
    _listener.format.mSampleRate = 44100.0f;
    _listener.format.mBitsPerChannel = 16;
    _listener.format.mChannelsPerFrame = 1;
    _listener.format.mFramesPerPacket = 1;
    _listener.format.mBytesPerFrame = _listener.format.mBytesPerPacket = _listener.format.mChannelsPerFrame * sizeof(SInt16);
    _listener.format.mReserved = 0;
    _listener.format.mFormatFlags = kLinearPCMFormatFlagIsNonInterleaved | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked ;//|
    _listener.fBuffer = calloc(SR, sizeof(float));
}

-(void)listen {
    NSLog(@"Listening");
    OSStatus status = noErr;
    status = AudioQueueNewInput(&_listener.format,
                                bufferDecoder,
                                &_listener,
                                NULL,
                                NULL,
                                0,
                                &_listener.queue);
    if (status != noErr) {
        NSLog(@"error!!!");
    }
    AudioQueueAllocateBuffer(_listener.queue, BUFFER_SIZE, &_listener.mBuffers[0]);
    AudioQueueEnqueueBuffer(_listener.queue, _listener.mBuffers[0], 0, NULL);
    
    status = AudioQueueStart(_listener.queue, NULL);
    if (status != noErr) {
        NSLog(@"CAN'tLISTNE!!!");
    }
}

@end
