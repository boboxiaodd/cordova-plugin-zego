//
//  FUDemoBar.m
//  FUAPIDemoBar
//
//  Created by L on 2018/6/26.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUAPIDemoBar.h"
#import "FUFilterView.h"
#import "FUSlider.h"
#import "FUBeautyView.h"
#import "FUManager.h"
#import "FUBeautyParam.h"
#import "FUDateHandle.h"


@interface FUAPIDemoBar ()<FUFilterViewDelegate, FUBeautyViewDelegate>


//@property (weak, nonatomic) IBOutlet UIButton *skinBtn;
@property (weak, nonatomic) IBOutlet UIButton *shapeBtn;
@property (weak, nonatomic) IBOutlet UIButton *beautyFilterBtn;

//@property (weak, nonatomic) IBOutlet UIButton *stickerBtn;
//@property (weak, nonatomic) IBOutlet UIButton *makeupBtn;
//@property (weak, nonatomic) IBOutlet UIButton *bodyBtn;

// 上半部分
@property (weak, nonatomic) IBOutlet UIView *topView;
// 滤镜页
@property (weak, nonatomic) IBOutlet FUFilterView *stickerView;
// 美颜滤镜页
@property (weak, nonatomic) IBOutlet FUFilterView *beautyFilterView;
@property (weak, nonatomic) IBOutlet FUFilterView *makeupView;

@property (weak, nonatomic) IBOutlet FUSlider *beautySlider;
@property (weak, nonatomic) IBOutlet FUBeautyView *bodyView;
// 美型页
@property (weak, nonatomic) IBOutlet FUBeautyView *shapeView;
// 美肤页
@property (weak, nonatomic) IBOutlet FUBeautyView *skinView;

/* 当前选中参数 */
@property (strong, nonatomic) FUBeautyParam *seletedParam;

@property (nonatomic, assign) NSInteger selectedIndex ;


/* 滤镜参数 */
@property (nonatomic, strong) NSArray<FUBeautyParam *> *filtersParams;
/* 美肤参数 */
@property (nonatomic, strong) NSArray<FUBeautyParam *> *skinParams;
/* 美型参数 */
@property (nonatomic, strong) NSArray<FUBeautyParam *> *shapeParams;

@property (nonatomic, strong) NSArray<FUBeautyParam *> *stickerParams;
@property (nonatomic, strong) NSArray<FUBeautyParam *> *makeupParams;
@property (nonatomic, strong) NSArray<FUBeautyParam *> *bodyParams;
@end

@implementation FUAPIDemoBar

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {self.backgroundColor = [UIColor clearColor];
        
        self.backgroundColor = [UIColor clearColor];
        NSBundle *bundle = [NSBundle bundleForClass:[FUAPIDemoBar class]];
        self = (FUAPIDemoBar *)[bundle loadNibNamed:@"FUAPIDemoBar" owner:self options:nil].firstObject;
        self.frame = frame;
    }
    return self ;
}


-(void)awakeFromNib {
    [super awakeFromNib];
    [self setupDate];
    
    [self reloadShapView:_shapeParams];
    [self reloadSkinView:_skinParams];
    [self reloadFilterView:_filtersParams];

    self.beautyFilterView.mDelegate = self ;
    self.shapeView.mDelegate = self ;
    self.skinView.mDelegate = self;
    
    [self.skinBtn setTitle:NSLocalizedString(@"美肤", nil) forState:UIControlStateNormal];
    [self.shapeBtn setTitle:NSLocalizedString(@"美型", nil) forState:UIControlStateNormal];
    [self.beautyFilterBtn setTitle:NSLocalizedString(@"滤镜", nil) forState:UIControlStateNormal];
    
    self.skinBtn.tag = 101;
    self.shapeBtn.tag = 102;
    self.beautyFilterBtn.tag = 103 ;
    
}

-(void)setupDate{
    NSMutableArray *tempFilterArray = [[FUDateHandle setupFilterData] mutableCopy];
    self.selectedIndex = 0;
    for(int i=0;i<tempFilterArray.count;i++){
        FUBeautyParam *item  = tempFilterArray[i];
        if([item.mParam isEqualToString: [FURenderKit shareRenderKit].beauty.filterName]){
            self.selectedIndex = i;
            item.mValue = [FURenderKit shareRenderKit].beauty.filterLevel;
        }
        tempFilterArray[i] = item;
        NSLog(@"[CDVLive]setup data %@ = %f",item.mParam,item.mValue);
    }
    
    _filtersParams = tempFilterArray;
    

    NSMutableArray *tempShapeArray = [[FUDateHandle setupShapData] mutableCopy];
    for(int i=0;i<tempShapeArray.count;i++){
        FUBeautyParam *item  = tempShapeArray[i];
        if([item.mParam isEqualToString:@"cheekNarrow"] || [item.mParam isEqualToString:@"cheekSmall"]){
            item.mValue = [[[FURenderKit shareRenderKit].beauty valueForKey:item.mParam] floatValue] * 2;
        }else{
            item.mValue = [[[FURenderKit shareRenderKit].beauty valueForKey:item.mParam] floatValue];
        }
        tempShapeArray[i] = item;
        NSLog(@"[CDVLive]setup data %@ = %f",item.mParam,item.mValue);
    }
    _shapeParams = tempShapeArray;
    
    NSMutableArray *tempSkinArray = [[FUDateHandle setupSkinData] mutableCopy];
    for(int i=0;i<tempSkinArray.count;i++){
        FUBeautyParam *item  = tempSkinArray[i];
        if([item.mParam isEqualToString:@"blurLevel"]){
            item.mValue = [[[FURenderKit shareRenderKit].beauty valueForKey:item.mParam] floatValue] / 6;
        }else{
            item.mValue = [[[FURenderKit shareRenderKit].beauty valueForKey:item.mParam] floatValue];
        }
        tempSkinArray[i] = item;
        NSLog(@"[CDVLive]setup data %@ = %f",item.mParam,item.mValue);
    }
    _skinParams = tempSkinArray;
}

-(void)layoutSubviews{
    [super layoutSubviews];
}

-(void)updateUI:(UIButton *)sender{
    self.skinBtn.selected = NO;
    self.shapeBtn.selected = NO;
    self.beautyFilterBtn.selected = NO;
    
    self.skinView.hidden = YES;
    self.shapeView.hidden = YES ;
    self.beautyFilterView.hidden = YES;
    sender.selected = YES;
    
    if (sender == self.skinBtn) {
        self.skinView.hidden = NO;
    }
    if (sender == self.beautyFilterBtn) {
        self.beautyFilterView.hidden = NO;
    }
    if (sender == self.shapeBtn) {
        self.shapeView.hidden = NO;
    }
}


- (IBAction)bottomBtnsSelected:(UIButton *)sender {
    if (sender.selected) {
//        sender.selected = NO ;
//        [self hiddenTopViewWithAnimation:YES];
        return ;
    }
    [self updateUI:sender];
    
    if (self.shapeBtn.selected) {
        /* 修改当前UI */
        NSInteger selectedIndex = self.shapeView.selectedIndex;
        self.beautySlider.hidden = selectedIndex < 0 ;
        
        if (selectedIndex >= 0) {
            FUBeautyParam *modle = self.shapeView.dataArray[selectedIndex];
            _seletedParam = modle;
            self.beautySlider.value = modle.mValue;
        }
    }
    
    if (self.skinBtn.selected) {
        NSInteger selectedIndex = self.skinView.selectedIndex;
        self.beautySlider.hidden = selectedIndex < 0 ;
        
        if (selectedIndex >= 0) {
            FUBeautyParam *modle = self.skinView.dataArray[selectedIndex];
            _seletedParam = modle;
            self.beautySlider.value = modle.mValue;
        }
    }
    
    // slider 是否显示
    if (self.beautyFilterBtn.selected) {
        NSInteger selectedIndex = self.beautyFilterView.selectedIndex ;
        self.beautySlider.type = FUFilterSliderType01 ;
        self.beautySlider.hidden = selectedIndex <= 0;
        if (selectedIndex >= 0) {
            FUBeautyParam *modle = self.beautyFilterView.filters[selectedIndex];
            _seletedParam = modle;
            self.beautySlider.value = modle.mValue;
        }
    }
    
    [self showTopViewWithAnimation:self.topView.isHidden];
    [self setSliderTyep:_seletedParam];
    
    if ([self.mDelegate respondsToSelector:@selector(bottomDidChange:)]) {
            [self.mDelegate bottomDidChange:sender.tag - 101];
    }
}

-(void)setSliderTyep:(FUBeautyParam *)param{
    if (param.iSStyle101) {
        self.beautySlider.type = FUFilterSliderType101;
    }else{
        self.beautySlider.type = FUFilterSliderType01 ;
    }
}


// 开启上半部分
- (void)showTopViewWithAnimation:(BOOL)animation {
    
    if (animation) {
        self.topView.alpha = 0.0 ;
        self.topView.transform = CGAffineTransformMakeTranslation(0, self.topView.frame.size.height / 2.0) ;
        self.topView.hidden = NO ;
        [UIView animateWithDuration:0.35 animations:^{
            self.topView.transform = CGAffineTransformIdentity ;
            self.topView.alpha = 1.0 ;
        }];
        
        if (self.mDelegate && [self.mDelegate respondsToSelector:@selector(showTopView:)]) {
            [self.mDelegate showTopView:YES];
        }
    }else {
        self.topView.transform = CGAffineTransformIdentity ;
        self.topView.alpha = 1.0 ;
    }
}

// 关闭上半部分
-(void)hiddenTopViewWithAnimation:(BOOL)animation {
    
    if (self.topView.hidden) {
        return ;
    }
    if (animation) {
        self.topView.alpha = 1.0 ;
        self.topView.transform = CGAffineTransformIdentity ;
        self.topView.hidden = NO ;
        [UIView animateWithDuration:0.35 animations:^{
            self.topView.transform = CGAffineTransformMakeTranslation(0, self.topView.frame.size.height / 2.0) ;
            self.topView.alpha = 0.0 ;
        }completion:^(BOOL finished) {
            self.topView.hidden = YES ;
            self.topView.alpha = 1.0 ;
            self.topView.transform = CGAffineTransformIdentity ;
            
            self.skinBtn.selected = NO ;
            self.shapeBtn.selected = NO ;
            self.beautyFilterBtn.selected = NO ;
        }];
        
        if (self.mDelegate && [self.mDelegate respondsToSelector:@selector(showTopView:)]) {
            [self.mDelegate showTopView:NO];
        }
    }else {
        
        self.topView.hidden = YES ;
        self.topView.alpha = 1.0 ;
        self.topView.transform = CGAffineTransformIdentity ;
    }
}


- (UIViewController *)viewControllerFromView:(UIView *)view {
    for (UIView *next = [view superview]; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}


#pragma mark ---- FUFilterViewDelegate
// 开启滤镜
-(void)filterViewDidSelectedFilter:(FUBeautyParam *)param{
    _seletedParam = param;
    self.beautySlider.hidden = YES;

    if(param.type == FUDataTypeFilter && _beautyFilterView.selectedIndex > 0){
        self.beautySlider.value = param.mValue;
        self.beautySlider.hidden = NO;
    }
    
//    if(param.type == FUDataTypeMakeup&& _makeupView.selectedIndex > 0){
//                self.beautySlider.value = param.mValue;
//        self.beautySlider.hidden = NO;
//    }
//
//    if(param.type == FUDataTypebody&& _bodyView.selectedIndex > 0){
//        self.beautySlider.value = param.mValue;
//        self.beautySlider.hidden = NO;
//    }

     [self setSliderTyep:_seletedParam];
    
    if (_mDelegate && [_mDelegate respondsToSelector:@selector(filterValueChange:)]) {
        [_mDelegate filterValueChange:_seletedParam];
    }
}

-(void)beautyCollectionView:(FUBeautyView *)beautyView didSelectedParam:(FUBeautyParam *)param{
    _seletedParam = param;
    self.beautySlider.value = param.mValue;
    self.beautySlider.hidden = NO;
    
     [self setSliderTyep:_seletedParam];
}


// 滑条滑动
- (IBAction)filterSliderValueChange:(FUSlider *)sender {
    _seletedParam.mValue = sender.value;
    if (_mDelegate && [_mDelegate respondsToSelector:@selector(filterValueChange:)]) {
        [_mDelegate filterValueChange:_seletedParam];
    }
}

- (IBAction)isOpenFURender:(UISwitch *)sender {
    
    if (_mDelegate && [_mDelegate respondsToSelector:@selector(switchRenderState:)]) {
        [_mDelegate switchRenderState:sender.on];
    }
}

-(void)reloadSkinView:(NSArray<FUBeautyParam *> *)skinParams{
    if([skinParams[1].mParam isEqualToString:@"colorLevel"]){
        NSLog(@"[CDVLive] reloadSkinView colorLevel = %f",skinParams[1].mValue);
    }
    _skinView.dataArray = skinParams;
    _skinView.selectedIndex = 0;
    FUBeautyParam *modle = skinParams[0];
    if (modle) {
        _beautySlider.hidden = NO;
        _beautySlider.value = modle.mValue;
    }
    [_skinView reloadData];
}

-(void)reloadShapView:(NSArray<FUBeautyParam *> *)shapParams{
    _shapeView.dataArray = shapParams;
    _shapeView.selectedIndex = 1;
    [_shapeView reloadData];
}

-(void)reloadFilterView:(NSArray<FUBeautyParam *> *)filterParams{
    _beautyFilterView.selectedIndex = self.selectedIndex;
    _beautyFilterView.filters = filterParams;
    [_beautyFilterView reloadData];
}

-(void)setDefaultFilter:(FUBeautyParam *)filter{
    [self.beautyFilterView setDefaultFilter:filter];
}

-(BOOL)isTopViewShow {
    return !self.topView.hidden ;
}



@end
