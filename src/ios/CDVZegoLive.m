#import <Cordova/CDV.h>
#import "CDVZegoLive.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>
#import "ZGCaptureDeviceCamera.h"
#import <libCNamaSDK/FURenderer.h>
#import "FUManager.h"
#import "FUAPIDemoBar.h"
#import <Masonry/Masonry.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
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
@property (nonatomic,strong) id<ZGCaptureDevice> captureDevice;
@property (nonatomic,strong) CDVInvokedUrlCommand * live_command;
@property (nonatomic,readwrite) NSString * current_room_id;
@property (nonatomic,readwrite) NSString * play_stream_id;
@property (nonatomic,strong) UIView * mineView;
@property (nonatomic,strong) UIView * playView;
@property (nonatomic,readwrite) CGFloat minWindowHeight;
@property (nonatomic,readwrite) CGFloat minWindowWidth;
@property (nonatomic,strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic,strong) UITapGestureRecognizer *switchGesture;
@property (nonatomic,readwrite) BOOL hasSwitchView;
@property (nonatomic,readwrite) BOOL is_video_call;
@property (nonatomic,strong) AVAudioPlayer* audioPlayer;

@end


@implementation CDVZegoLive

- (id<ZGCaptureDevice>)captureDevice {
    if (!_captureDevice) {
        _captureDevice = [[ZGCaptureDeviceCamera alloc] initWithPixelFormatType:kCVPixelFormatType_32BGRA];
        _captureDevice.delegate = self;
    }
    return _captureDevice;
}

#pragma mark Cordova接口
- (void)pluginInitialize
{
    NSLog(@"--------------- init CDVZegoLive --------");
    if(_zego) return;

    _rootVC = (MainViewController *)[UIApplication sharedApplication].keyWindow.rootViewController;

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

    _minWindowHeight = [UIScreen mainScreen].bounds.size.height * 0.2;
    _minWindowWidth = [UIScreen mainScreen].bounds.size.width * 0.2;

    ZegoCustomVideoCaptureConfig *captureConfig = [[ZegoCustomVideoCaptureConfig alloc] init];
    captureConfig.bufferType = ZegoVideoBufferTypeCVPixelBuffer;
    [_zego enableCustomVideoCapture:YES config:captureConfig channel:ZegoPublishChannelMain];
    [_zego setCustomVideoCaptureHandler:self];
    [_zego setVideoMirrorMode:(ZegoVideoMirrorModeNoMirror) channel:ZegoPublishChannelMain];
}
-(void)playRingtone:(CDVInvokedUrlCommand *)command
{
    if(!_audioPlayer){
        NSDictionary *options = [command.arguments objectAtIndex: 0];
        NSString * path = [options valueForKey:@"path"];
        BOOL loop = [[options valueForKey:@"loop"] boolValue];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: [NSURL fileURLWithPath:path] error:nil];
        if(loop){
            [_audioPlayer setNumberOfLoops: -1];
        }else{
            [_audioPlayer setNumberOfLoops: 1];
        }
        [_audioPlayer play];
    }
}
-(void)stopRingtone:(CDVInvokedUrlCommand *)command
{
    if(_audioPlayer){
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
}

//加入房间
-(void) joinRoom:(CDVInvokedUrlCommand *)command
{
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    NSString * roomID = [options valueForKey:@"roomID"];
    NSString * userId = [options valueForKey:@"userId"];
    NSString * userName = [options valueForKey:@"userName"];
    ZegoRoomConfig * conf = [[ZegoRoomConfig alloc] init];
    conf.isUserStatusNotify = YES;
    conf.token = [options valueForKey:@"token"];
    _current_room_id = roomID;
    _hasSwitchView = NO;

    [_zego loginRoom:roomID user:[ZegoUser userWithUserID:userId userName:userName] config: conf];
}

-(void) callStart:(CDVInvokedUrlCommand *)command
{
    [_mineView addGestureRecognizer:self.panGesture];
    [_mineView addGestureRecognizer:self.switchGesture];
    [self send_event:command withMessage:@{@"result":@"ok"} Alive:NO State:YES];
}
-(void) callEnd:(CDVInvokedUrlCommand *)command
{
    if(_play_stream_id) [_zego stopPlayingStream:_play_stream_id];
    if(_current_room_id) [_zego logoutRoom:_current_room_id];
    if(_is_video_call){
        [_captureDevice stopCapture]; //停止摄像头
        [_zego stopPreview: ZegoPublishChannelMain]; //停止预览
        _hasSwitchView = NO;
        [_mineView removeFromSuperview];
        [_playView removeFromSuperview];
    }
    [_zego stopPublishingStream]; //停止推流

    _current_room_id = nil;
    _play_stream_id = nil;
    _live_command = nil;
    _hasSwitchView = NO;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self send_event:command withMessage:@{@"result":@"ok"} Alive:NO State:YES];
}

-(void) startVideoCall:(CDVInvokedUrlCommand *)command
{
    _live_command = command;
    _is_video_call = YES;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    _rootVC.webView.backgroundColor = UIColor.clearColor;
    _rootVC.webView.opaque = false;
    //创建拉流view
    _playView = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [_rootVC.view insertSubview:_playView belowSubview:_rootVC.webView];
    //创建预览view
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat safeTop =  UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
    _mineView = [[UIView alloc] initWithFrame:CGRectMake(size.width - _minWindowWidth - 8, safeTop + 8, _minWindowWidth, _minWindowHeight)];
    [self.viewController.view addSubview: _mineView];

    //开启预览
    [_zego setCameraZoomFactor:1.0 channel:ZegoPublishChannelMain];
    [_zego enableCamera:YES];
    [_zego enableAudioCaptureDevice:NO];
    ZegoCanvas * canvas = [ZegoCanvas canvasWithView: _mineView];
    [canvas setViewMode:ZegoViewModeAspectFill];
    [_zego startPreview: canvas];
    [self send_event:_live_command withMessage:@{@"event":@"startVideoCall"} Alive:YES State:YES];
}

-(void) startVoiceCall:(CDVInvokedUrlCommand *)command
{
    _live_command = command;
    _is_video_call = NO;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [_zego enableCamera:NO];
    [_zego enableAudioCaptureDevice:NO];
    [self send_event:_live_command withMessage:@{@"event":@"startVoiceCall"} Alive:YES State:YES];
}

-(void) startPublish:(CDVInvokedUrlCommand *)command
{
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    NSString *stream_id = [options valueForKey:@"stream_id"];
    [_zego enableAudioCaptureDevice:YES];
    [_zego startPublishingStream:stream_id channel:ZegoPublishChannelMain]; //推流
}

-(void) startPlayStream:(CDVInvokedUrlCommand *)command
{
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    _play_stream_id = [options valueForKey:@"stream_id"];

    if(_is_video_call){
        ZegoCanvas * canvas = [ZegoCanvas canvasWithView: _playView];
        [canvas setViewMode:ZegoViewModeAspectFill];
        [_zego startPlayingStream:_play_stream_id canvas: canvas];

    }else{
        [_zego startPlayingStream:_play_stream_id];
    }
}


-(void) switchCamera:(CDVInvokedUrlCommand *)command
{
    [_captureDevice switchCameraPosition];
    [self send_event:command withMessage:@{@"result":@"ok"} Alive:NO State:YES];
}
-(void) closeCamera:(CDVInvokedUrlCommand *)command
{
    [_captureDevice stopCapture];
    [_zego enableCamera:NO];
    [self send_event:command withMessage:@{@"result":@"ok"} Alive:NO State:YES];
}
-(void) openCamera:(CDVInvokedUrlCommand *)command
{
    [_captureDevice startCapture];
    [_zego enableCamera:YES];
    [self send_event:command withMessage:@{@"result":@"ok"} Alive:NO State:YES];
}

-(void)snapshot:(CDVInvokedUrlCommand *)command
{
    if(_live_command){
        NSData *imageData = UIImageJPEGRepresentation([self imageFromView: _mineView ], 0.8);
        NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
        NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]] URLByAppendingPathExtension:@"jpg"];
        [imageData writeToURL:fileURL atomically:YES];
        imageData = nil;
        [self send_event: _live_command withMessage:@{@"event":@"screen",@"path":[fileURL path]} Alive:YES State:YES];
    }
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
        [self send_event:command withMessage:@{@"result":@"ok"} Alive:NO State:YES];
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
        [self send_event:command withMessage:@{@"result":@"ok"} Alive:NO State:YES];
    }];
}

#pragma mark 视频窗口操作相关
- (UIPanGestureRecognizer *)panGesture
{
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panSmallVideoView:)];
        _panGesture.maximumNumberOfTouches = 1;
        _panGesture.minimumNumberOfTouches = 1;
    }
    return _panGesture;
}

- (UITapGestureRecognizer *)switchGesture
{
    if (!_switchGesture) {
        _switchGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchVideoPreview:)];
        [_switchGesture requireGestureRecognizerToFail:self.panGesture];
    }
    return _switchGesture;
}

- (void)panSmallVideoView:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state != UIGestureRecognizerStateEnded &&
        panGesture.state != UIGestureRecognizerStateFailed) {

        CGPoint location = [panGesture locationInView:[UIApplication sharedApplication].windows[0]];

        CGRect frame = panGesture.view.frame;

        frame.origin.x = location.x - frame.size.width / 2;
        frame.origin.y = location.y - frame.size.height / 2;

        if (frame.origin.x < 0) {
            frame.origin.x = 2;
        }

        if (frame.origin.y < 20) {
            frame.origin.y = 20;
        }

        if (frame.origin.x + frame.size.width > [UIScreen mainScreen].bounds.size.width) {
            frame.origin.x = [UIScreen mainScreen].bounds.size.width - 2 - frame.size.width;
        }

        if (frame.origin.y + frame.size.height >  [UIScreen mainScreen].bounds.size.height) {
            frame.origin.y = [UIScreen mainScreen].bounds.size.height - 2 - frame.size.height;
        }

        panGesture.view.frame = frame;

    } else if (panGesture.state == UIGestureRecognizerStateEnded) {

        NSLog(@"拖动Window结束");
        CGRect frame = panGesture.view.frame;
        CGRect screen = UIScreen.mainScreen.bounds;
        if ((frame.size.width / 2 + frame.origin.x) >= screen.size.width / 2) {
            frame.origin.x = screen.size.width - frame.size.width - 12;
        } else {
            frame.origin.x = 12;
        }

        [UIView animateWithDuration:0.2 animations:^{
            panGesture.view.frame = frame;
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)switchVideoPreview:(UITapGestureRecognizer *)tapGesture
{
    if(_beautyView) [self hideBeauty:nil];
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat safeTop =  UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
    if(!_hasSwitchView){
        [_mineView removeGestureRecognizer:self.panGesture];
        [_mineView removeGestureRecognizer:self.switchGesture];
        [_playView setFrame:CGRectMake(size.width - _minWindowWidth - 8, safeTop + 8, _minWindowWidth, _minWindowHeight)];

        [_mineView setFrame:UIScreen.mainScreen.bounds];

        [_rootVC.webView.superview bringSubviewToFront:_rootVC.webView];
        [_playView.superview bringSubviewToFront:_playView];

        [_playView addGestureRecognizer:self.panGesture];
        [_playView addGestureRecognizer:self.switchGesture];
        _hasSwitchView = YES;
    }else{
        [_playView removeGestureRecognizer:self.panGesture];
        [_playView removeGestureRecognizer:self.switchGesture];
        [_mineView setFrame:CGRectMake(size.width - _minWindowWidth - 8, safeTop + 8, _minWindowWidth, _minWindowHeight)];

        [_playView setFrame:UIScreen.mainScreen.bounds];

        [_rootVC.webView.superview bringSubviewToFront:_rootVC.webView];
        [_mineView.superview bringSubviewToFront:_mineView];

        [_mineView addGestureRecognizer:self.panGesture];
        [_mineView addGestureRecognizer:self.switchGesture];
        _hasSwitchView = NO;
    }
}

#pragma mark FUAPIDemoBarDelegate

-(void)filterValueChange:(FUBeautyParam *)param{
    if(_saveButton.isHidden){
        [_saveButton setHidden:NO];
    }
    [[FUManager shareManager] filterValueChange:param];
}

-(void)switchRenderState:(BOOL)state{
    [FUManager shareManager].isRender = state;
}

-(void)bottomDidChange:(int)index{
    [self touchfeedback];
    if (index < 3) {
        [[FUManager shareManager] setRenderType:FUDataTypeFilter];
    }
}

- (void)showTopView:(BOOL)shown {}

#pragma mark ZGCaptureDeviceDataOutputPixelBufferDelegate

- (void)onStart:(ZegoPublishChannel)channel {
    [self.captureDevice startCapture];
}

- (void)onStop:(ZegoPublishChannel)channel {
    [self.captureDevice stopCapture];
}

- (void)captureDevice:(id<ZGCaptureDevice>)device didCapturedData:(CMSampleBufferRef)data {
    // BufferType: CVPixelBuffer
    CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(data);
    CMTime timeStamp = CMSampleBufferGetPresentationTimeStamp(data);
    CVPixelBufferRef fuBuffer = [[FUManager shareManager] renderItemsToPixelBuffer:buffer];
    [[ZegoExpressEngine sharedEngine] sendCustomVideoCapturePixelBuffer:fuBuffer timestamp:timeStamp];
}


#pragma mark ZegoCustomVideoCaptureHandler
#pragma mark Room Event
- (void)onRoomStateUpdate:(ZegoRoomState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData roomID:(NSString *)roomID {
    [self send_event:_live_command withMessage:@{@"event":@"onRoomStateUpdate",@"state":@(state)} Alive:YES State:YES];
}

- (void)onRoomUserUpdate:(ZegoUpdateType)updateType userList:(NSArray<ZegoUser *> *)userList roomID:(NSString *)roomID {
    NSMutableArray *userlist = [NSMutableArray array];
    for (int i = 0 ; i < [userList count] ; i ++) {
        [userlist addObject:@{@"uid": userList[i].userID , @"nickname": userList[i].userName}];
    }
    if(updateType == ZegoUpdateTypeAdd){ //新用户进入
        [self send_event:_live_command withMessage:@{@"event":@"user_join",@"userlist":userlist} Alive:YES State:YES];
    }
    if(updateType == ZegoUpdateTypeDelete){ //用户离开房间
        [self send_event:_live_command withMessage:@{@"event":@"user_exit",@"userlist":userlist} Alive:YES State:YES];
    }
}

- (void)onRoomStreamUpdate:(ZegoUpdateType)updateType streamList:(NSArray<ZegoStream *> *)streamList extendedData:(NSDictionary *)extendedData roomID:(NSString *)roomID {
    NSMutableArray *userlist = [NSMutableArray array];
    for (int i = 0 ; i < [streamList count] ; i ++) {
        [userlist addObject:@{@"uid": streamList[i].user.userID , @"nickname": streamList[i].user.userName}];
    }
    if(updateType == ZegoUpdateTypeAdd){ //新用户开始推流
        [self send_event:_live_command withMessage:@{@"event":@"user_start_publish",@"userlist":userlist} Alive:YES State:YES];
    }
    if(updateType == ZegoUpdateTypeDelete){ //用户停止推流
        [self send_event:_live_command withMessage:@{@"event":@"user_end_publish",@"userlist":userlist} Alive:YES State:YES];
    }
}


#pragma mark Publisher Callback

- (void)onPublisherStateUpdate:(ZegoPublisherState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData streamID:(NSString *)streamID {
    [self send_event:_live_command withMessage:@{@"event":@"onPublisherStateUpdate",@"state":@(state)} Alive:YES State:YES];
}

- (void)onPublisherQualityUpdate:(ZegoPublishStreamQuality *)quality streamID:(NSString *)streamID {
    [self send_event:_live_command withMessage:@{@"event":@"onPublisherQualityUpdate",@"fps":@(quality.videoSendFPS)} Alive:YES State:YES];
}

- (void)onPublisherCapturedAudioFirstFrame {
    [self send_event:_live_command withMessage:@{@"event":@"onPublisherCapturedAudioFirstFrame"} Alive:YES State:YES];
}

- (void)onPublisherCapturedVideoFirstFrame:(ZegoPublishChannel)channel {
    [self send_event:_live_command withMessage:@{@"event":@"onPublisherCapturedVideoFirstFrame"} Alive:YES State:YES];
}

- (void)onPublisherVideoSizeChanged:(CGSize)size channel:(ZegoPublishChannel)channel {
    [self send_event:_live_command withMessage:@{@"event":@"onPublisherVideoSizeChanged"} Alive:YES State:YES];
}

- (void)onPublisherRelayCDNStateUpdate:(NSArray<ZegoStreamRelayCDNInfo *> *)streamInfoList streamID:(NSString *)streamID {
    [self send_event:_live_command withMessage:@{@"event":@"onPublisherRelayCDNStateUpdate"} Alive:YES State:YES];
}

#pragma mark Player Callback

- (void)onPlayerStateUpdate:(ZegoPlayerState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData streamID:(NSString *)streamID {
    [self send_event:_live_command withMessage:@{@"event":@"onPlayerStateUpdate",@"state":@(state)} Alive:YES State:YES];
}

- (void)onPlayerQualityUpdate:(ZegoPlayStreamQuality *)quality streamID:(NSString *)streamID {
    [self send_event:_live_command withMessage:@{@"event":@"onPlayerQualityUpdate",
                                                 @"fps":@(quality.videoRecvFPS)} Alive:YES State:YES];
}

- (void)onPlayerMediaEvent:(ZegoPlayerMediaEvent)event streamID:(NSString *)streamID {
    [self send_event:_live_command withMessage:@{@"event":@"onPlayerMediaEvent",@"state":@(event)} Alive:YES State:YES];
}

- (void)onPlayerRecvAudioFirstFrame:(NSString *)streamID {
    [self send_event:_live_command withMessage:@{@"event":@"onPlayerRecvAudioFirstFrame"} Alive:YES State:YES];
}

- (void)onPlayerRecvVideoFirstFrame:(NSString *)streamID {
    [self send_event:_live_command withMessage:@{@"event":@"onPlayerRecvVideoFirstFrame"} Alive:YES State:YES];
}

- (void)onPlayerRenderVideoFirstFrame:(NSString *)streamID {
    [self send_event:_live_command withMessage:@{@"event":@"onPlayerRenderVideoFirstFrame"} Alive:YES State:YES];
}

- (void)onPlayerVideoSizeChanged:(CGSize)size streamID:(NSString *)streamID {
    [self send_event:_live_command withMessage:@{@"event":@"onPlayerVideoSizeChanged"} Alive:YES State:YES];
}




#pragma mark 美颜加载与保存

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

#pragma mark 公共方法

-(void)touchfeedback
{
    UIImpactFeedbackGenerator *feedBackGenertor = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedBackGenertor impactOccurred];
}

- (id)settingForKey:(NSString*)key
{
    return [self.commandDelegate.settings objectForKey:[key lowercaseString]];
}

- (void)send_event:(CDVInvokedUrlCommand *)command withMessage:(NSDictionary *)message Alive:(BOOL)alive State:(BOOL)state{
    if(!command) return;
    CDVPluginResult* res = [CDVPluginResult resultWithStatus: (state ? CDVCommandStatus_OK : CDVCommandStatus_ERROR) messageAsDictionary:message];
    if(alive) [res setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult: res callbackId: command.callbackId];
}
- (UIImage *)imageFromView:(UIView *)view
{
    UIScreen *screen = [UIScreen mainScreen];
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, screen.scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end
