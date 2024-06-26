//
//  FUDateHandle.m
//  FULiveDemo
//
//  Created by 孙慕 on 2020/6/20.
//  Copyright © 2020 FaceUnity. All rights reserved.
//

#import "FUDateHandle.h"
#import "FUBeautyParam.h"

@implementation FUDateHandle


+(NSArray<FUBeautyParam *>*)setupFilterData{
    NSArray *beautyFiltersDataSource = @[@"origin",
                                         @"fennen1",@"fennen2",@"fennen3",@"fennen5",@"fennen6",@"fennen7",@"fennen8",
                                         @"ziran1",@"ziran2",@"ziran3",@"ziran4",@"ziran5",@"ziran6",@"ziran7",@"ziran8",
                                         @"zhiganhui1",@"zhiganhui2",@"zhiganhui3",@"zhiganhui4",@"zhiganhui5",@"zhiganhui6",@"zhiganhui7",@"zhiganhui8",
                                         @"bailiang1",@"bailiang2",@"bailiang3",@"bailiang4",@"bailiang5",@"bailiang6",@"bailiang7",
                                         @"lengsediao1",@"lengsediao2",@"lengsediao3",@"lengsediao4",@"lengsediao7",@"lengsediao8",@"lengsediao11",
                                         @"nuansediao1",@"nuansediao2",
                                         @"gexing1",@"gexing2",@"gexing3",@"gexing4",@"gexing5",@"gexing7",@"gexing10",@"gexing11",
                                         @"xiaoqingxin1",@"xiaoqingxin3",@"xiaoqingxin4",@"xiaoqingxin6",
                                         @"heibai1",@"heibai2",@"heibai3",@"heibai4"];
    
    NSDictionary *filtersCHName = @{@"origin":@"原图",
        @"fennen1":@"粉嫩1",@"fennen2":@"粉嫩2",@"fennen3":@"粉嫩3",@"fennen4":@"粉嫩4",@"fennen5":@"粉嫩5",@"fennen6":@"粉嫩6",@"fennen7":@"粉嫩7",@"fennen8":@"粉嫩8",
          @"bailiang1":@"白亮1",@"bailiang2":@"白亮2",@"bailiang3":@"白亮3",@"bailiang4":@"白亮4",@"bailiang5":@"白亮5",@"bailiang6":@"白亮6",@"bailiang7":@"白亮7",
          @"gexing1":@"个性1",@"gexing2":@"个性2",@"gexing3":@"个性3",@"gexing4":@"个性4",@"gexing5":@"个性5",@"gexing6":@"个性6",@"gexing7":@"个性7",@"gexing8":@"个性8",@"gexing9":@"个性9",@"gexing10":@"个性10",@"gexing11":@"个性11",
        @"heibai1":@"黑白1",@"heibai2":@"黑白2",@"heibai3":@"黑白3",@"heibai4":@"黑白4",@"heibai5":@"黑白5",
        @"lengsediao1":@"冷色调1",@"lengsediao2":@"冷色调2",@"lengsediao3":@"冷色调3",@"lengsediao4":@"冷色调4",@"lengsediao5":@"冷色调5",@"lengsediao6":@"冷色调6",@"lengsediao7":@"冷色调7",@"lengsediao8":@"冷色调8",@"lengsediao9":@"冷色调9",@"lengsediao10":@"冷色调10",@"lengsediao11":@"冷色调11",
        @"nuansediao1":@"暖色调1",@"nuansediao2":@"暖色调2",@"nuansediao3":@"暖色调3",
        @"xiaoqingxin1":@"小清新1",@"xiaoqingxin2":@"小清新2",@"xiaoqingxin3":@"小清新3",@"xiaoqingxin4":@"小清新4",@"xiaoqingxin5":@"小清新5",@"xiaoqingxin6":@"小清新6",
        @"ziran1":@"自然1",@"ziran2":@"自然2",@"ziran3":@"自然3",@"ziran4":@"自然4",@"ziran5":@"自然5",@"ziran6":@"自然6",@"ziran7":@"自然7",@"ziran8":@"自然8",
        @"zhiganhui1":@"质感灰1",@"zhiganhui2":@"质感灰2",@"zhiganhui3":@"质感灰3",@"zhiganhui4":@"质感灰4",@"zhiganhui5":@"质感灰5",@"zhiganhui6":@"质感灰6",@"zhiganhui7":@"质感灰7",@"zhiganhui8":@"质感灰8"
    };

    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSString *str in beautyFiltersDataSource) {
        FUBeautyParam *modle = [[FUBeautyParam alloc] init];
        modle.mParam = str;
        modle.mTitle = [filtersCHName valueForKey:str];
        modle.mValue = 0.4;
        modle.type = FUDataTypeFilter;
        [array addObject:modle];
    }
    
    return array;
}

+(NSArray<FUBeautyParam *>*)setupSkinData{
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
    
    NSMutableArray *array = [[NSMutableArray alloc] init];

    for (NSString *str in prams) {

        FUBeautyParam *modle = [[FUBeautyParam alloc] init];
        modle.mParam = str;
        modle.mTitle = [titelDic valueForKey:str];
        modle.mValue = [[defaultValueDic valueForKey:str] floatValue];
        modle.defaultValue = modle.mValue;
        modle.type = FUDataTypeBeautify;
        [array addObject:modle];
        
    }
    
    return array;
    
}

+(NSArray<FUBeautyParam *>*)setupShapData{
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
    
   
   NSMutableArray *array = [[NSMutableArray alloc] init];
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
       modle.type = FUDataTypeBeautify;
       [array addObject:modle];
   }
    
    return array;
}

+(NSArray<FUBeautyParam *>*)setupSticker{
   NSArray *prams = @[@"makeup_noitem",@"sdlu",@"DaisyPig",@"fashi",@"xueqiu_lm_fu",@"wobushi",@"gaoshiqing"];//,@"chri1"

   
   NSMutableArray *array = [[NSMutableArray alloc] init];
   for (NSString *str in prams) {
       FUBeautyParam *modle = [[FUBeautyParam alloc] init];
       modle.mParam = str;
//       modle.mTitle = str;
      modle.type = FUDataTypeStrick;
       [array addObject:modle];
       
   }
    
    return array;
}

+(NSArray<FUBeautyParam *>*)setupMakeupData{
//   NSArray *prams = @[@"makeup_noitem",@"jianling",@"nuandong",@"hongfeng",@"Rose",@"shaonv",@"ziyun",@"yanshimao",@"renyu",@"chuqiu",@"qianzhihe",@"chaomo",@"chuju",@"gangfeng",@"xinggan",@"tianmei",@"linjia",@"oumei",@"wumei"];
//    NSDictionary *titelDic = @{@"makeup_noitem":@"卸妆",@"jianling":@"减龄",@"nuandong":@"暖冬",@"hongfeng":@"红枫",@"Rose":@"玫瑰",@"shaonv":@"少女",@"ziyun":@"紫韵",@"yanshimao":@"厌世猫",@"renyu":@"人鱼",@"chuqiu":@"初秋",@"qianzhihe":@"千纸鹤",@"chaomo":@"超模",@"chuju":@"雏菊",@"gangfeng":@"港风",@"xinggan":@"性感",@"tianmei":@"甜美",@"linjia":@"邻家",@"oumei":@"欧美",@"wumei":@"妩媚"};
    NSArray *prams = @[@"makeup_noitem",@"chaoA",@"dousha",@"naicha"];
    NSDictionary *titelDic = @{@"makeup_noitem":@"卸妆",@"naicha":@"奶茶",@"dousha":@"豆沙",@"chaoA":@"超A"};
    
   NSMutableArray *array = [[NSMutableArray alloc] init];
   for (NSString *str in prams) {
       FUBeautyParam *modle = [[FUBeautyParam alloc] init];
       modle.mParam = str;
       modle.mTitle = [titelDic valueForKey:str];
       modle.type = FUDataTypeMakeup;
       modle.mValue = 0.7;
       [array addObject:modle];
   }
    
    return array;
}

+(NSArray<FUBeautyParam *>*)setupBodyData{
   NSArray *prams = @[@"BodySlimStrength",@"LegSlimStrength",@"WaistSlimStrength",@"ShoulderSlimStrength",@"HipSlimStrength",@"HeadSlim",@"LegSlim"];
    NSDictionary *titelDic = @{@"BodySlimStrength":@"瘦身",@"LegSlimStrength":@"长腿",@"WaistSlimStrength":@"细腰",@"ShoulderSlimStrength":@"美肩",@"HipSlimStrength":@"美臀",@"HeadSlim":@"小头",@"LegSlim":@"瘦腿"
    };
   NSDictionary *defaultValueDic = @{@"BodySlimStrength":@(0),@"LegSlimStrength":@(0),@"WaistSlimStrength":@(0),@"ShoulderSlimStrength":@(0.5),@"HipSlimStrength":@(0),@"HeadSlim":@(0),@"LegSlim":@(0)
   };
   
   NSMutableArray *array = [[NSMutableArray alloc] init];
   for (NSString *str in prams) {
       BOOL isStyle101 = NO;
       if ([str isEqualToString:@"ShoulderSlimStrength"]) {
           isStyle101 = YES;
       }
       
       FUBeautyParam *modle = [[FUBeautyParam alloc] init];
       modle.mParam = str;
       modle.mTitle = [titelDic valueForKey:str];
       modle.mValue = [[defaultValueDic valueForKey:str] floatValue];
       modle.defaultValue = modle.mValue;
       modle.iSStyle101 = isStyle101;
       modle.type = FUDataTypebody;
       [array addObject:modle];
   }
    
    return array;
}


@end
