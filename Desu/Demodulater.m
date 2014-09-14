//
//  Demodulater.m
//  Desu
//
//  Created by Bram Wasti on 9/13/14.
//  Copyright (c) 2014 bwasti. All rights reserved.
//

#import "Demodulater.h"

@implementation Demodulater
id this;

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

int determineSpike(long numSamples, float* buffer,
                    long sweep, unsigned long high,  unsigned long mid,  unsigned long low,
                    float cutoff) {
    unsigned long i;
    unsigned long spacing = (high - low) / 4;
    unsigned long totalRangeBy10 = spacing * 6 / 10;
    
    float *mag = calloc(totalRangeBy10, sizeof(float));
    for (i = 0; i < totalRangeBy10; ++i) {
        mag[i] = goertzel_mag(numSamples, low - spacing + i * 10, SR, buffer);
        //NSLog(@"[%lu] %f", i, mag[i]);
    }
    
    long maxFreq = 0;
    float maxMag = 0;
    float totalMag = 0.0;
    
    for (i = 0; i < sweep; ++i) {
        totalMag += mag[i];
        if (mag[i] > maxMag) {
            maxFreq = low - spacing + i * 10;
            maxMag = mag[i];
        }
    }
    
    //NSLog(@"total mag: %f", totalMag);
    
    float averageMag = totalMag / totalRangeBy10;
    
    //NSLog(@"max freq is %lu at %f, avg is %f", maxFreq, maxMag, averageMag);
    if (maxMag > cutoff * averageMag) {
        if (abs(maxFreq-low) < 40) return 0;
        if (abs(maxFreq-mid) < 40) return 1;
        if (abs(maxFreq-high) < 40) return 2;
    }
    return -1;
}

#define CLEAN 5
static int last[CLEAN] = {-1, -1, -1};

-(void) labelUpdater{
    float hi_mag = goertzel_mag(SAMPLES_PER_READ, HI_FREQ, SR, _listener.fBuffer);
    float low_mag = goertzel_mag(SAMPLES_PER_READ, LOW_FREQ, SR, _listener.fBuffer);
    [_highLabel setText:[NSString stringWithFormat:@"%f",hi_mag]];
    [_lowLabel setText:[NSString stringWithFormat:@"%f",low_mag]];
    NSLog(@"\nHI:%f\nLOW:%f",hi_mag, low_mag);
    //
}

-(void)setLabelHigh:(UILabel *)highLabel AndLow:(UILabel *)lowLabel {
    _lowLabel = lowLabel;
    _highLabel = highLabel;
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
    
    int sample_base = 0;
    short *samples = inBuffer->mAudioData;
    
    int vals[numSamples/SAMPLES_PER_READ];
    
    int clean = 0;
    
    while (sample_base + SAMPLES_PER_READ < numSamples) {
        for (long i = 0; i < SAMPLES_PER_READ; i++) {
            listener->fBuffer[i] = samples[i + sample_base] / (float)SHRT_MAX;
        }
        
        [this labelUpdater];
        
        /*
        int res = determineSpike(SAMPLES_PER_READ, listener->fBuffer, 50, HI_FREQ, MED_FREQ, LOW_FREQ, 2.0);
        //NSLog(@"%d", res);
        vals[sample_base / SAMPLES_PER_READ] = res;
        
        for (int i = 0; i < CLEAN - 1; i ++) {
            last[i] = last[i+1];
        }
        last[CLEAN - 1] = res;
        
        int nums[3] = {0, 0, 0};
        
        for (int i = 0; i < CLEAN; i ++) {
            if (last[i] != -1) {
                nums[last[i]] ++;
            }
        }
        for (int i = 0; i < 3; i++) {
            if (nums[i] > CLEAN / 2 + 1) {
                switch(i) {
                    case 0:
                    case 1:
                        if (clean) {
                            NSLog(@"%d", i);
                            clean = 0;
                        }
                        break;
                    case 2:
                        clean = 1;
                        break;
                    default:
                        NSLog(@"Whatasldkfjklsdjf");
                }
            }
        }

        */
        sample_base += SAMPLES_PER_READ;
    }
   
    
    


    AudioQueueEnqueueBuffer(listener->queue, inBuffer, 0, NULL);

    return;
}

-(void)initializeListener {
    this = self;
    NSLog(@"Initiliazing listener");
    _listener.format.mFormatID = kAudioFormatLinearPCM;
    _listener.format.mSampleRate = 44100.0f;
    _listener.format.mBitsPerChannel = 16;
    _listener.format.mChannelsPerFrame = 1;
    _listener.format.mFramesPerPacket = 1;
    _listener.format.mBytesPerFrame = _listener.format.mBytesPerPacket = _listener.format.mChannelsPerFrame * sizeof(SInt16);
    _listener.format.mReserved = 0;
    _listener.format.mFormatFlags = kLinearPCMFormatFlagIsNonInterleaved | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked ;//|
    _listener.fBuffer = calloc(SAMPLES_PER_READ, sizeof(float));
        [_highLabel setText:[NSString stringWithFormat:@"%f",0.2]];
    [_lowLabel setText:[NSString stringWithFormat:@"%f",0.123]];
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

-(void)pause {
    AudioQueueReset(_listener.queue);
    AudioQueueStop(_listener.queue, YES);
    AudioQueueDispose (_listener.queue, YES);
}

@end
