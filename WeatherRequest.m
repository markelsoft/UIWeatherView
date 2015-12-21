//
//  WeatherRequest.m
//
// Used to hold parameters for retrying a showWeatherForCurrentAddress API call
// when waiting on current address
//
//  Copyright (c) 2015 MarkelSoft, Inc. All rights reserved.
//

#import "WeatherRequest.h"

@implementation WeatherRequest

@synthesize frame;
@synthesize title;
@synthesize parent;
@synthesize allowSharing;
@synthesize allowClosing;
@synthesize verbose;

- (id)initWithData:(CGRect)lFrame title:(NSString *)lTitle parent:(UIViewController *)lParent
            allowSharing:(BOOL)lAllowSharing allowClosing:(BOOL)lAllowClosing verbose:(BOOL)lVerbose {
    self = [super init];
    if (self) {
        frame = lFrame;
        title = lTitle;
        parent = lParent;
        allowSharing = lAllowSharing;
        allowClosing = lAllowClosing;
        verbose = lVerbose;
    }
    
    return self;
}
@end
