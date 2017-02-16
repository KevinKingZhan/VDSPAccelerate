//
//  AccelerateTester.h
//  VdspAccelerate
//
//  Created by apple on 2017/2/15.
//  Copyright © 2017年 xiaokai.zhan. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifndef PI
#define PI (float)3.14159265358979323846
#endif

#define phuket_log2(x) (log(x) * 1.44269504088896340736)

@interface AccelerateTester : NSObject

- (void) doFFTTestWithPCMFilePath:(NSString*) pcmFilePath resultFilePath: (NSString*) resultFilePath;

@end
