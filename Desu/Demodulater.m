//
//  Demodulater.m
//  Desu
//
//  Created by Bram Wasti on 9/13/14.
//  Copyright (c) 2014 bwasti. All rights reserved.
//

#import "Demodulater.h"
#define THRESH  0.001

@implementation Demodulater
id this;

UILabel *this_highLabel;
UILabel *this_lowLabel;
UILabel *this_remoteLabel;
float goertzel_mag(int numSamples,int TARGET_FREQUENCY,int SAMPLING_RATE, short* data)
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
        q0 = coeff * q1 - q2 + (float)data[i];
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

#define RESETSAMPLES 500
typedef struct {
    double s_prev[2];
    double s_prev2[2];
    double totalpower[2];
    int N;
    int n[2];
} goertzel_context_t;

goertzel_context_t *new_goertzel_context() {
    goertzel_context_t *n = malloc(sizeof(goertzel_context_t));
    
    n->s_prev[0] = 0.0;
    n->s_prev[1] = 0.0;
    n->s_prev2[0] = 0.0;
    n->s_prev2[1] = 0.0;
    
    n->totalpower[0] = 0.0;
    n->totalpower[1] = 0.0;
    n->N = 0;
    n->n[0] = 0;
    n->n[1] = 0;
    
    return n;
}

double tandemRTgoertzelFilter(int sample, double freq, goertzel_context_t *c) {
    double coeff,normalizedfreq,power,s;
    int active;
    normalizedfreq = freq / SR;
    coeff = 2*cos(2*M_PI*normalizedfreq);
    s = sample + coeff * c->s_prev[0] - c->s_prev2[0];
    c->s_prev2[0] = c->s_prev[0];
    c->s_prev[0] = s;
    c->n[0]++;
    s = sample + coeff * c->s_prev[1] - c->s_prev2[1];
    c->s_prev2[1] = c->s_prev[1];
    c->s_prev[1] = s;
    c->n[1]++;
    c->N++;
    active = (c->N / RESETSAMPLES) & 0x01;
    if  (c->n[1-active] >= RESETSAMPLES) { // reset inactive
        c->s_prev[1-active] = 0.0;
        c->s_prev2[1-active] = 0.0;
        c->totalpower[1-active] = 0.0;
        c->n[1-active]=0;
    }
    c->totalpower[0] += sample*sample;
    c->totalpower[1] += sample*sample;
    power = c->s_prev2[active]*c->s_prev2[active]+c->s_prev[active]
       * c->s_prev[active]-coeff*c->s_prev[active]*c->s_prev2[active];
    return power / (c->totalpower[active]+1e-7) / c->n[active];
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
    
    for (i = 0; i < totalRangeBy10; ++i) {
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

#define CLEAN 15


#define SPEAKERS 2
static int values[CLEAN] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
static int start[SPEAKERS] = {-1, -1};
static float last[SPEAKERS] = {-1.0, -1.0, -1.0};
static goertzel_context_t *contexts[2];

#define MEM_LEN 300
#define MEM_NUM_SAMPLES_PER_SAMPLE 100
#define SIGNAL_LEN 30
static double memory[SPEAKERS][MEM_LEN];

float runningAvg[100];

-(void) labelUpdater{
//    float hi_mag = goertzel_mag(SAMPLES_PER_READ, HI_FREQ, SR, _listener.fBuffer);
//    float low_mag = goertzel_mag(SAMPLES_PER_READ, LOW_FREQ, SR, _listener.fBuffer);
//    float ratio = (hi_mag/low_mag);
//    [_highLabel setText:[NSString stringWithFormat:@"%f",hi_mag]];
//    [_lowLabel setText:[NSString stringWithFormat:@"%f",low_mag]];
//    [_ratioLabel setText: [NSString stringWithFormat:@"%f",ratio]];
    //NSLog(@"\nHI:%f\nLOW:%f",hi_mag, low_mag);
    //
}

-(void)setLabelHigh:(UILabel *)highLabel AndLow:(UILabel *)lowLabel AndRatio:(UILabel *)ratioLabel{
    this_lowLabel = lowLabel;
    this_highLabel = highLabel;
    this_remoteLabel = ratioLabel;
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
    
    int sample_base = 0;
    short *samples = inBuffer->mAudioData;
    
    int vals[numSamples/SAMPLES_PER_READ];
    
    int signal[2] = {0, 0};
#define DETECTION_LEN   10
#define AMPLIFICATION 10000
#define AMP_THRESH 1000

    double s1_detect[DETECTION_LEN + 1];
    double s2_detect[DETECTION_LEN + 1];
    double ampCheck[4] = {INFINITY, INFINITY, INFINITY, INFINITY};
    for (long i = 0; i < numSamples; i ++) {
        double s1 = tandemRTgoertzelFilter(samples[i], LOW_FREQ, contexts[0]);
        double s2 = tandemRTgoertzelFilter(samples[i], MED_FREQ, contexts[1]);
        double avg = (s1 + s2) / 2;
        memory[0][i % MEM_LEN] = s1;
        memory[1][i % MEM_LEN] = s2;
        s1 *= AMPLIFICATION;
        s2 *= AMPLIFICATION;
        double totalAvg = 0;
        ampCheck[3] = ampCheck[2];
        ampCheck[2] = ampCheck[1];
        ampCheck[1] = ampCheck[0];
        ampCheck[0] = s1;
        totalAvg = ampCheck[1] + ampCheck[2] + ampCheck[3];
//        if ( ((ampCheck[0] - ampCheck[2]) > (AMP_THRESH)) &&
//             ((ampCheck[1] - ampCheck[2] > (AMP_THRESH))) &&
//             ((ampCheck[2] - ampCheck[3] <= (AMP_THRESH)))) {
        if (s1 > 10 * totalAvg / 3){
            NSLog(@"( %f, %f )", s1, s2);
        }
//        }
//        if ( ((ampCheck[0] - ampCheck[1]) > (1500))) {
//            NSLog(@"( %f, %f )", s1, s2);
//        }

        double max[2] = {0.0, 0.0};
        double min[2] = {INFINITY, INFINITY};
        double sum[2] = {0.0, 0.0};
        
        for (int j = 0; j < MEM_LEN; j ++) {
            sum[0] += memory[0][j];
            sum[1] += memory[1][j];
            
            if (memory[0][j] < min[0]) {
                min[0] = memory[0][j];
            }
            if (memory[1][j] < min[1]) {
                min[1] = memory[1][j];
            }
            if (memory[0][j] > max[0]) {
                max[0] = memory[0][j];
            }
            if (memory[1][j] > max[1]) {
                max[1] = memory[1][j];
            }
        }
        
        if (s1 > 10.0 * sum[0] / MEM_LEN) {
            signal[0]++;
        } else {
            signal[0] = 0;
        }
        
        if (s2 > 10.0 * sum[1] / MEM_LEN) {
            signal[1]++;
        } else {
            signal[1] = 0;
        }
        
        
//        if (i % 10000 == 0) {
//            NSLog(@"s1 = %f", s1);
//        }
//        if (i % 10000 == 0) {
//            NSLog(@"s2 = %f", s2);
//        }
        
        if (signal[0] > SIGNAL_LEN) {
//            NSLog(@"0");
        }
        if (signal[1] > SIGNAL_LEN) {
//            NSLog(@"1");
        }
        
    }
    //NSLog(@"maxamp: %f, frame %ld",maxAmp, maxAmpFrame);
    //NSLog(@"maxam2: %f, frame %ld",maxAmp2, maxAmpFrame2);
    
//    
//    while (sample_base + SAMPLES_PER_READ < numSamples) {
//        for (long i = 0; i < SAMPLES_PER_READ; i++) {
//            listener->fBuffer[i] = samples[i + sample_base] / (float)SHRT_MAX;
//        }
//        
//        //[this labelUpdater];
//        
//        //int res = determineSpike(SAMPLES_PER_READ, listener->fBuffer, 50, HI_FREQ, MED_FREQ, LOW_FREQ, 2.0);
//        
//        //NSLog(@"%d", res);
//        float s1 = goertzel_mag(SAMPLES_PER_READ, LOW_FREQ, SR, listener->fBuffer);
//        float s2 = goertzel_mag(SAMPLES_PER_READ, MED_FREQ, SR, listener->fBuffer);
//        
//        if (s1 > 8 * last[0]) {
//            start[0] = sample_base;
//        }
//        if (s2 > 8 * last[1]) {
//            start[1] = sample_base;
//        }
//        
//        last[0] = s1;
//        last[1] = s2;
//        
//        int res = 0;
//        vals[sample_base / SAMPLES_PER_READ] = res;
//        
//        for (int i = 0; i < CLEAN - 1; i ++) {
//            values[i] = values[i+1];
//        }
//        values[CLEAN - 1] = res;
//    
//        int nums[SPEAKERS] = {0, 0};
//        for (int i = 0; i < CLEAN; i ++) {
//            if (values[i] != -1 && values[i] != 2) {
//                nums[values[i]] ++;
//            }
//        }
//    
//        if (nums[0] > CLEAN / 2 + 1) {
//        } else if (nums[1] > CLEAN / 2 + 1) {
//            
//        }
//        
//        
//        if (start[0] != -1 && start[1] != -1) {
//            NSLog(@"Diff:  %d", abs(start[0] - start[1]));
//            [this_remoteLabel setText: [NSString stringWithFormat:@"%d",abs(start[0] - start[1])]];
//            start[0] = -1;
//            start[1] = -1;
//        }
//        
////
////
////        
//
////        for (int i = 0; i < 3; i++) {
////            if (nums[i] > CLEAN / 2 + 1) {
////                switch(i) {
////                    case 0:
////                    case 1:
////                        if (clean) {
////                            NSLog(@"%d", i);
////                            clean = 0;
////                        }
////                        break;
////                    case 2:
////                        clean = 1;
////                        break;
////                    default:
////                        NSLog(@"Whatasldkfjklsdjf");
////                }
////            }
////        }
//
//        
//        sample_base += 1000;
//    }
   
    
    
    
    start[0] = -1;
    start[1] = -1;

    AudioQueueEnqueueBuffer(listener->queue, inBuffer, 0, NULL);

    return;
}

-(void)initializeListener {
    this = self;
    NSLog(@"Initiliazing listener");
    
    
    contexts[0] = new_goertzel_context();
    contexts[1] = new_goertzel_context();
    
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
    AudioQueueAllocateBuffer(_listener.queue, BUFFER_SIZE, &_listener.mBuffers[1]);
    AudioQueueAllocateBuffer(_listener.queue, BUFFER_SIZE, &_listener.mBuffers[2]);
    AudioQueueEnqueueBuffer(_listener.queue, _listener.mBuffers[0], 0, NULL);
    AudioQueueEnqueueBuffer(_listener.queue, _listener.mBuffers[1], 0, NULL);
    AudioQueueEnqueueBuffer(_listener.queue, _listener.mBuffers[2], 0, NULL);
    
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
