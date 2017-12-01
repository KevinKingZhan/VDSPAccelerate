//
//  AccelerateTester.m
//  VdspAccelerate
//
//  Created by apple on 2017/2/15.
//  Copyright © 2017年 xiaokai.zhan. All rights reserved.
//

#import "AccelerateTester.h"
#import <Accelerate/Accelerate.h>
#import <QuartzCore/CABase.h>
#import <stdio.h>
#import "CommonUtil.h"
#include "fft_routine.h"

#define NFFT        2048

@implementation AccelerateTester
{
    
    DSPSplitComplex                         tempSplitComplex;
    struct OpaqueFFTSetup*                  fftsetup;
    int                                     m_LOG_N;
    size_t                                  m_halfSize;
    
    FftRoutine* fftRoutine;
}
- (void) doFFTTestWithPCMFilePath:(NSString*) pcmFilePath resultFilePath: (NSString*) resultFilePath;
{
    
    FILE* pcmFile = fopen([pcmFilePath cStringUsingEncoding:NSUTF8StringEncoding], "rb");
    FILE* resultFile = fopen([resultFilePath cStringUsingEncoding:NSUTF8StringEncoding], "wb");
    short* buffer = new short[NFFT];
    float* fftBuffer = new float[NFFT];
    size_t correcSize = NFFT / 2 +1;
    float* fftfreqRe = new float[correcSize];
    float* fftfreqIm = new float[correcSize];
    float* m_hannwindow = new float[NFFT];
    memset(m_hannwindow, 0, sizeof(float) * NFFT);
    for (int ti = 0; ti < NFFT; ti++) {
        m_hannwindow[ti] = -0.5 * cos(2 * PI * ti / NFFT) + 0.5;
    }
    [self setupMayerFFT];
    [self setupDSPFFT];
    size_t actualReadSize = -1;
    float totalDSPTime = 0;
    float totalMayerTime = 0;
    while((actualReadSize = fread(buffer, sizeof(short), NFFT, pcmFile)) > 0) {
        for(int i = 0; i < actualReadSize; i++) {
            fftBuffer[i] = buffer[i] / 32768.0f * m_hannwindow[i];
        }
        double startTime = CACurrentMediaTime();
        [self mayerFFTForward:fftBuffer rePart:fftfreqRe imPart:fftfreqIm];
        totalMayerTime+=(CACurrentMediaTime() - startTime);
        startTime = CACurrentMediaTime();
        [self dspFFTForward:fftBuffer rePart:fftfreqRe imPart:fftfreqIm];
        totalDSPTime+=(CACurrentMediaTime() - startTime);
        for(int i = 0; i < correcSize - 1; i++){
            float result = fftfreqRe[i] * fftfreqRe[i] + fftfreqIm[i] * fftfreqIm[i];
            fwrite(&result, sizeof(float), 1, resultFile);
        }
    }
    NSLog(@"totalDSPTime is %f ms totalMayerTime is %f ms", totalDSPTime * 1000, totalMayerTime * 1000);
    [self releaseDSPFFT];
    fclose(pcmFile);
    fclose(resultFile);
    delete[] buffer;
    delete[] fftBuffer;
    delete[] fftfreqRe;
    delete[] fftfreqIm;
    delete[] m_hannwindow;
}

- (void) setupMayerFFT
{
    fftRoutine = new FftRoutine(NFFT);
}
- (void) setupDSPFFT
{
    m_halfSize = NFFT/2;
    m_LOG_N = round(phuket_log2(NFFT));
    fftsetup = vDSP_create_fftsetup(m_LOG_N, kFFTRadix2);
    tempSplitComplex.realp = new float[m_halfSize+1];
    memset(tempSplitComplex.realp,0,sizeof(float)*(m_halfSize+1));
    tempSplitComplex.imagp = new float[m_halfSize+1];
    memset(tempSplitComplex.imagp,0,sizeof(float)*(m_halfSize+1));
}

- (void) mayerFFTForward:(float*) inputData rePart:(float*) outputRe imPart:(float*) outputIm;
{
    fftRoutine->fft_forward(inputData, outputRe, outputIm);
}

- (void) dspFFTForward:(float*) inputData rePart:(float*) outputRe imPart:(float*) outputIm;
{
    vDSP_ctoz((DSPComplex*)inputData, 2, &tempSplitComplex, 1, NFFT / 2);
    vDSP_fft_zrip(fftsetup, &tempSplitComplex, 1, m_LOG_N, kFFTDirection_Forward);
    for (int i = 0; i < NFFT / 2; i++) {
        outputRe[i] = tempSplitComplex.realp[i];
        outputIm[i] = tempSplitComplex.imagp[i];
    }
    float scale = 0.5;
    vDSP_vsmul(outputRe, 1, &scale, outputRe, 1, NFFT/2);//vdsp的结果比mayerfft结果大两倍，scale后保证二者的输出结果一致
    vDSP_vsmul(outputIm, 1, &scale, outputIm, 1, NFFT/2);
}

- (void) releaseMayerFFT
{
    if (fftRoutine) {
        delete fftRoutine;
        fftRoutine = NULL;
    }
}

- (void) releaseDSPFFT
{
    if (fftsetup) {
        vDSP_destroy_fftsetup(fftsetup);
        fftsetup = NULL;
    }
    if (tempSplitComplex.realp) {
        delete[] tempSplitComplex.realp;
        tempSplitComplex.realp = NULL;
    }
    if (tempSplitComplex.imagp) {
        delete[] tempSplitComplex.imagp;
        tempSplitComplex.imagp = NULL;
    }
}
@end
