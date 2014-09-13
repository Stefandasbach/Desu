//
//  Modulater.m
//  Desu
//
//  Created by Bram Wasti on 9/13/14.
//  Copyright (c) 2014 bwasti. All rights reserved.
//
#import "Modulater.h"

static unsigned char barkerbin[BARKER_LEN] = {
    0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0
};
static const unsigned char ParityTable256[256] =
{
#   define P2(n) n, n^1, n^1, n
#   define P4(n) P2(n), P2(n^1), P2(n^1), P2(n)
#   define P6(n) P4(n), P4(n^1), P4(n^1), P4(n)
    P6(0), P6(1), P6(1), P6(0)
};

@implementation Modulater

- (void)_encodeMessage:(NSString *)message {
    const char * str = [message cStringUsingEncoding:NSASCIIStringEncoding];
    UInt32 length = message.length;
    UInt32 encodedLength = length * 12 + BARKER_LEN + 1;
    unsigned char * encodedMessage = (unsigned char *)calloc(encodedLength, sizeof(unsigned char));
    char * bpsk = (char *)calloc(encodedLength * BIT_RATE, sizeof(char));

    encodedMessage[0] = 1;
    for (int i = 1; i < BARKER_LEN+1; i++) {
        encodedMessage[i] = 1& ~(barkerbin[i-1] ^ encodedMessage[i-1]);
    }
    for (int i = BARKER_LEN+1; i < encodedLength; i++) {
        switch ((i-BARKER_LEN-1)%12) {
            case 0:
            case 10:
            case 11:
                encodedMessage[i] = 1& ~(0 ^ encodedMessage[i-1]);
                break;
            case 9:
                encodedMessage[i] = 1& ~(ParityTable256[str[(i-BARKER_LEN-1)/12]] ^ encodedMessage[i-1]);
                break;
            default:
                encodedMessage[i] = 1& ~((((unsigned char)str[(i-BARKER_LEN-1)/12] >> (8-((i-BARKER_LEN-1)%12)) & 0x01)) ^ encodedMessage[i-1]);
                break;
        }
    }
#ifdef SHOW_ENCODED
    for (int i = 0; i < encodedLength; i++) {
        printf("%d", encodedMessage[i]);
    }
    printf("\n");
#endif

    for (int i = 0; i < encodedLength; i++) {
        for (int j = 0; j < SAMPLE_PER_BIT; j++) {
            bpsk[i*SAMPLE_PER_BIT+j] = 2* encodedMessage[i] - 1;
        }
    }

#ifdef SHOW_BASEBAND
    for (int i = 0; i < SAMPLE_PER_BIT * encodedLength; i++) {
        printf("%+d\n", bpsk[i]);
    }
#endif


}

void bufferPopulater(void * inUserData,
                       AudioQueueRef inAQ,
                       AudioQueueBufferRef inBuffer) {

    NSLog(@"playing");
    PlayerState * pPlayState = (PlayerState *)inUserData;

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    UInt32 numBytesToPlay = inBuffer->mAudioDataBytesCapacity;
    UInt32 numPackets = numBytesToPlay/pPlayState->format.mBytesPerPacket;

	SInt16 * buffer = (SInt16 *)inBuffer->mAudioData;

	for(long i = 0; i < numPackets; i++) {
        long long idx = pPlayState->currentPacket++;
        //short encoding =  pPlayState->message[idx%MESSAGE_LEN];
		buffer[i] = (SInt16) (sin(2 * M_PI * FREQ * idx / SR) * SHRT_MAX);
	}

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    inBuffer->mAudioDataByteSize = numPackets * 2;
    AudioQueueEnqueueBuffer(pPlayState->queue, inBuffer, 0, NULL);
    return;
}

-(void)initializeAudio {
    NSLog(@"Initializing audio");
    _playstate.format.mFormatID = kAudioFormatLinearPCM;
    _playstate.format.mSampleRate = 44100.0f;
    _playstate.format.mBitsPerChannel = 16;
    _playstate.format.mChannelsPerFrame = 1;
    _playstate.format.mFramesPerPacket = 1;
    _playstate.format.mBytesPerFrame = _playstate.format.mBytesPerPacket = _playstate.format.mChannelsPerFrame * sizeof(SInt16);
    _playstate.format.mReserved = 0;
    _playstate.format.mFormatFlags = kLinearPCMFormatFlagIsNonInterleaved | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked ;//| kLinearPCMFormatFlagIsBigEndian;
    _playstate.message[0] = '1';
    _playstate.message[0] = '2';
    return;
}

-(void)play {
    NSLog(@"Playing audio");

    OSStatus status = noErr;
    status = AudioQueueNewOutput(&_playstate.format,
                                bufferPopulater,
                                &_playstate,
                                NULL,
                                NULL,
                                0,
                                &_playstate.queue);
    
    if (status != noErr) {
        NSLog(@"FUCCCGGGKKKKSDF");
    }
    
    AudioQueueAllocateBuffer(_playstate.queue, BUFFER_SIZE, &_playstate.mBuffers[0]);
    bufferPopulater(&_playstate, _playstate.queue, _playstate.mBuffers[0]);
    
    status = AudioQueueStart(_playstate.queue, NULL);
    
    if (status != noErr) {
        NSLog(@"FUCCCGGGKKKKSDF");
    }
    
    return;
}


@end
