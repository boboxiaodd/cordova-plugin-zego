#import <Cordova/CDV.h>
#import "CDVZegoLive.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>
#import "ZGCaptureDeviceCamera.h"
#import <libCNamaSDK/FURenderer.h>
#import "FUManager.h"
#import "FUAPIDemoBar.h"
#import <Masonry/Masonry.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "MainViewController.h"
#define BEAUTY_SHAPE_FILE @"NoCloud/beauty_shape.plist"
#define BEAUTY_SKIN_FILE @"NoCloud/beauty_skin.plist"
#define BEAUTY_FILTER_FILE @"NoCloud/beauty_filter.plist"
#define BEAUTY_VIEW_HEIGHT 194


@interface CDVZegoLive () <ZegoEventHandler,FUAPIDemoBarDelegate,ZegoCustomVideoCaptureHandler,ZGCaptureDeviceDataOutputPixelBufferDelegate>
    @property (nonatomic,strong) MainViewController *rootVC;
    @property (nonatomic,strong) ZegoExpressEngine * zego;
    @property (nonatomic,strong) FUAPIDemoBar * demoBar;
    @property (nonatomic,strong) UIView * beautyView;
    @property (nonatomic,strong) UIButton * saveButton;
@end


@implementation CDVZegoLive
- (void)pluginInitialize
{
    NSLog(@"--------------- init CDVZegoLive --------");
    if(_zego) return;
    _rootVC = (MainViewController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    _rootVC.webView.backgroundColor = UIColor.clearColor;
    _rootVC.webView.opaque = false;
    NSString *sign = [self settingForKey:@"zego.sign"];
    ZegoEngineProfile * profile = [ZegoEngineProfile new];
    profile.appID = [[self settingForKey:@"zego.appid"] intValue];
    profile.appSign = sign;
    _zego = [ZegoExpressEngine createEngineWithProfile:profile eventHandler:self];

    [_zego enableHardwareDecoder:YES];
    [_zego enableHardwareEncoder:YES];

    [self load_beauty_skin_from_file];
    [self load_beauty_shape_from_file];
    [self load_beauty_filter_from_file];

    ZegoCustomVideoCaptureConfig *captureConfig = [[ZegoCustomVideoCaptureConfig alloc] init];
    // 选择 CVPixelBuffer 类型视频帧数据
    captureConfig.bufferType = ZegoVideoBufferTypeCVPixelBuffer;

    // Enable custom video capture
    [_zego enableCustomVideoCapture:YES config:captureConfig channel:ZegoPublishChannelMain];

    // 将自身作为自定义视频采集回调对象
    [_zego setCustomVideoCaptureHandler:self];

    // 设置无镜像
    [_zego setVideoMirrorMode:(ZegoVideoMirrorModeNoMirror) channel:ZegoPublishChannelMain];
}


-(void) showBeauty:(CDVInvokedUrlCommand *)command
{
    if(!_beautyView){
        CGFloat safeBottom =  UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
        CGRect rect = UIScreen.mainScreen.bounds;
        _beautyView = [[UIView alloc] initWithFrame:CGRectMake(0, rect.size.height, rect.size.width, BEAUTY_VIEW_HEIGHT + safeBottom)];
        [self.viewController.view addSubview:_beautyView];
        _demoBar = [[FUAPIDemoBar alloc] init];
        _demoBar.mDelegate = self;
        [_beautyView addSubview:_demoBar];

        [_demoBar mas_makeConstraints:^(MASConstraintMaker *make) {
            if (@available(iOS 11.0, *)) {
                make.bottom.equalTo(self.viewController.view.mas_safeAreaLayoutGuideBottom);
            } else {
                make.bottom.equalTo(self.viewController.view.mas_bottom);
            }
            make.left.right.equalTo(self.viewController.view);
            make.height.mas_equalTo(BEAUTY_VIEW_HEIGHT);
        }];


        CGRect mainRect = _beautyView.frame;

        _saveButton = [[UIButton alloc] initWithFrame:CGRectMake(mainRect.size.width - 60 - 8, BEAUTY_VIEW_HEIGHT - 30 - 8, 60, 30)];
        [_saveButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_saveButton setTitleColor:UIColor.yellowColor forState:UIControlStateHighlighted];
        [_saveButton setBackgroundColor:UIColor.redColor];
        [_saveButton addTarget:self action:@selector(save_beauty_to_file:) forControlEvents:UIControlEventTouchUpInside];
        [_saveButton setTitle:@"保存" forState:UIControlStateNormal];
        [_saveButton setHidden: YES];
        _saveButton.clipsToBounds = YES;
        _saveButton.layer.cornerRadius = 5.0;
        [_beautyView addSubview:_saveButton];

        UIView *bottonView = [[UIView alloc] initWithFrame:CGRectMake(0, BEAUTY_VIEW_HEIGHT, rect.size.width, safeBottom)];
        bottonView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        [_beautyView addSubview:bottonView];

        [_demoBar reloadShapView:[FUManager shareManager].shapeParams];
        [_demoBar reloadSkinView:[FUManager shareManager].skinParams];
        [_demoBar reloadFilterView:[FUManager shareManager].filters];
        [_demoBar setDefaultFilter:[FUManager shareManager].seletedFliter];
        [_demoBar.skinBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
        [UIView animateWithDuration: 0.3 animations: ^(void){
            CGRect f = self.beautyView.frame;
            f.origin.y = UIScreen.mainScreen.bounds.size.height - BEAUTY_VIEW_HEIGHT - safeBottom;
            [self.beautyView setFrame: f];
            [self.demoBar setIsTopViewShow:YES];
        }];
    }
}
-(void) hideBeauty:(CDVInvokedUrlCommand *)command
{

    if(!_beautyView) return;
    [UIView animateWithDuration: 0.3 animations: ^(void){
        [self.beautyView setAlpha:0];
    } completion:^(BOOL finlished){
        [self.demoBar removeFromSuperview];
        [self.saveButton removeFromSuperview];
        [self.beautyView removeFromSuperview];
        self.demoBar = nil;
        self.saveButton = nil;
        self.beautyView = nil;
    }];
}





- (void)bottomDidChange:(int)index {

}

- (void)filterValueChange:(FUBeautyParam *)param {

}

- (void)showTopView:(BOOL)shown {

}

- (void)switchRenderState:(BOOL)state {

}

- (void)captureDevice:(id<ZGCaptureDevice>)device didCapturedData:(CMSampleBufferRef)data {

}



-(void)save_beauty_to_file:(UIButton *)sender{
    [sender setHidden:YES];
    [self touchfeedback];
    [self save_beauty_skin_to_file];
    [self save_beauty_shape_to_file];
    [self save_beauty_filter_to_file];
}

- (void)save_beauty_shape_to_file
{
    NSURL *docDir = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *pathUrl = [docDir URLByAppendingPathComponent: BEAUTY_SHAPE_FILE];
    NSError *err;
    NSMutableArray *dat = [FUManager shareManager].shapeParams;
    NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:[dat count]];
    for (FUBeautyParam * item in dat) {
        [message setObject:@(item.mValue) forKey:item.mParam];
    }
    [message writeToURL:pathUrl error:&err];
    if(err.code != 0){
        NSLog(@"[CDVLive]save file fail");
    }else{
        NSLog(@"[CDVLive]save success!!");
    }
}

- (void)save_beauty_skin_to_file
{
    NSURL *docDir = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *pathUrl = [docDir URLByAppendingPathComponent: BEAUTY_SKIN_FILE];
    NSError *err;
    NSMutableArray *dat = [FUManager shareManager].skinParams;
    NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:[dat count]];
    for (FUBeautyParam * item in dat) {
        [message setObject:@(item.mValue) forKey:item.mParam];
    }
    [message writeToURL:pathUrl error:&err];
    if(err.code != 0){
        NSLog(@"[CDVLive]save file fail");
    }else{
        NSLog(@"[CDVLive]save success!!");
    }
}

- (void)save_beauty_filter_to_file
{
    NSURL *docDir = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *pathUrl = [docDir URLByAppendingPathComponent: BEAUTY_FILTER_FILE];
    NSError *err;
    NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:3];
    FUBeautyParam *p = [FUManager shareManager].seletedFliter;
    [message setObject:p.mParam forKey:@"mParam"];
    [message setObject:p.mTitle forKey:@"mTitle"];
    [message setObject:@(p.mValue) forKey:@"mValue"];
    [message writeToURL:pathUrl error:&err];

    if(err.code != 0){
        NSLog(@"[CDVLive]save file fail");
    }else{
        NSLog(@"[CDVLive]save success!!");
    }
}

- (void)load_beauty_shape_from_file{
    NSURL *docDir = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *pathUrl = [docDir URLByAppendingPathComponent: BEAUTY_SHAPE_FILE];
    if ([[NSFileManager defaultManager]fileExistsAtPath: pathUrl.path isDirectory: FALSE]) {
        NSLog(@"[CDVLive]The file found!");
        NSError *err;
        NSMutableDictionary *dictBeauty = [[NSMutableDictionary alloc] initWithContentsOfURL:pathUrl error:&err];
        if(err.code == 0){
            for(int i=0;i<[[FUManager shareManager].shapeParams count];i++){
                [FUManager shareManager].shapeParams[i].mValue = [[dictBeauty valueForKey:[FUManager shareManager].shapeParams[i].mParam] floatValue];
            }
        }else{
            NSLog(@"[CDVLive]Open file fail: %ld",(long)err.code);
        }
    } else {
        NSLog(@"[CDVLive]The file not found");
    }
}
- (void)load_beauty_skin_from_file{
    NSURL *docDir = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *pathUrl = [docDir URLByAppendingPathComponent: BEAUTY_SKIN_FILE];
    if ([[NSFileManager defaultManager]fileExistsAtPath: pathUrl.path isDirectory: FALSE]) {
        NSLog(@"[CDVLive]The file found!");
        NSError *err;
        NSMutableDictionary *dictBeauty = [[NSMutableDictionary alloc] initWithContentsOfURL:pathUrl error:&err];
        if(err.code == 0){
            for(int i=0;i<[[FUManager shareManager].skinParams count];i++){
                [FUManager shareManager].skinParams[i].mValue = [[dictBeauty valueForKey:[FUManager shareManager].skinParams[i].mParam] floatValue];
            }
        }else{
            NSLog(@"[CDVLive]Open file fail: %ld",(long)err.code);
        }
    } else {
        NSLog(@"[CDVLive]The file not found");
    }
}

- (void)load_beauty_filter_from_file{
    NSURL *docDir = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *pathUrl = [docDir URLByAppendingPathComponent: BEAUTY_FILTER_FILE];
    if ([[NSFileManager defaultManager]fileExistsAtPath: pathUrl.path isDirectory: FALSE]) {
        NSLog(@"[CDVLive]The file found!");
        NSError *err;
        NSMutableDictionary *dictBeauty = [[NSMutableDictionary alloc] initWithContentsOfURL:pathUrl error:&err];
        if(err.code == 0){
            FUBeautyParam *modle = [[FUBeautyParam alloc] init];
            modle.mParam = [dictBeauty valueForKey:@"mParam"];
            modle.mTitle = [dictBeauty valueForKey:@"mTitle"];
            modle.mValue = [[[NSString alloc] initWithFormat:@"%1f",[[dictBeauty valueForKey:@"mValue"] floatValue]] floatValue];
            modle.type = FUDataTypeFilter;
            [self setDefaultFilter:modle];
            NSLog(@"load filter from file: %@",modle.mTitle);
        }else{
            NSLog(@"[CDVLive]Open file fail: %ld",(long)err.code);
        }
    } else {
        FUBeautyParam *modle = [[FUBeautyParam alloc] init];
        modle.mParam = @"fennen1";
        modle.mTitle = @"粉嫩1";
        modle.mValue = 0.4;
        modle.type = FUDataTypeFilter;
        [self setDefaultFilter:modle];
        NSLog(@"[CDVLive]The file not found");
    }
}

- (void)setDefaultFilter:(FUBeautyParam *)modle
{
    int handle = [[FUManager shareManager] getHandleAboutType:FUNamaHandleTypeBeauty];
    [FURenderer itemSetParam:handle withName:@"filter_name" value:[modle.mParam lowercaseString]];
    [FURenderer itemSetParam:handle withName:@"filter_level" value:@(modle.mValue)]; //滤镜程度
    [FUManager shareManager].seletedFliter = modle;
}


-(void)touchfeedback
{
    UIImpactFeedbackGenerator *feedBackGenertor = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedBackGenertor impactOccurred];
}

- (id)settingForKey:(NSString*)key
{
    return [self.commandDelegate.settings objectForKey:[key lowercaseString]];
}

@end
