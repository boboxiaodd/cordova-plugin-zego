//
//  FUManager.m
//  FULiveDemo
//
//  Created by 刘洋 on 2017/8/18.
//  Copyright © 2017年 刘洋. All rights reserved.
//

#import "FUManager.h"
#import <CoreMotion/CoreMotion.h>
#import "authpack.h"
#import <sys/utsname.h>

@interface FUManager ()
{
    //MARK: Faceunity
    int items[FUNamaHandleTotal];
    int frameID;
    NSString *oldMakeup;
}

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) FUDevicePerformanceLevel devicePerformanceLevel;
@property (nonatomic, assign) int deviceOrientation;


@end

static FUManager *shareManager = NULL;

@implementation FUManager

+ (FUManager *)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [[FUManager alloc] init];
    });

    return shareManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        FUSetupConfig *setupConfig = [[FUSetupConfig alloc] init];
        setupConfig.authPack = FUAuthPackMake(g_auth_package, sizeof(g_auth_package));
        
        // 初始化 FURenderKit
        [FURenderKit setupWithSetupConfig:setupConfig];
        
        [FURenderKit setLogLevel:FU_LOG_LEVEL_INFO];
        
        self.devicePerformanceLevel = [FURenderKit devicePerformanceLevel];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // 加载人脸 AI 模型
            NSString *faceAIPath = [[NSBundle mainBundle] pathForResource:@"ai_face_processor" ofType:@"bundle"];
            NSLog(@"ai_face_processor = %@",faceAIPath);
            [FUAIKit loadAIModeWithAIType:FUAITYPE_FACEPROCESSOR dataPath:faceAIPath];
            
            // 设置人脸算法质量
            [FUAIKit shareKit].faceProcessorFaceLandmarkQuality = self.devicePerformanceLevel == FUDevicePerformanceLevelHigh ? FUFaceProcessorFaceLandmarkQualityHigh : FUFaceProcessorFaceLandmarkQualityMedium;
            
            // 设置小脸检测是否打开
            [FUAIKit shareKit].faceProcessorDetectSmallFace = self.devicePerformanceLevel == FUDevicePerformanceLevelHigh;
            
            
            NSString *path = [[NSBundle mainBundle] pathForResource:@"face_beautification" ofType:@"bundle"];
            self.beauty = [[FUBeauty alloc] initWithPath:path name:@"FUBeauty"];
            [FURenderKit shareRenderKit].beauty = self.beauty;
            
            /* 默认精细磨皮 */
            [[FURenderKit shareRenderKit].beauty setHeavyBlur:0];
            [[FURenderKit shareRenderKit].beauty setBlurType:2];
            [[FURenderKit shareRenderKit].beauty setFaceShape:4];
            
            [self setupSkinData];
            [self setupShapData];
            [self setupFilterData];
            [self setBeautyParameters];

        });
        
        [FUAIKit shareKit].maxTrackFaces = 1;
    }
    
    return self;
}


#pragma mark -  nama查询&设置
- (void) setAsyncTrackFaceEnable:(BOOL)enable{

    [FURenderer setAsyncTrackFaceEnable:enable];
}

- (void)loadBundleWithName:(NSString *)name aboutType:(FUNamaHandleType)type{
    dispatch_async(_asyncLoadQueue, ^{
        if (self->items[type] != 0) {
            NSLog(@"faceunity: destroy item");
            [FURenderer destroyItem:self->items[type]];
            self->items[type] = 0;
        }
        if ([name isEqualToString:@""] || !name) {
            return ;
        }
        NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"bundle"];
        self->items[type] = [FURenderer itemWithContentsOfFile:filePath];
    });
}

-(void)setParamItemAboutType:(FUNamaHandleType)type name:(NSString *)paramName value:(float)value{
    dispatch_async(_asyncLoadQueue, ^{
        if(self->items[type]){
            [FURenderer itemSetParam:self->items[type] withName:paramName value:@(value)];
        NSLog(@"设置type(%lu)----参数（%@）-----值（%lf",(unsigned long)self->items[type],paramName,value);
       }
    });
}


- (void)destoryItemAboutType:(FUNamaHandleType)type;
{
    dispatch_async(_asyncLoadQueue, ^{
        /**后销毁老道具句柄*/
        if (self->items[type] != 0) {
            NSLog(@"faceunity: destroy item");
            [FURenderer destroyItem:self->items[type]];
            self->items[type] = 0;
        }
    });
}

-(int)getHandleAboutType:(FUNamaHandleType)type{
    return items[type];
}

-(void)setRenderType:(FUDataType)dateType{
    _currentType = dateType;
}

static int oldHandle = 0;
-(void)filterValueChange:(FUBeautyParam *)param{
    NSLog(@" %@ = %f %lu",param.mParam, param.mValue, (unsigned long)param.type);
   if (param.type == FUDataTypeBeautify) {
       if ([param.mParam isEqualToString:@"cheek_narrow"] || [param.mParam isEqualToString:@"cheek_small"]){//程度值 只去一半
           [[FURenderKit shareRenderKit].beauty setValue:@(param.mValue * 0.5) forKey:param.mParam];
       }else if([param.mParam isEqualToString:@"blur_level"]) {//磨皮 0~6
           [[FURenderKit shareRenderKit].beauty setValue:@(param.mValue * 6) forKey:param.mParam];
       }else{
           [[FURenderKit shareRenderKit].beauty setValue:@(param.mValue) forKey:param.mParam];
       }
   }else if (param.type == FUDataTypeFilter){
       [[FURenderKit shareRenderKit].beauty setFilterName:[param.mParam lowercaseString]];
       [[FURenderKit shareRenderKit].beauty setFilterLevel:param.mValue];
       self.seletedFliter = param;
   }
}


/**加载美颜道具*/
- (void)loadFilter{

}


- (void)setBeautyParameters{
   for (FUBeautyParam *modle in _skinParams){
        if ([modle.mParam isEqualToString:@"blur_level"]) {
            [[FURenderKit shareRenderKit].beauty setValue:@(modle.mValue * 6) forKey:modle.mParam];
        }else{
            [[FURenderKit shareRenderKit].beauty setValue:@(modle.mValue) forKey:modle.mParam];
        }
    }
    
    for (FUBeautyParam *modle in _shapeParams){
        [[FURenderKit shareRenderKit].beauty setValue:@(modle.mValue) forKey:modle.mParam];
     }
    
    
    /* 设置默认状态 */
    if (self.seletedFliter) {
        [[FURenderKit shareRenderKit].beauty setFilterName:[self.seletedFliter.mParam lowercaseString]];
        [[FURenderKit shareRenderKit].beauty setFilterLevel:self.seletedFliter.mValue];
    }
}

-(void)setupFilterData{
    NSArray *beautyFiltersDataSource = @[@"origin",
                                         @"ziran1",
                                         @"ziran2",
                                         @"ziran3",
                                         @"ziran4",
                                         @"ziran5",
                                         @"ziran6",
                                         @"ziran7",
                                         @"ziran8",
                                         @"zhiganhui1",
                                         @"zhiganhui2",
                                         @"zhiganhui3",
                                         @"zhiganhui4",
                                         @"zhiganhui5",
                                         @"zhiganhui6",
                                         @"zhiganhui7",
                                         @"zhiganhui8",
                                         @"bailiang1",
                                         @"bailiang2",
                                         @"bailiang3",
                                         @"bailiang4",
                                         @"bailiang5",
                                         @"bailiang6",
                                         @"bailiang7",
                                         @"fennen1",
                                         @"fennen2",
                                         @"fennen3",
                                         @"fennen5",
                                         @"fennen6",
                                         @"fennen7",
                                         @"fennen8",
                                         @"lengsediao1",@"lengsediao2",@"lengsediao3",@"lengsediao4",@"lengsediao7",@"lengsediao8",@"lengsediao11",
                                         @"nuansediao1",@"nuansediao2",
                                         @"gexing1",@"gexing2",@"gexing3",@"gexing4",@"gexing5",@"gexing7",@"gexing10",@"gexing11",
                                         @"xiaoqingxin1",@"xiaoqingxin3",@"xiaoqingxin4",@"xiaoqingxin6",
                                         @"heibai1",@"heibai2",@"heibai3",@"heibai4"];
    
    NSDictionary *filtersCHName = @{@"origin":@"原图",@"bailiang1":@"白亮1",@"bailiang2":@"白亮2",@"bailiang3":@"白亮3",@"bailiang4":@"白亮4",@"bailiang5":@"白亮5",@"bailiang6":@"白亮6",@"bailiang7":@"白亮7"
                                    ,@"fennen1":@"粉嫩1",@"fennen2":@"粉嫩2",@"fennen3":@"粉嫩3",@"fennen4":@"粉嫩4",@"fennen5":@"粉嫩5",@"fennen6":@"粉嫩6",@"fennen7":@"粉嫩7",@"fennen8":@"粉嫩8",
                                    @"gexing1":@"个性1",@"gexing2":@"个性2",@"gexing3":@"个性3",@"gexing4":@"个性4",@"gexing5":@"个性5",@"gexing6":@"个性6",@"gexing7":@"个性7",@"gexing8":@"个性8",@"gexing9":@"个性9",@"gexing10":@"个性10",@"gexing11":@"个性11",
                                    @"heibai1":@"黑白1",@"heibai2":@"黑白2",@"heibai3":@"黑白3",@"heibai4":@"黑白4",@"heibai5":@"黑白5",
                                    @"lengsediao1":@"冷色调1",@"lengsediao2":@"冷色调2",@"lengsediao3":@"冷色调3",@"lengsediao4":@"冷色调4",@"lengsediao5":@"冷色调5",@"lengsediao6":@"冷色调6",@"lengsediao7":@"冷色调7",@"lengsediao8":@"冷色调8",@"lengsediao9":@"冷色调9",@"lengsediao10":@"冷色调10",@"lengsediao11":@"冷色调11",
                                    @"nuansediao1":@"暖色调1",@"nuansediao2":@"暖色调2",@"nuansediao3":@"暖色调3",@"xiaoqingxin1":@"小清新1",@"xiaoqingxin2":@"小清新2",@"xiaoqingxin3":@"小清新3",@"xiaoqingxin4":@"小清新4",@"xiaoqingxin5":@"小清新5",@"xiaoqingxin6":@"小清新6",
                                    @"ziran1":@"自然1",@"ziran2":@"自然2",@"ziran3":@"自然3",@"ziran4":@"自然4",@"ziran5":@"自然5",@"ziran6":@"自然6",@"ziran7":@"自然7",@"ziran8":@"自然8",
                                    @"zhiganhui1":@"质感灰1",@"zhiganhui2":@"质感灰2",@"zhiganhui3":@"质感灰3",@"zhiganhui4":@"质感灰4",@"zhiganhui5":@"质感灰5",@"zhiganhui6":@"质感灰6",@"zhiganhui7":@"质感灰7",@"zhiganhui8":@"质感灰8"
    };
    if (!_filters) {
        _filters = [[NSMutableArray alloc] init];
    }
    
    for (NSString *str in beautyFiltersDataSource) {
        FUBeautyParam *modle = [[FUBeautyParam alloc] init];
        modle.mParam = str;
        modle.mTitle = [filtersCHName valueForKey:str];
        modle.mValue = 0.4;
        modle.type = FUDataTypeFilter;

        [_filters addObject:modle];
    }
    NSLog(@"load filter from default: %@",_filters[24].mTitle);
    self.seletedFliter = _filters[24];
}

-(void)setupSkinData{
    NSArray *prams = @[@"blurLevel",@"colorLevel",@"redLevel",@"sharpen",@"eyeBright",@"toothWhiten",@"removePouchStrength",@"removeNasolabialFoldsStrength"];//
    NSDictionary *titelDic = @{@"blurLevel":@"精细磨皮",
                               @"colorLevel":@"美白",
                               @"redLevel":@"红润",
                               @"sharpen":@"锐化",
                               @"removePouchStrength":@"去黑眼圈",
                               @"removeNasolabialFoldsStrength":@"去法令纹",
                               @"eyeBright":@"亮眼",
                               @"toothWhiten":@"美牙"};
    NSDictionary *defaultValueDic = @{@"blurLevel":@(1.0),
                                      @"colorLevel":@(0.8),
                                      @"redLevel":@(0.6),
                                      @"sharpen":@(0.2),
                                      @"removePouchStrength":@(0),
                                      @"removeNasolabialFoldsStrength":@(0),
                                      @"eyeBright":@(0.2),
                                      @"toothWhiten":@(0.2)};
    
    
    if (!_skinParams) {
        _skinParams = [[NSMutableArray alloc] init];
    }

    for (NSString *str in prams) {

        FUBeautyParam *modle = [[FUBeautyParam alloc] init];
        modle.mParam = str;
        modle.mTitle = [titelDic valueForKey:str];
        modle.mValue = [[defaultValueDic valueForKey:str] floatValue];
        modle.defaultValue = modle.mValue;
        [_skinParams addObject:modle];
    }

}

-(void)setupShapData{
   NSArray *prams = @[@"cheekThinning",@"cheekV",@"cheekNarrow",@"cheekSmall",@"eyeEnlarging",@"intensityChin",@"intensityForehead",@"intensityNose",@"intensityMouth",@"intensityCanthus",@"intensityEyeSpace",@"intensityEyeRotate",@"intensityLongNose",@"intensityPhiltrum",@"intensitySmile"];
    NSDictionary *titelDic = @{@"cheekThinning":@"瘦脸",@"cheekV":@"v脸",@"cheekNarrow":@"窄脸",@"cheekSmall":@"小脸",@"eyeEnlarging":@"大眼",@"intensityChin":@"下巴",
                               @"intensityForehead":@"额头",@"intensityNose":@"瘦鼻",@"intensityMouth":@"嘴型",@"intensityCanthus":@"开眼角",@"intensityEyeSpace":@"眼距",@"intensityEyeRotate":@"眼睛角度",@"intensityLongNose":@"长鼻",@"intensityPhiltrum":@"缩人中",@"intensitySmile":@"微笑嘴角"
    };
   NSDictionary *defaultValueDic = @{@"cheekThinning":@(0.2),
                                     @"cheekV":@(0.2),
                                     @"cheekNarrow":@(0.2),
                                     @"cheekSmall":@(0.2),
                                     @"eyeEnlarging":@(0.2),
                                     @"intensityChin":@(0.5),
                                     @"intensityForehead":@(0.5),
                                     @"intensityNose":@(0),
                                     @"intensityMouth":@(0.5),
                                     @"intensityCanthus":@(0),
                                     @"intensityEyeSpace":@(0.5),
                                     @"intensityEyeRotate":@(0.5),
                                     @"intensityLongNose":@(0.5),
                                     @"intensityPhiltrum":@(0.5),
                                     @"intensitySmile":@(0)
   };
   
   if (!_shapeParams) {
       _shapeParams = [[NSMutableArray alloc] init];
   }
   
   for (NSString *str in prams) {
       BOOL isStyle101 = NO;
       if ([str isEqualToString:@"intensityChin"] || [str isEqualToString:@"intensityForehead"] || [str isEqualToString:@"intensityMouth"] || [str isEqualToString:@"intensityEyeSpace"] || [str isEqualToString:@"intensityEyeRotate"] || [str isEqualToString:@"intensityLongNose"] || [str isEqualToString:@"intensityPhiltrum"]) {
           isStyle101 = YES;
       }
       
       FUBeautyParam *modle = [[FUBeautyParam alloc] init];
       modle.mParam = str;
       modle.mTitle = [titelDic valueForKey:str];
       modle.mValue = [[defaultValueDic valueForKey:str] floatValue];
       modle.defaultValue = modle.mValue;
       modle.iSStyle101 = isStyle101;
       [_shapeParams addObject:modle];
   }
}

/**销毁全部道具*/
- (void)destoryItems
{
    NSLog(@"destoryItems...");
    [FURenderKit shareRenderKit].beauty = nil;
    [FURenderKit shareRenderKit].bodyBeauty = nil;
    [FURenderKit shareRenderKit].makeup = nil;
    [[FURenderKit shareRenderKit].stickerContainer removeAllSticks];
//    [FURenderer destroyAllItems];
//
//    /**销毁道具后，为保证被销毁的句柄不再被使用，需要将int数组中的元素都设为0*/
//    for (int i = 0; i < sizeof(items) / sizeof(int); i++) {
//        items[i] = 0;
//    }
//
//    /**销毁道具后，清除context缓存*/
//    [FURenderer OnDeviceLost];
//
//    /**销毁道具后，重置人脸检测*/
//    [FURenderer onCameraChange];
//
//    oldMakeup = nil;
    
}

//-(void)getNeedRenderItems:()


#pragma mark -  render
/**将道具绘制到pixelBuffer*/
- (CVPixelBufferRef)renderItemsToPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    if ([self isDeviceMotionChange]) {
        fuSetDefaultRotationMode(self.deviceOrientation);
            /* 解决旋转屏幕效果异常 onCameraChange*/
        [FURenderer onCameraChange];
        
        [FURenderer itemSetParam:items[FUNamaHandleTypeBodySlim] withName:@"Orientation" value:@(self.deviceOrientation)];
    }
    
    if (_isRender) {
        /* 由于 rose 妆可能会镜像，下面代码对妆容做镜像翻转 */
         int temp = self.flipx? 1:0;
        [FURenderer itemSetParam:items[FUNamaHandleTypeMakeup] withName:@"is_flip_points" value:@(temp)];
        
        /* 美妆，美体，贴纸 性能问题不共用 */
        static int readerItems[2] = {0};
        readerItems[0] = items[FUNamaHandleTypeBeauty];
        if (_currentType == FUDataTypeMakeup) {
            readerItems[1] = items[FUNamaHandleTypeMakeup];
        }
        if (_currentType == FUDataTypeStrick) {
            readerItems[1] = items[FUNamaHandleTypeItem];
        }
        if (_currentType == FUDataTypebody) {
            readerItems[1] = items[FUNamaHandleTypeBodySlim];
            [FURenderer itemSetParam:items[FUNamaHandleTypeBodySlim] withName:@"Orientation" value:@(self.deviceOrientation)];
        }

        CVPixelBufferRef buffer = [[FURenderer shareRenderer] renderPixelBuffer:pixelBuffer withFrameId:frameID items:readerItems itemCount:2 flipx:_flipx];//flipx 参数设为YES可以使道具做水平方向的镜像翻转
        frameID += 1;
    }

    
    return pixelBuffer;
}

/**处理YUV*/
- (void)processFrameWithY:(void*)y U:(void*)u V:(void*)v yStride:(int)ystride uStride:(int)ustride vStride:(int)vstride FrameWidth:(int)width FrameHeight:(int)height {
    if ([self isDeviceMotionChange]) {
        fuSetDefaultRotationMode(self.deviceOrientation);
        /* 解决旋转屏幕效果异常 onCameraChange*/
        [FURenderer onCameraChange];
    }
    
    /* 由于 rose 妆可能会镜像，下面代码对妆容做镜像翻转 */
     int temp = self.flipx? 1:0;
    [FURenderer itemSetParam:items[FUNamaHandleTypeMakeup] withName:@"is_flip_points" value:@(temp)];
    
    /* 美妆，美体，贴纸 性能问题不共用 */
    static int readerItems[2] = {0};
    readerItems[0] = items[FUNamaHandleTypeBeauty];
    if (_currentType == FUDataTypeMakeup) {
        readerItems[1] = items[FUNamaHandleTypeMakeup];
    }
    if (_currentType == FUDataTypeStrick) {
        readerItems[1] = items[FUNamaHandleTypeItem];
    }
    if (_currentType == FUDataTypebody) {
        readerItems[1] = items[FUNamaHandleTypeBodySlim];
    }
    
    [[FURenderer shareRenderer] renderFrame:y u:u  v:v  ystride:ystride ustride:ustride vstride:vstride width:width height:height frameId:frameID items:readerItems itemCount:2];
    frameID ++ ;
}

/**将道具绘制到pixelBuffer*/

- (int)renderItemWithTexture:(int)texture Width:(int)width Height:(int)height {
    if ([self isDeviceMotionChange]) {
        // 设置识别方向
        fuSetDefaultRotationMode(self.deviceOrientation);
        /* 解决旋转屏幕效果异常 onCameraChange*/
        [FURenderer onCameraChange];
    }
    
    if (_isRender) {
        
        [self prepareToRender];
        
        /* 由于 rose 妆可能会镜像，下面代码对妆容做镜像翻转 */
         int temp = self.flipx? 1:0;
        [FURenderer itemSetParam:items[FUNamaHandleTypeMakeup] withName:@"is_flip_points" value:@(temp)];
        
        /* 美妆，美体，贴纸 性能问题不共用 */
        static int readerItems[2] = {0};
        readerItems[0] = items[FUNamaHandleTypeBeauty];
        if (_currentType == FUDataTypeMakeup) {
            readerItems[1] = items[FUNamaHandleTypeMakeup];
        }
        if (_currentType == FUDataTypeStrick) {
            readerItems[1] = items[FUNamaHandleTypeItem];
        }
        if (_currentType == FUDataTypebody) {
            readerItems[1] = items[FUNamaHandleTypeBodySlim];
            [FURenderer itemSetParam:items[FUNamaHandleTypeBodySlim] withName:@"Orientation" value:@(self.deviceOrientation)];
        }
        
        if(self.flipx){
           fuRenderItemsEx2(FU_FORMAT_RGBA_TEXTURE,&texture, FU_FORMAT_RGBA_TEXTURE, &texture, width, height, frameID, readerItems, 2, NAMA_RENDER_OPTION_FLIP_X | NAMA_RENDER_FEATURE_FULL, NULL);
        }else{
           fuRenderItemsEx(FU_FORMAT_RGBA_TEXTURE, &texture, FU_FORMAT_RGBA_TEXTURE, &texture, width, height, frameID, readerItems, 2) ;
        }

        [self renderFlush];
        
        frameID ++ ;
        
    }
   
    return texture;
}

// 此方法用于提高 FaceUnity SDK 和 腾讯 SDK 的兼容性
 static int enabled[10];
- (void)prepareToRender {
    for (int i = 0; i<10; i++) {
        glGetVertexAttribiv(i,GL_VERTEX_ATTRIB_ARRAY_ENABLED,&enabled[i]);
    }
}

// 此方法用于提高 FaceUnity SDK 和 腾讯 SDK 的兼容性
- (void)renderFlush {
    glFlush();
    
    for (int i = 0; i<10; i++) {
        
        if(enabled[i]){
            glEnableVertexAttribArray(i);
        }
        else{
            glDisableVertexAttribArray(i);
        }
    }
}


#pragma mark -  重力感应
-(void)setupDeviceMotion{
    // 初始化陀螺仪
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.5;// 1s刷新一次
    
    if ([self.motionManager isDeviceMotionAvailable]) {
       [self.motionManager startAccelerometerUpdates];
         [self.motionManager startDeviceMotionUpdates];
    }
}

-(BOOL)isDeviceMotionChange{
//    if (![FURenderer isTracking]) {
        CMAcceleration acceleration = self.motionManager.accelerometerData.acceleration ;
        int orientation = 0;
        if (acceleration.x >= 0.75) {
            orientation = self.trackFlipx ? 3:1;
        } else if (acceleration.x <= -0.75) {
            orientation = self.trackFlipx ? 1:3;;
        } else if (acceleration.y <= -0.75) {
            orientation = 0;
        } else if (acceleration.y >= 0.75) {
            orientation = 2;
        }
    
        if (self.deviceOrientation != orientation) {
            self.deviceOrientation = orientation ;
            NSLog(@"屏幕方向-----%d",self.deviceOrientation);

            return YES;
        }
//    }
    return NO;
}



/**获取图像中人脸中心点*/
- (CGPoint)getFaceCenterInFrameSize:(CGSize)frameSize{
    
    static CGPoint preCenter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        preCenter = CGPointMake(0.5, 0.5);
    });
    
    // 获取人脸矩形框，坐标系原点为图像右下角，float数组为矩形框右下角及左上角两个点的x,y坐标（前两位为右下角的x,y信息，后两位为左上角的x,y信息）
    float faceRect[4];
    int ret = [FURenderer getFaceInfo:0 name:@"face_rect" pret:faceRect number:4];
    
    if (ret == 0) {
        return preCenter;
    }
    
    // 计算出中心点的坐标值
    CGFloat centerX = (faceRect[0] + faceRect[2]) * 0.5;
    CGFloat centerY = (faceRect[1] + faceRect[3]) * 0.5;
    
    // 将坐标系转换成以左上角为原点的坐标系
    centerX = frameSize.width - centerX;
    centerX = centerX / frameSize.width;
    
    centerY = frameSize.height - centerY;
    centerY = centerY / frameSize.height;
    
    CGPoint center = CGPointMake(centerX, centerY);
    
    preCenter = center;
    
    return center;
}

/**获取75个人脸特征点*/
- (void)getLandmarks:(float *)landmarks
{
    int ret = [FURenderer getFaceInfo:0 name:@"landmarks" pret:landmarks number:150];
    
    if (ret == 0) {
        memset(landmarks, 0, sizeof(float)*150);
    }
}

/**判断是否检测到人脸*/
- (BOOL)isTracking
{
    return [FURenderer isTracking] > 0;
}

/**切换摄像头要调用此函数*/
- (void)onCameraChange
{
    [FURenderer onCameraChange];
}

/**获取错误信息*/
- (NSString *)getError
{
    // 获取错误码
    int errorCode = fuGetSystemError();
    
    if (errorCode != 0) {
        
        // 通过错误码获取错误描述
        NSString *errorStr = [NSString stringWithUTF8String:fuGetSystemErrorString(errorCode)];
        
        return errorStr;
    }
    
    return nil;
}


@end
