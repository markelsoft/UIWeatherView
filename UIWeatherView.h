//
//  UIWeatheView.h
//
//  Created by Tom Markel on 02/24/2015.
//
//  Copyright (c) 2015 MarkelSoft, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JSON.h"
#import "MDHTMLLabel.h"
#import "LocationUtils.h"
#import "WeatherRequest.h"

@interface UIWeatherView : UIView <MDHTMLLabelDelegate, UIScrollViewDelegate, LocationUtilsDelegate> {
    
    UIScrollView * scrollView;
    MDHTMLLabel * weatherLabel;
    NSString * htmlText;
    NSString * weatherForecastUrl;
    
    UILabel * label;
    UILabel * labelAddress;
    UIButton * closeButton;
    UIButton * shareButton;
    UIButton * weatherButton;
    UIImageView * iconImageView;
    
    NSString * address;
    NSString * currentAddress;
    NSString * currentCityStateAddress;
    NSString * currentHeading;
    int currentHeadingAccuracy;

    UIViewController * parent;
    
    NSMutableDictionary * current_observation;
    NSString * weatherSunrise;
    NSString * weatherSunset;
    NSString * weatherPercentIlluminated;
    NSString * weatherAgeOfMoon;

    BOOL isNewAddress;
    BOOL gettingAddress;
}

// start of API...

// initialize weather service using your Wunderground API Key
//
// NSString * apiKey - weather PAI key (e.g. Wunderground Weather API Key ID)
// id<LocationUtilsDelegate> locationDelegate - location delegate to notify of address changes if monitoring is on
// BOOL verbose - turn verbose mode on/off
+ (void)initializeWeatherService:(NSString *)apiKey locationDelegate:(id<LocationUtilsDelegate>)locationDelegate verbose:(BOOL)verbose;

// show weather for an address
//
// NSString * address - location address to get weather for
// CGRect frame - weather view frame
// NSString title - title for weather view
// UIViewController * parent - parent to add weather view to
// BOOL allowSharing - if true adds sharing button to view
// BOOL allowClosing - if true adds close button to view
// BOOL verbose - turn verbose mode on/off
//
// return UIWeatherView * - created weather view
+ (UIWeatherView *)showWeatherForAddress:(NSString *)address frame:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose;

// show weather for current address
//
// NSString * address - location address to get weather for
// CGRect frame - weather view frame
// NSString title - title for weather view
// UIViewController * parent - parent to add weather view to
// BOOL allowSharing - if true adds sharing button to view
// BOOL allowClosing - if true adds close button to view
// BOOL waitForAddress, if true wait for current address to be found (location monitoring should be ON for this to work)
// BOOL verbose - turn verbose mode on/off
//
// return UIWeatherView * - created weather view
+ (UIWeatherView *)showWeatherForCurrentAddress:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing waitForAddress:(BOOL)waitForAddress verbose:(BOOL)verbose;

// show weather for an latitude and longitude coordinate
//
// NSString * address - location address to get weather for
// CGRect frame - weather view frame
// NSString title - title for weather view
// UIViewController * parent - parent to add weather view to
// BOOL allowSharing - if true adds sharing button to view
// BOOL allowClosing - if true adds close button to view
// BOOL verbose - turn verbose mode on/off
//
// return UIWeatherView * - created weather view
+ (UIWeatherView *)showWeatherForCoordinate:(CLLocationCoordinate2D)coordinate frame:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose;

// get the Weather for a location address
//
// NSString * address - location address to get weather for
// BOOL verbose - turn verbose mode on/off
//
// return NSMutableDictionary - dictionary of weather items
//        (see #weatherItems in UIWeatherView or use helper API e.g. getLocationWeather)
+ (NSMutableDictionary *)getLocationWeather:(NSString *)address verbose:(BOOL)verbose;

// get the temperature for a location address
//
// NSString * address - location address to get temperature for
// BOOL verbose - turn verbose mode on/off
//
// return NSString * - the temperature fahrenheit (centigrade)
+ (NSString *)getLocationTemperature:(NSString *)address verbose:(BOOL)verbose;


// get the Sunrise and Sunset times for a location address
// (also includes Moon illumination and Moon age)
//
// NSString * address - location address to get sunrise and sunset for
// BOOL verbose - turn verbose mode on/off
//
// return NSMutableDictionary - dictionary with sunrise time     "sunrise"
//                                              sunset time      "sunset"
//                               also contains moon illumination  "percentIlluminated"
//                                             moon age           "ageOfMoon"
+ (NSMutableDictionary *)getLocationSunriseSunset:(NSString *)address verbose:(BOOL)verbose;

// get the Sunrise time for a location address
//
// NSString * address - location address to get Sunrise time for
// BOOL verbose - turn verbose mode on/off
//
// return NSString * - sunrise time
+ (NSString *)getLocationSunrise:(NSString *)address verbose:(BOOL)verbose;

// get the Sunset time for a location address
//
// NSString * address - location address to get Sunset time for
// BOOL verbose - turn verbose mode on/off
//
// return NSString * - sunset time
+ (NSString *)getLocationSunset:(NSString *)address verbose:(BOOL)verbose;

// get the Moon Illimination for a location address
//
// NSString * address - location address to get Moon Illumination for
// BOOL verbose - turn verbose mode on/off
//
// return NSString * - moon illumination
+ (NSString *)getLocationMoonIllumination:(NSString *)address verbose:(BOOL)verbose;

// get the Moon Age for a location address
//
// NSString * address - location addressto get Moon age for
// BOOL verbose - turn verbose mode on/off
//
// return NSString * - moon age
+ (NSString *)getLocationMoonAge:(NSString *)address verbose:(BOOL)verbose;

//  set whether monitoring of your location is on or off.  On by default.
//  Note: if you want UIWeatherView to automatically get your current address
//  ,which is needed for getWeatherForCurrentAddress, you should leave this on
+ (void)setLocationMonitoring:(BOOL)monitorLocation;

// set the location delegate to call when monitoring in on
+ (void)setLocationDelegate:(id<LocationUtilsDelegate>)locationDelegate;

// get the location delegate to call when monitoring in on
//
// return (id<LocationUtilsDelegate>) locationDelegate
+ (id<LocationUtilsDelegate>)getLocationDelegate;

// get the address for a coordinate
//
// return NSString * - the address
+ (NSString *)getAddressForCoordinate:(CLLocationCoordinate2D)coordinate verbose:(BOOL)verbose;

// get the coordinate for an address
//
// NSString * address - the address to validate and expand
// BOOL verbose - turn verbose mode on or off
//
// return CLLocationCoordinate2D coordinate - the coordinate
+ (CLLocationCoordinate2D)getAddressCoordinate:(NSString *)address verbose:(BOOL)verbose;

// get the full address for an address
//
// NSString * address - the address to validate and expand
// BOOL formatted - whether to return unformatted or formatted (with LFs) address
// BOOL verbose - turn verbose mode on or off
//
// return NSString * - the address
+ (NSString *)getFullAddressForAddress:(NSString *)address formatted:(BOOL)formatted verbose:(BOOL)verbose;

// get the current address
//
// return NSString * - current address
+ (NSString *)getCurrentAddress;

// get the current cityState address
//
// return NSString * - current cityState address
+ (NSString *)getCurrentCityStateAddress;

// get the current heading
//
// return NSString * - current heading
+ (NSString *)getCurrentHeading;

// get the current heading accuracy
//
// return int - current heading accuracy
+ (int)getCurrentHeadingAccuracy;

// start of helper APIs

// get the location weather
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location weather (e.g. conditions: cloundy etc...)
+ (NSString *)getLocationWeatherFromDict:(NSMutableDictionary *)weatherDict;

// get the location temperature
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location temperature
+ (NSString *)getLocationTemperatureFromDict:(NSMutableDictionary *)weatherDict;

// get the location temperature in fahrenheit
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location temperature in fahrenheit
+ (NSString *)getLocationTemperatureFahrenheitFromDict:(NSMutableDictionary *)weatherDict;

// get the location temperature in centigrade
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location temperature in centigrade
+ (NSString *)getLocationTemperatureCentigradeFromDict:(NSMutableDictionary *)weatherDict;

// get the location relative humidity
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location relaive humidity
+ (NSString *)getLocationRelativeHumidityFromDict:(NSMutableDictionary *)weatherDict;

// get the location wind
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind
+ (NSString *)getLocationWindFromDict:(NSMutableDictionary *)weatherDict;

// get the location wind degrees
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind degrees
+ (NSString *)getLocationWindDegreesFromDict:(NSMutableDictionary *)weatherDict;

// get the location wind mph
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind mph
+ (NSString *)getLocationWindMphFromDict:(NSMutableDictionary *)weatherDict;

// get the location wind gust mph
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind gust mph
+ (NSString *)getLocationWindGustMphFromDict:(NSMutableDictionary *)weatherDict;

// get the location wind kph
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind kph
+ (NSString *)getLocationWindKphFromDict:(NSMutableDictionary *)weatherDict;

// get the location wind gust kph
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind gust kph
+ (NSString *)getLocationWindGustKphFromDict:(NSMutableDictionary *)weatherDict;

// get the location pressure in mb
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location pressure in Mb
+ (NSString *)getLocationPressureMbFromDict:(NSMutableDictionary *)weatherDict;

// get the location pressure in inches
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location pressure in inches
+ (NSString *)getLocationPressureInchesFromDict:(NSMutableDictionary *)weatherDict;

// get the location pressure trend
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location pressure trend
+ (NSString *)getLocationPressureTrendFromDict:(NSMutableDictionary *)weatherDict;

// get the location dewpoint
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location dewpoint
+ (NSString *)getLocationDewpointFromDict:(NSMutableDictionary *)weatherDict;

// get the location dewpoint in fahrenheit
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location dewpoint in fahrenheit
+ (NSString *)getLocationDewpointFahrenheitFromDict:(NSMutableDictionary *)weatherDict;

// get the location dewpoint in centigrade
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location dewpoint in centigrade
+ (NSString *)getLocationDewpointCentigradeFromDict:(NSMutableDictionary *)weatherDict;

// get the location heat index
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location heat index
+ (NSString *)getLocationHeatIndexFromDict:(NSMutableDictionary *)weatherDict;

// get the location heat index n fahrenheit
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location heat index in fahrenheit
+ (NSString *)getLocationHeatIndexFahrenheitFromDict:(NSMutableDictionary *)weatherDict;

// get the location heat index n centigrade
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location heat index in centigrade
+ (NSString *)getLocationHeatIndexCentigradeFromDict:(NSMutableDictionary *)weatherDict;

// get the location windchill
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location windchill
+ (NSString *)getLocationWindchillFromDict:(NSMutableDictionary *)weatherDict;

// get the location windchill in fahrenheit
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location windchill in fahrenheit
+ (NSString *)getLocationWindchillFahrenheitFromDict:(NSMutableDictionary *)weatherDict;

// get the location windchill in centigrade
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location windchill in centigrade
+ (NSString *)getLocationWindchillCentigradeFromDict:(NSMutableDictionary *)weatherDict;

// get the location feels like temperature
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location feels like temperature
+ (NSString *)getLocationFeelslikeFromDict:(NSMutableDictionary *)weatherDict;

// get the location feels like temperature in fahrenheit
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location feels like temperature in fahrenheit
+ (NSString *)getLocationFeelslikeFahrenheitFromDict:(NSMutableDictionary *)weatherDict;

// get the location feels like temperature in centigrade
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location feels like temperature in fahrenheit
+ (NSString *)getLocationFeelslikeCentigradeFromDict:(NSMutableDictionary *)weatherDict;

// get the location visibility in miles
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location visibility in miles
+ (NSString *)getLocationVisibilityMilesFromDict:(NSMutableDictionary *)weatherDict;

// get the location visibility in Km
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location visibility in Km
+ (NSString *)getLocationVisibilityKmFromDict:(NSMutableDictionary *)weatherDict;

// get the location solar radiation
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location solar radiation
+ (NSString *)getLocationSolarRadiationFromDict:(NSMutableDictionary *)weatherDict;

// get the location UV
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location UV
+ (NSString *)getLocationUVFromDict:(NSMutableDictionary *)weatherDict;

// get the location pricipitation in last 1 hour
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation in last 1 hours
+ (NSString *)getLocationPrecipitation1HrFromDict:(NSMutableDictionary *)weatherDict;

// get the location pricipitation in last 1 hour in inches
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation in last 1 hours in inches
+ (NSString *)getLocationPrecipitation1HrInchesFromDict:(NSMutableDictionary *)weatherDict;

// get the location pricipitation in last 1 hour in metric
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation in last 1 hours in metric
+ (NSString *)getLocationPrecipitation1HrMetricFromDict:(NSMutableDictionary *)weatherDict;

// get the location pricipitation today
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation today
+ (NSString *)getLocationPrecipitationTodayFromDict:(NSMutableDictionary *)weatherDict;

// get the location pricipitation today in inches
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation today in inches
+ (NSString *)getLocationPrecipitationTodayInchesFromDict:(NSMutableDictionary *)weatherDict;

// get the location pricipitation today metric
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation today metric
+ (NSString *)getLocationPrecipitationTodayMetricFromDict:(NSMutableDictionary *)weatherDict;

// get the location icon
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location icon
+ (NSString *)getLocationIconFromDict:(NSMutableDictionary *)weatherDict;

// get the location icon url
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location icon url
+ (NSString *)getLocationIconUrlFromDict:(NSMutableDictionary *)weatherDict;

// get the location forecast url
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location forecast url
+ (NSString *)getLocationForecastUrlFromDict:(NSMutableDictionary *)weatherDict;

// get the location history url
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location history url
+ (NSString *)getLocationHistoryUrlFromDict:(NSMutableDictionary *)weatherDict;

// get the location observation url
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location observation url
+ (NSString *)getLocationObservationUrlFromDict:(NSMutableDictionary *)weatherDict;

// get the location sunrise
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationSunriseSunset API
//
// return NSString * - location sunrise
+ (NSString *)getLocationSunriseFromDict:(NSMutableDictionary *)sunriseSunsetDict;

// get the location sunset
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationSunriseSunset API
//
// return NSString * - location sunset
+ (NSString *)getLocationSunsetFromDict:(NSMutableDictionary *)sunriseSunsetDict;

// get the location moon percent illuminated
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationSunriseSunset API
//
// return NSString * - location moon percent illuminated
+ (NSString *)getLocationMoonPercentIllumnatedFromDict:(NSMutableDictionary *)sunriseSunsetDict;

// get the location moon age
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationSunriseSunset API
//
// return NSString * - location moon age
+ (NSString *)getLocationMoonAgeFromDict:(NSMutableDictionary *)sunriseSunsetDict;

// end of helper APIs

// end of API

// start of Weather View constructors   (use showWeatherFor… APIs which will automatically create Weather Views.  only
//                                       use constructor if wan full control)

// create the UIWeatherView
//
// CGRect frame - frame for the UIWeatherView
// NSString * title - title for UIWeatherView
// NSMutableDictionary * _weather - weather for the location
// NSString * sunrise - sunrise time
// NSString * sunset - sunset time
// NSString * percentIlluminated - moon illumination
// NSString * ageOfMoon - age of Moon
// UIViewController * _parent - parent view controller
// BOOL allowSharing - allow sharing of detail
// BOOL allowClosing - allow closing the view
// BOOL verbose - turn verbose mode on/off
- (id)initWithFrame:(CGRect)frame title:(NSString *)title weather:(NSMutableDictionary *)weather sunrise:(NSString *)sunrise sunset:(NSString *)sunset percentIlluminated:(NSString *)percentIlluminated ageOfMoon:(NSString *)ageOfMoon parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose;

// end of Weather View constructors

// start of Weather View instance methods

// set the title
//
// NSString * title - the new title
- (void)setTitle:(NSString *)title;

// set the address and optionally refresh weather details...
//
// NSString * address - the new address
// NSString * displayAddress - the new address to display at top of weather view.  if nil, uses address
// BOOL refreshDetails -if TRUE, refresh address weather details also
// BOOL verbose - turn verbose mode on/off
- (void)setAddress:(NSString *)address displayAddress:(NSString *)displayAddress refreshDetails:(BOOL)refreshDetails verbose:(BOOL)verbose;

// Show the weather forecast for the current weather
//
// can be called after using constructor and will show show Wunderground.com
// weather forecast in your browser for the location you used in constructor
- (void)showWeatherForecast;

// share the weather details
- (void)shareWeather;

// resize weather view
//
// CGRect frame - new frame
- (void)resizeView:(CGRect)frame;

// close the weather view
- (void)closeView;

// see if running on iPad
//
// return BOOL - TRUE if running on iPad
- (BOOL)isRunningIPad;

// end of Weather View instance methods


@end
