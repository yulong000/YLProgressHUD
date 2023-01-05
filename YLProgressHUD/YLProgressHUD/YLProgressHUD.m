//
//  YLProgressHUD.m
//  iCopy
//
//  Created by 魏宇龙 on 2022/11/29.
//

#import "YLProgressHUD.h"
#import <QuartzCore/CAMediaTimingFunction.h>
#import <CoreImage/CIFilter.h>

#define kHUDHideDefaultSecond   1.0         // 默认延迟隐藏的秒数
#define kHUDMaxWidth            300         // 最大的宽度，超过宽度换行

// 判断当前app是否是深色模式
#define kAppIsDarkTheme                \
^ BOOL {                                                                                    \
    if (@available(macOS 11.0, *)) {                                                        \
        return [NSAppearance currentDrawingAppearance].name != NSAppearanceNameAqua;        \
    } else {                                                                                \
        return [NSAppearance currentAppearance].name != NSAppearanceNameAqua;               \
    }                                                                                       \
}()                                                                                         \

#pragma mark - 显示进度

@interface YLProgressDisplayView : NSView

@property (nonatomic, assign) YLProgressHUDStyle style;
@property (nonatomic, assign) CGFloat progress;
/// 将progress转换成百分比字符串
@property (nonatomic, copy)   NSString *progressText;

@end

@implementation YLProgressDisplayView

- (void)setProgress:(CGFloat)progress {
    _progress = MIN(1, MAX(0, progress));;
    self.progressText = [NSString stringWithFormat:@"%d%%", (int)(_progress * 100)];
    [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped {
    return YES;
}

- (void)setStyle:(YLProgressHUDStyle)style {
    _style = style;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    CGContextRef ctx = [NSGraphicsContext currentContext].CGContext;
    CGContextSetLineWidth(ctx, 2);
    if(self.style == YLProgressHUDStyleBlack) {
        [[NSColor whiteColor] set];
    } else {
        [[NSColor blackColor] set];
    }
    
    CGFloat centerX = NSMidX(dirtyRect);
    CGFloat centerY = NSMidY(dirtyRect);
    CGFloat radius1 = dirtyRect.size.height / 2 - 2;
    CGFloat radius2 = radius1 - 3;
    
    // 外层的圆
    CGContextAddArc(ctx, centerX, centerY, radius1, 0, M_PI * 2, 0);
    CGContextStrokePath(ctx);
    
    // 内部的进度
    CGFloat end = M_PI * 2 * self.progress - M_PI_2;
    CGContextAddArc(ctx, centerX, centerY, radius2, - M_PI_2, end, 0);
    CGContextAddLineToPoint(ctx, centerX, centerY);
    CGContextAddLineToPoint(ctx, centerX, centerY - radius2);
    CGContextFillPath(ctx);
}

@end

#pragma mark - hud显示区域

@interface YLProgressHUDView : NSView

@property (nonatomic, assign) YLProgressHUDStyle style;

@end

@implementation YLProgressHUDView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if(self = [super initWithFrame:frameRect]) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = 10;
        self.style = YLProgressHUDStyleBlack;
    }
    return self;
}

- (void)resetShadow {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    shadow.shadowBlurRadius = 5;
    if(self.style == YLProgressHUDStyleBlack) {
        self.layer.backgroundColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:0.6].CGColor;
        shadow.shadowColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    } else {
        self.layer.backgroundColor = [NSColor colorWithRed:1 green:1 blue:1 alpha:0.6].CGColor;
        shadow.shadowColor = [NSColor colorWithRed:1 green:1 blue:1 alpha:0.3];
    }
    self.shadow = shadow;
}

- (BOOL)isFlipped {
    return YES;
}

- (void)setStyle:(YLProgressHUDStyle)style {
    _style = style;
    [self resetShadow];
}

@end

#pragma mark - hud窗口

@interface YLProgressHUD ()

@property (nonatomic, strong) YLProgressHUDView *hudView;
@property (nonatomic, strong, nullable) NSView *customView;
@property (nonatomic, strong) NSTextField *textLabel;
/// 隐藏后的回调
@property (nonatomic, copy)   YLProgressHUDCompletionHandler completionHandler;

@property (nonatomic, strong) id monitor;

@end

@implementation YLProgressHUD

- (instancetype)init {
    if (self = [super init]) {
        
        self.backgroundColor = [NSColor colorWithWhite:0 alpha:0.005];
        self.level = NSPopUpMenuWindowLevel;
        self.styleMask = NSWindowStyleMaskBorderless;
        self.releasedWhenClosed = NO;
        self.contentView = [[NSImageView alloc] init];

        self.hudView = [[YLProgressHUDView alloc] init];
        [self.contentView addSubview:self.hudView];
        
        self.textLabel = [NSTextField labelWithString:@""];
        self.textLabel.font = YLProgressHUDConfig.share.textFont ?: [NSFont systemFontOfSize:16];
        self.textLabel.maximumNumberOfLines = 10;
        self.textLabel.preferredMaxLayoutWidth = kHUDMaxWidth - 40;
        self.textLabel.cell.wraps = YES;
        self.textLabel.textColor = [NSColor whiteColor];
        [self.hudView addSubview:self.textLabel];
        
        self.style = [YLProgressHUDConfig share].style;
        
        __weak typeof(self) weakSelf = self;
        self.monitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDragged handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
            if(event.window == weakSelf) {
                // 让窗口响应鼠标的拖动
                NSPoint parentWindowOrigin = weakSelf.parentWindow.frame.origin;
                [weakSelf.parentWindow setFrameOrigin:NSMakePoint(parentWindowOrigin.x + event.deltaX, parentWindowOrigin.y - event.deltaY)];
            }
            return event;
        }];
    }
    return self;
}

- (void)setStyle:(YLProgressHUDStyle)style {
    if(style == YLProgressHUDStyleAuto) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        _style = kAppIsDarkTheme ? YLProgressHUDStyleWhite : YLProgressHUDStyleBlack;
#pragma clang diagnostic pop
    } else {
        _style = style;
    }
    self.hudView.style = _style;
    self.textLabel.textColor = _style == YLProgressHUDStyleBlack ? [NSColor whiteColor] : [NSColor blackColor];
    if(self.customView) {
        if([self.customView isKindOfClass:[NSImageView class]]) {
            [YLProgressHUD setImageView:(NSImageView *)self.customView withStyle:_style];
        } else if([self.customView isKindOfClass:[NSProgressIndicator class]]) {
            [(NSProgressIndicator *)self.customView setContentFilters:@[[YLProgressHUD createColorFilterWithStyle:_style]]];
        } else if([self.customView isKindOfClass:[YLProgressDisplayView class]]) {
            [(YLProgressDisplayView *)self.customView setStyle:_style];
        }
    }
}

- (void)dealloc {
    [NSEvent removeMonitor:self.monitor];
}

- (void)layoutSubviews {
    // 上下左右留白 20， text customView 间距 20
    if(self.textLabel.stringValue.length > 0) {
        [self.textLabel setFrameSize:[self.textLabel sizeThatFits:NSMakeSize(kHUDMaxWidth - 40, MAXFLOAT)]];
    } else {
        [self.textLabel setFrameSize:NSZeroSize];
    }
    CGFloat windowWidth = self.contentView.frame.size.width;
    CGFloat windowHeight = self.contentView.frame.size.height;
    CGFloat textLabelWidth = self.textLabel.frame.size.width;
    CGFloat textLabelHeight = self.textLabel.frame.size.height;
    CGFloat customViewWidth = self.customView.frame.size.width;
    CGFloat customViewHeight = self.customView.frame.size.height;
    CGFloat hudWidth = 0;
    CGFloat hudHeight = 0;
    if(self.customView) {
        hudWidth = MAX(textLabelWidth, customViewWidth) + 40;
        hudHeight = (textLabelHeight > 0 ? (textLabelHeight + 20) : 0) + customViewHeight + 40;
        hudWidth = MAX(hudWidth, hudHeight);
        [self.hudView setFrameSize:NSMakeSize(hudWidth, hudHeight)];
        [self.customView setFrameOrigin:NSMakePoint((hudWidth - customViewWidth) / 2, 20)];
        [self.textLabel setFrameOrigin:NSMakePoint((hudWidth - textLabelWidth) / 2, 20 + customViewHeight + 20)];
    } else {
        hudWidth = textLabelWidth + 40;
        hudHeight = textLabelHeight + 40;
        hudWidth = MAX(hudWidth, hudHeight);
        [self.hudView setFrameSize:NSMakeSize(hudWidth, hudHeight)];
        [self.textLabel setFrameOrigin:NSMakePoint(20, 20)];
    }
    [self.hudView setFrameOrigin:NSMakePoint((windowWidth - hudWidth) / 2, (windowHeight - hudHeight) / 2)];
}

#pragma mark - 显示成功

+ (instancetype)showSuccess:(NSString *)success toWindow:(NSWindow *)window {
    return [YLProgressHUD showSuccess:success toWindow:window completionHandler:nil];
}

+ (instancetype)showSuccess:(NSString *)success toWindow:(NSWindow *)window hideAfterDelay:(CGFloat)second {
    return [YLProgressHUD showSuccess:success toWindow:window hideAfterDelay:second completionHandler:nil];
}

+ (instancetype)showSuccess:(NSString *)success toWindow:(NSWindow *)window completionHandler:(YLProgressHUDCompletionHandler _Nullable)completionHandler {
    return [YLProgressHUD showSuccess:success toWindow:window hideAfterDelay:kHUDHideDefaultSecond completionHandler:completionHandler];
}

+ (instancetype)showSuccess:(NSString *)success toWindow:(NSWindow *)window hideAfterDelay:(CGFloat)second completionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    NSImageView *successView = [YLProgressHUD createSuccessViewWithStyle:YLProgressHUDConfig.share.style];
    return [YLProgressHUD showCustomView:successView text:success toWindow:window hideAfterDelay:second completionHandler:completionHandler];
}

#pragma mark - 显示错误

+ (instancetype)showError:(NSString *)error toWindow:(NSWindow *)window {
    return [YLProgressHUD showError:error toWindow:window completionHandler:nil];
}

+ (instancetype)showError:(NSString *)error toWindow:(NSWindow *)window hideAfterDelay:(CGFloat)second {
    return [YLProgressHUD showError:error toWindow:window hideAfterDelay:second completionHandler:nil];
}

+ (instancetype)showError:(NSString *)error toWindow:(NSWindow *)window completionHandler:(YLProgressHUDCompletionHandler _Nullable)completionHandler {
    return [YLProgressHUD showError:error toWindow:window hideAfterDelay:kHUDHideDefaultSecond completionHandler:completionHandler];
}

+ (instancetype)showError:(NSString *)error toWindow:(NSWindow *)window hideAfterDelay:(CGFloat)second completionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    NSImageView *errorView = [YLProgressHUD createErrorViewWithStyle:YLProgressHUDConfig.share.style];
    return [YLProgressHUD showCustomView:errorView text:error toWindow:window hideAfterDelay:second completionHandler:completionHandler];
}

#pragma mark - 显示文字

+ (instancetype)showText:(NSString *)text toWindow:(NSWindow *)window {
    return [YLProgressHUD showText:text toWindow:window completionHandler:nil];
}

+ (instancetype)showText:(NSString *)text toWindow:(NSWindow *)window hideAfterDelay:(CGFloat)second {
    return [YLProgressHUD showText:text toWindow:window hideAfterDelay:second completionHandler:nil];
}

+ (instancetype)showText:(NSString *)text toWindow:(NSWindow *)window completionHandler:(YLProgressHUDCompletionHandler _Nullable)completionHandler {
    return [YLProgressHUD showText:text toWindow:window hideAfterDelay:kHUDHideDefaultSecond completionHandler:completionHandler];
}

+ (instancetype)showText:(NSString *)text toWindow:(NSWindow *)window hideAfterDelay:(CGFloat)second completionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    return [YLProgressHUD showCustomView:nil text:text toWindow:window hideAfterDelay:second completionHandler:completionHandler];
}

#pragma mark - 显示加载中

+ (instancetype)showLoading:(NSString *)loadingText toWindow:(NSWindow *)window {
    NSProgressIndicator *indicator = [YLProgressHUD createLoadingIndicator];
    return [YLProgressHUD showCustomView:indicator text:loadingText toWindow:window hideAfterDelay:-1 completionHandler:nil];
}

#pragma mark - 显示进度

+ (instancetype)showProgress:(CGFloat)progress toWindow:(NSWindow *)window {
    return [YLProgressHUD showProgress:progress text:nil toWindow:window];
}

+ (instancetype)showProgress:(CGFloat)progress text:(NSString * _Nullable)text toWindow:(nonnull NSWindow *)window {
    YLProgressDisplayView *progressView = [YLProgressHUD createProgressViewWithStyle:YLProgressHUDConfig.share.style];
    progressView.progress = progress;
    return [YLProgressHUD showCustomView:progressView text:text ?: progressView.progressText toWindow:window hideAfterDelay:-1 completionHandler:nil];
}

#pragma mark - 显示自定义view和文字
+ (instancetype)showCustomView:(NSView * _Nullable)customView text:(NSString *)text toWindow:(NSWindow *)window hideAfterDelay:(CGFloat)second completionHandler:(YLProgressHUDCompletionHandler _Nullable)completionHandler {
    YLProgressHUD *hud = [[YLProgressHUD alloc] init];
    hud.textLabel.stringValue = text ?: @"";
    hud.completionHandler = completionHandler;
    if(customView) {
        hud.customView = customView;
        [hud.hudView addSubview:customView];
    }
    [window addChildWindow:hud ordered:NSWindowAbove];
    [hud setFrame:window.frame display:YES];
    [hud layoutSubviews];
    if(second >= 0) {
        // 自动隐藏
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [YLProgressHUD hideHUD:hud];
        });
    }
    return hud;
}

#pragma mark - 隐藏

+ (void)hideHUD:(YLProgressHUD *)hud {
    if(hud.completionHandler) {
        hud.completionHandler();
    }
    [hud.parentWindow removeChildWindow:hud];
    [hud close];
}

+ (void)hideHUDForWindow:(NSWindow *)window {
    for (YLProgressHUD *hud in window.childWindows) {
        if([hud isKindOfClass:[YLProgressHUD class]]) {
            [YLProgressHUD hideHUD:hud];
        }
    }
}

#pragma mark - 切换显示

- (void)hide {
    [self hideWithCompletionHandler:nil];
}

- (void)hideWithCompletionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    [self hideAfterDelay:kHUDHideDefaultSecond completionHandler:completionHandler];
}

- (void)hideAfterDelay:(CGFloat)second completionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    self.completionHandler = completionHandler;
    if(second > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [YLProgressHUD hideHUD:self];
        });
    }
}

- (void)showLoading:(NSString *)loading {
    self.textLabel.stringValue = loading ?: @"";
    [self layoutSubviews];
}

#pragma mark 文字

- (void)showText:(NSString *)text {
    [self showText:text completionHandler:nil];
}

- (void)showText:(NSString *)text hideAfterDelay:(CGFloat)second {
    [self showText:text hideAfterDelay:second completionHandler:nil];
}

- (void)showText:(NSString *)text completionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    [self showText:text hideAfterDelay:kHUDHideDefaultSecond completionHandler:completionHandler];
}

- (void)showText:(NSString *)text hideAfterDelay:(CGFloat)second completionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    [self loadBackgroudImage];
    [self.customView removeFromSuperview];
    self.customView = nil;
    self.textLabel.stringValue = text ?: @"";
    self.completionHandler = completionHandler;
    [self layoutSubviews];
    if(second >= 0) {
        // 自动隐藏
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [YLProgressHUD hideHUD:self];
        });
    }
}

#pragma mark 成功

- (void)showSuccess:(NSString *)success {
    [self showSuccess:success completionHandler:nil];
}

- (void)showSuccess:(NSString *)success hideAfterDelay:(CGFloat)second {
    [self showSuccess:success hideAfterDelay:second completionHandler:nil];
}

- (void)showSuccess:(NSString *)success completionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    [self showSuccess:success hideAfterDelay:kHUDHideDefaultSecond completionHandler:completionHandler];
}

- (void)showSuccess:(NSString *)success hideAfterDelay:(CGFloat)second completionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    [self loadBackgroudImage];
    [self.customView removeFromSuperview];
    self.customView = [YLProgressHUD createSuccessViewWithStyle:self.style];
    [self.hudView addSubview:self.customView];
    self.textLabel.stringValue = success ?: @"";
    self.completionHandler = completionHandler;
    [self layoutSubviews];
    if(second >= 0) {
        // 自动隐藏
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [YLProgressHUD hideHUD:self];
        });
    }
}

#pragma mark 错误

- (void)showError:(NSString *)error {
    [self showError:error completionHandler:nil];
}

- (void)showError:(NSString *)error hideAfterDelay:(CGFloat)second {
    [self showError:error hideAfterDelay:second completionHandler:nil];
}

- (void)showError:(NSString *)error completionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    [self showError:error hideAfterDelay:kHUDHideDefaultSecond completionHandler:completionHandler];
}

- (void)showError:(NSString *)error hideAfterDelay:(CGFloat)second completionHandler:(YLProgressHUDCompletionHandler)completionHandler {
    [self loadBackgroudImage];
    [self.customView removeFromSuperview];
    self.customView = [YLProgressHUD createErrorViewWithStyle:self.style];
    [self.hudView addSubview:self.customView];
    self.textLabel.stringValue = error ?: @"";
    self.completionHandler = completionHandler;
    [self layoutSubviews];
    if(second >= 0) {
        // 自动隐藏
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [YLProgressHUD hideHUD:self];
        });
    }
}

#pragma mark 进度

- (void)showProgress:(CGFloat)progress {
    [self showProgress:progress text:nil];
}

- (void)showProgress:(CGFloat)progress text:(NSString * _Nullable)text {
    [self loadBackgroudImage];
    [self.customView removeFromSuperview];
    YLProgressDisplayView *progressView = [YLProgressHUD createProgressViewWithStyle:self.style];
    progressView.progress = progress;
    self.customView = progressView;
    [self.hudView addSubview:self.customView];
    self.textLabel.stringValue = text ?: progressView.progressText;
    [self layoutSubviews];
}

- (void)loadBackgroudImage {
    // 截取父window的内容作为背景，解决hud尺寸变化时的残影问题
    [(NSImageView *)self.contentView setImage:[self getThumbImageFromView:self.parentWindow.contentView]];
}

#pragma mark 获取view的截图
- (NSImage *)getThumbImageFromView:(NSView *)view {
    NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:rep];
    NSImage *image = [[NSImage alloc] initWithSize:view.bounds.size];
    [image addRepresentation:rep];
    return image;
}

#pragma mark -

#pragma mark 获取成功的view
+ (NSImageView *)createSuccessViewWithStyle:(YLProgressHUDStyle)style {
    NSImageView *successView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 40, 40)];
    successView.tag = 10000;
    [YLProgressHUD setImageView:successView withStyle:style];
    return successView;
}

#pragma mark 获取失败的view
+ (NSImageView *)createErrorViewWithStyle:(YLProgressHUDStyle)style {
    NSImageView *errorView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 40, 40)];
    errorView.tag = 20000;
    [YLProgressHUD setImageView:errorView withStyle:style];
    return errorView;
}

+ (void)setImageView:(NSImageView *)imageView withStyle:(YLProgressHUDStyle)style {
    if(imageView.tag == 10000) {
        // 成功
        if(style == YLProgressHUDStyleBlack) {
            imageView.image = [YLProgressHUD bundleImage:@"success_white@2x.png"];
        } else {
            imageView.image = [YLProgressHUD bundleImage:@"success_black@2x.png"];
        }
    } else if(imageView.tag == 20000) {
        // 失败
        if(style == YLProgressHUDStyleBlack) {
            imageView.image = [YLProgressHUD bundleImage:@"error_white@2x.png"];
        } else {
            imageView.image = [YLProgressHUD bundleImage:@"error_black@2x.png"];
        }
    }
}

#pragma mark 获取加载中的view
+ (NSProgressIndicator *)createLoadingIndicator {
    NSProgressIndicator *indicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 40, 40)];
    indicator.style = NSProgressIndicatorStyleSpinning;
    indicator.contentFilters = @[[YLProgressHUD createColorFilterWithStyle:YLProgressHUDConfig.share.style]];
    [indicator startAnimation:nil];
    return indicator;
}

+ (CIFilter *)createColorFilterWithStyle:(YLProgressHUDStyle)style {
    NSColor *color = [[NSColor whiteColor] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    if(style == YLProgressHUDStyleWhite) {
        color = [[NSColor blackColor] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    }
    CIVector *min = [CIVector vectorWithX:color.redComponent Y:color.greenComponent Z:color.blueComponent W:0];
    CIVector *max = [CIVector vectorWithX:color.redComponent Y:color.greenComponent Z:color.blueComponent W:1.0];
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorClamp"];
    [colorFilter setDefaults];
    [colorFilter setValue:min forKey:@"inputMinComponents"];
    [colorFilter setValue:max forKey:@"inputMaxComponents"];
    return colorFilter;
}

#pragma mark 获取进度的view
+ (YLProgressDisplayView *)createProgressViewWithStyle:(YLProgressHUDStyle)style {
    YLProgressDisplayView *progressView = [[YLProgressDisplayView alloc] initWithFrame:NSMakeRect(0, 0, 40, 40)];
    progressView.style = style;
    return progressView;
}

#pragma mark 获取bundle里的图片
+ (NSImage *)bundleImage:(NSString *)icon {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"YLProgressHUD" withExtension:@"bundle"];
    if(url == nil) {
        url = [[[[NSBundle mainBundle] URLForResource:@"Frameworks" withExtension:nil] URLByAppendingPathComponent:@"YLCategory"] URLByAppendingPathExtension:@"framework"];
        NSBundle *bundle = [NSBundle bundleWithURL:url];
        url = [bundle URLForResource:@"YLProgressHUD" withExtension:@"bundle"];
    }
    NSString *path = [[NSBundle bundleWithURL:url].bundlePath stringByAppendingPathComponent:icon];
    return [[NSImage alloc] initWithContentsOfFile:path];
}

@end

#pragma mark - 配置信息

@implementation YLProgressHUDConfig

+ (instancetype)share {
    static dispatch_once_t onceToken = '\0';
    static YLProgressHUDConfig *config = nil;
    dispatch_once(&onceToken, ^{
        config = [[YLProgressHUDConfig alloc] init];
        config.style = YLProgressHUDStyleAuto;
    });
    return config;
}

@end
