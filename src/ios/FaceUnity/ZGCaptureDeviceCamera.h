//
//  ZGCaptureDeviceCamera.h
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/1/12.
//  Copyright © 2020 Zego. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "ZGCaptureDeviceProtocol.h"


@interface ZGCaptureDeviceCamera : NSObject <ZGCaptureDevice>

@property (nonatomic, weak) id<ZGCaptureDeviceDataOutputPixelBufferDelegate> delegate;

- (instancetype)initWithPixelFormatType:(OSType)pixelFormatType;

@end

