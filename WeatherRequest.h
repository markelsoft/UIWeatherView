//
//  WeatherRequest.h
//
// Use to hold parameters for retrying a showWeatherForCurrentAddress API call
// when waiting on current address
//
//  Copyright (c) 2015 MarkelSoft, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface WeatherRequest : NSObject {
    
}

@property (nonatomic) CGRect frame;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) UIViewController * parent;
@property (nonatomic, assign) BOOL allowSharing;
@property (nonatomic, assign) BOOL allowClosing;
@property (nonatomic, assign) BOOL verbose;

- (id)initWithData:(CGRect)lFrame title:(NSString *)lTitle parent:(UIViewController *)lParent
      allowSharing:(BOOL)lAllowSharing allowClosing:(BOOL)lAllowClosing verbose:(BOOL)lVerbose;

@end
