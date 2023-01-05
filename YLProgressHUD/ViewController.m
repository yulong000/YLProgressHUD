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
    
    NSButton *success = [NSButton buttonWithTitle:@"成功" target:self action:@selector(showSuccess)];
    NSButton *error = [NSButton buttonWithTitle:@"失败" target:self action:@selector(showError)];
    NSButton *text = [NSButton buttonWithTitle:@"文字" target:self action:@selector(showText)];
    NSButton *loading = [NSButton buttonWithTitle:@"loading" target:self action:@selector(showLoading)];
    NSButton *progress = [NSButton buttonWithTitle:@"进度" target:self action:@selector(showProgress)];
    
    [self.view addSubview:success];
    [self.view addSubview:error];
    [self.view addSubview:text];
    [self.view addSubview:loading];
    [self.view addSubview:progress];
    
    success.frame = NSMakeRect(50, 150, 100, 22);
    error.frame = NSMakeRect(50, 120, 100, 22);
    text.frame = NSMakeRect(50, 90, 100, 22);
    loading.frame = NSMakeRect(50, 60, 100, 22);
    progress.frame = NSMakeRect(50, 30, 100, 22);
}

- (void)showSuccess {
    [YLProgressHUD showSuccess:@"成功！" toWindow:self.view.window];
}

- (void)showError {
    [YLProgressHUD showError:@"失败！" toWindow:self.view.window];
}

- (void)showText {
    [YLProgressHUD showText:@"开始撸代码～" toWindow:self.view.window];
}

- (void)showLoading {
    YLProgressHUD *hud = [YLProgressHUD showLoading:@"加载中..." toWindow:self.view.window];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [hud hide];
        [self hideLoading];
    });
}

- (void)showProgress {
    YLProgressHUD *hud = [YLProgressHUD showProgress:0.2 toWindow:self.view.window];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud showProgress:0.4];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [hud showProgress:0.6];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [hud showProgress:0.8];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [hud showProgress:1];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [hud hide];
                    });
                });
            });
        });
    });
    
}

- (void)hideLoading {
    [YLProgressHUD hideHUDForWindow:self.view.window];
}

@end
