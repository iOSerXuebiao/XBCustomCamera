//
//  XBViewController.m
//  XBCustomCamera
//
//  Created by iOSerXuebiao on 09/03/2020.
//  Copyright (c) 2020 iOSerXuebiao. All rights reserved.
//

#import "XBViewController.h"
#import "XBCameraViewController.h"

@interface XBViewController ()

@end

@implementation XBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

///固定为竖屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

// 默认进入界面显示方向:默认垂直竖屏
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (IBAction)buttonAction:(id)sender {
    /**
       自定义UI采用该初始化方式即可
       KSCameraViewController *controller = [[KSCameraViewController alloc] initWithCustomView:self.customView];
       self.customView.delegate = controller;
     */
    
    XBCameraViewController *controller = [[XBCameraViewController alloc] init];
    controller.maxCount = 9;
    controller.maxRecordTime = 60;
    controller.maxVideoCount = 7;
    controller.needCompressVideo = YES;
    controller.modalPresentationStyle = UIModalPresentationOverCurrentContext | UIModalPresentationFullScreen;
    
    controller.cancelBlock = ^{
        NSLog(@"取消录制");
    };
    controller.completionBlock = ^(NSArray * _Nonnull dataArray) {
        NSLog(@"录制完成");
    };
    controller.exceedMaxCountBlock = ^{
        ///达到最大拍摄限制
        NSLog(@"达到最大拍摄限制");
    };
    controller.exceedVideoCountBlock = ^{
        ///只能上传一份视频作业哦
        NSLog(@"只能上传一份视频作业哦");
    };
    
    controller.videoCompressStartBlock = ^{
        ///视频压缩中
        NSLog(@"视频压缩中");
    };
    controller.videoCompressResultBlock = ^(BOOL isSuccess) {
        ///压缩成功
        NSLog(@"%@",isSuccess ? @"压缩成功" : @"压缩失败");
    };
    [self presentViewController:controller animated:true completion:NULL];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
