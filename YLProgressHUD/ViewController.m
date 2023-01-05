//
//  ViewController.m
//  YLProgressHUD
//
//  Created by 魏宇龙 on 2023/1/4.
//

#import "ViewController.h"
#import "YLProgressHUD.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [YLProgressHUD showLoading:@"成功" toWindow:self.view.window];
    });
}


@end
