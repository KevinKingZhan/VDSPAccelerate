//
//  ViewController.m
//  VdspAccelerate
//
//  Created by apple on 2017/2/15.
//  Copyright © 2017年 xiaokai.zhan. All rights reserved.
//

#import "ViewController.h"
#import "CommonUtil.h"
#import "AccelerateTester.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)doFFT:(id)sender {
    NSString* pcmFilePath = [CommonUtil bundlePath:@"vocal.pcm"];
    NSString* resultFilePath = [CommonUtil documentsPath:@"vDspResult.txt"];
    AccelerateTester* tester = [[AccelerateTester alloc] init];
    [tester doFFTTestWithPCMFilePath:pcmFilePath resultFilePath:resultFilePath];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
