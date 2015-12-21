# UIWeatherView
An iOS library for controlling and interacting with Weather Underground API, which gives you access to locatin-specific weather details.

Purpose
--------------

UIWeatherView is class to allow iPad, iPhone and iPod Touch apps to easily add a view for showing weather details.

Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 7.0 ARC / Mac OS 10.8 (Xcode 4.3.1, Apple LLVM compiler 3.1)
* Earliest supported deployment target - iOS 6.0 / Mac OS 10.8
* Earliest compatible deployment target - iOS 6.0 / Mac OS 10.8

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


Installation
--------------

To install UIWeatherView into your app, drag the files in the UIWeatherView folder into your project.    Make sure that you indicate to copy the files into your project.    Also make sure that the Target Membership is checked for all the .m, .png and .jpg images.


The easiest way to create a UIWeatherView is to use the showLocationFor… APIs.  
e.g. [UIWeatherView showWeatherForAddress:];             - shows weather for an city, state address
     [UIWeatherView showWeatherForCurrentAddress: ];     - shows weather for current address you are at
     [UIWeatherView showWeatherForCoordinate: ];         - shows weather for a location latitude and longitude

Required Frameworks and Libraries
---------------------------------

Must include the following frameworks: Foundation, UIKit, CoreFoundation, CoreGraphics, CoreLocation, CoreText, MessageUI, MobileCoreServices, Security and SystemConfiguration.


Usage 
-----

// see Demo Example in Examples/Demo folder for full source code

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect rect = [[UIScreen mainScreen] bounds];
    screenWidth = rect.size.width;
    screenHeight = rect.size.height;

    // UIWeatherView has about 50 APIs for doing weather, address and
    //                                           latitude/longitude related functionality
    //                                           plus location monitoring.
    // Create views and acquire data using APIs
    //
    //
    // Step 1.   Initialize the weather service with your Wundergrounnd API Key
    //
    // initialize weather service using your Wunderground API Key
    //
    // see http://www.wunderground.com/weather/api for Wunderground API setup
    // Once setup you will find key in Key Settings tab
    // Weather API key (e.g. Wunderground Weather API Key ID)
    //
    // Register at Wunderground.com and then replace WUNDERGROUND_WEATHERAPI_KEY above
    // This demo's key uses the free plan which allows a usage of 500 calls per day and 10 calls a minute
    //
    // locationDelegate - is self, since we wan app to receive any location changes.
    //                    see didUpdateToLocation: and currentAddressChanged: callbacks below
    //
    [UIWeatherView initializeWeatherService:WUNDERGROUND_WEATHERAPI_KEY locationDelegate:self verbose:TRUE];
    //[UIWeatherView setLocationMonitoring:TRUE];   // turn location monitoring ON (on by default)
    //[UIWeatherView setLocationMonitoring:FALSE];  // turn location monitor OFF (will effect current address APIs!)
    
    // address format is {city, state}.   One comma separating city and state (2 letter abbrev e.g. NY, CA, VA)
    // some examples:
    //
    // Note: if location monitoring on and you receive currentAddressChanged: and other callbacks, the
    //       current full address and city, state for current address is returned
    //
    //NSString * address = @"Cooperstown, NY 13326";
    //NSString * address = @"7514 Cannon Fort Dr Clifton, VA  20124-2804 United States";
    //NSString * address = @"San Francisco, CA";
    NSString * address = @"Los Angeles, CA";

    
    // Step 2.   Use show APIs to display a weather view containing weather detail for a location
    //
    // 3 example of creating a weather view showing weather details for a location.
    // Show by address, current address and location latitude/longitude.
    //
    int width = screenWidth * .90;
    int height = screenHeight * .80;
    int x = (screenWidth - width) / 2;
    int y = (screenHeight - height) / 2;

    // Example 1:
    // show weather details for the address.   Use City, State for the address  e.g. 'Los Angeles, CA', 'Clifton, VA'
    //
    // title is shown at top of weather view
    // parent is parent view controller to add the weather view to  
    //        if nil will not add to any view just create and sharing is disabled
    // allowSharing adds a share button to share the weather details displayed
    // allowClosing adds a close button to close the view, if required
    //
    // returns UIWeatherView * - created weather view
    UIWeatherView * weatherView1 = [UIWeatherView showWeatherForAddress:address frame:CGRectMake(x, y, width, height) title:@"Weather" parent:self allowSharing:TRUE allowClosing:FALSE verbose:FALSE];
    //[weatherView1 setTitle:@"New Weather"];
    //[weatherView1 setAddress:@"San Francisco, CA" displayAddress:nil refreshDetails:TRUE verbose:FALSE];

    //Example 2:   (uncomment to try out.   Be sure to comment out other examples since uses same area)
    //
    // show weather details for current address and wait for current address to be found...
    //
    // title is shown at top of weather view
    // allowSharing adds a share button to share the weather details displayed
    // allowClosing adds a close button to close the view, if required
    // waitForAddress waits for the current address to be found.
    //                location monitoring must be on for this to work.  By default location monitoring is on.
    //                see above initializeWeatherService and setLocationMonitoring APIs
    //
    // returns UIWeatherView * - created weather view
    /**
    UIWeatherView * weatherView2 = [UIWeatherView showWeatherForCurrentAddress:CGRectMake(x, y, width, height) title:@"Weather Current" parent:self allowSharing:TRUE allowClosing:FALSE waitForAddress:TRUE verbose:FALSE];
     **/
    
    // Example 3: (uncomment to try out.   Be sure to comment out other examples since uses same area)
    //
    // show weather for a coordinate (latitude and longitude) for San Francisco, CA...
    //
    // title is shown at top of weather view
    // allowSharing adds a share button to share the weather details displayed
    // allowClosing adds a close button to close the view, if required
    //
    // returns UIWeatherView * - created weather view
    /**
    CLLocationDegrees lat = 37.7749295;
    CLLocationDegrees lng = -122.4194155;
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lng);
    NSString * weatherTitle = [NSString stringWithFormat:@"Weather for %.2f, %.2f", lat, lng];
    UIWeatherView * weatherView3 = [UIWeatherView showWeatherForCoordinate:coordinate frame:CGRectMake(x, y, width, height) title:weatherTitle parent:self allowSharing:TRUE allowClosing:FALSE verbose:FALSE];
    **/
    
    // Step 3.   Use weather API to get tons of weather details
    //
    // get weather details for use in your own app...
    //
    // get the location weather...
    // all the main details for the weather.  Does not include sunset, sunrise, moon illumination and age of moon.
    NSMutableDictionary * weatherDict = [UIWeatherView getLocationWeather:address verbose:FALSE];
    NSString * weatherCondition = nil;
    NSString * temperature = nil;
    NSString * temp_f = nil;
    NSString * temp_c = nil;
    NSString * relativeHumidity = nil;
    NSString * forecastUrl = nil;
    NSString * historyUrl = nil;

    if (weatherDict != nil) {
        //
        // use helper APIs to get values...
        //
        weatherCondition = [UIWeatherView getLocationWeatherFromDict:weatherDict];
        temperature = [UIWeatherView getLocationTemperatureFromDict:weatherDict];
        temp_f = [UIWeatherView getLocationTemperatureFahrenheitFromDict:weatherDict];
        temp_c = [UIWeatherView getLocationTemperatureCentigradeFromDict:weatherDict];
        relativeHumidity = [UIWeatherView getLocationRelativeHumidityFromDict:weatherDict];
        forecastUrl = [UIWeatherView getLocationForecastUrlFromDict:weatherDict];
        historyUrl = [UIWeatherView getLocationHistoryUrlFromDict:weatherDict];

        NSLog(@"Weather Conditions: %@", weatherCondition);
        NSLog(@"Temperature: %@", temperature);
        NSLog(@"Temperature (fahrenheit): %@", temp_f);
        NSLog(@"Temperature (centigrade): %@", temp_c);
        NSLog(@"Relative Humidity: %@", relativeHumidity);
        NSLog(@"Forecast url: %@", forecastUrl);
        NSLog(@"History url: %@", historyUrl);
    }
    
    NSString * weatherTemperature = [UIWeatherView getLocationTemperature:address verbose:FALSE];
    NSLog(@"Temperature for %@ is %@", address, weatherTemperature);
    
    // get additional information for the location:
    //     sunrise and sunset,
    //     plus moon illumination and age of moon information
    //
    NSMutableDictionary * sunriseSunsetDict = [UIWeatherView getLocationSunriseSunset:address verbose:FALSE];
    NSString * weatherSunrise = nil;
    NSString * weatherSunset = nil;
    NSString * weatherPercentIlluminated = nil;
    NSString * weatherAgeOfMoon = nil;

    if (sunriseSunsetDict != nil) {
        //
        // use helper APIs to get values...
        //
        weatherSunrise = [UIWeatherView getLocationSunriseFromDict:sunriseSunsetDict];
        weatherSunset = [UIWeatherView getLocationSunsetFromDict:sunriseSunsetDict];
        weatherPercentIlluminated = [UIWeatherView getLocationMoonPercentIllumnatedFromDict:sunriseSunsetDict];
        weatherAgeOfMoon = [UIWeatherView getLocationMoonAgeFromDict:sunriseSunsetDict];
        
        NSLog(@"Sunrise time: %@", weatherSunrise);
        NSLog(@"Sunset time: %@", weatherSunset);
        NSLog(@"Moon percent illuminated: %@", weatherPercentIlluminated);
        NSLog(@"Age of moon: %@", weatherAgeOfMoon);
    }    
}

// Location address changed…
//
// if a locationDelegate is set on initializeWeatherService API call and location monitoring is on (by default is on)
//
// called if location monitoring is on
//
// provides: new current address, old address (if any) and city/state for new address (useful for showWeatherFor… APIs…
//
- (void)currentAddressChanged:(CLLocation *)currentLocation currentAddress:(NSString *)_currentAddress oldAddress:(NSString *)oldAddress cityState:(NSString *)cityState {
    
    if (_currentAddress != nil && _currentAddress.length > 0) {
        NSLog(@"Your address changed to '%@'.   City, State address is: '%@'.", _currentAddress, cityState);
    }
}

// creating Weather Views:  the best way to create a UIWeatherView is to use the showWeatherFor… APIs.     
//                          If you want total control you can use UIWindowsView constructor but it is 
//                          recommended to use showWeatherFor… APIs as make it much easier.
// showWeatherFor… APIs:
/
+ (void)showWeatherForAddress:(NSString *)address frame:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose;

+ (void)showWeatherForCurrentAddress:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing waitForAddress:(BOOL)waitForAddress verbose:(BOOL)verbose;

+ (void)showWeatherForCoordinate:(CLLocationCoordinate2D)coordinate frame:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose;
// end of showWeatherFor… Apis
//

// Register at Wunderground.com and then replace WUNDERGROUND_WEATHERAPI_KEY above
// This demo's key uses the free plan which allows a usage of 500 calls per day and 10 calls a minute
#define WUNDERGROUND_WEATHERAPI_KEY @"c1bab46d564bdb9a"

    [UIWeatherView initializeWeatherService:WUNDERGROUND_WEATHERAPI_KEY locationDelegate:self verbose:TRUE];
    
    // address format is {city, state}.   One comma separating city and state...
    // some examples:
    //
    int width = screenWidth * .90;
    int height = screenHeight * .80;
    int x = (screenWidth - width) / 2;
    int y = (screenHeight - height) / 2;
    [UIWeatherView showWeatherForAddress:@“Los Angeles, CA” frame:CGRectMake(x, y, width, height) title:@"Weather" parent:self allowSharing:TRUE allowClosing:FALSE verbose:FALSE];
    
    /**    show weather for your current address…
    [UIWeatherView showWeatherForCurrentAddress:CGRectMake(x, y, width, height) title:@"Weather Current" parent:self allowSharing:TRUE allowClosing:FALSE waitForAddress:TRUE verbose:FALSE];
    **/
      
    /**   show weather for a location at specified latitude/longitude…
    CLLocationDegrees lat = 37.7749295;
    CLLocationDegrees lng = -122.4194155;
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lng);
    NSString * weatherTitle = [NSString stringWithFormat:@"Weather for %.2f, %.2f", lat, lng];
    [UIWeatherView showWeatherForCoordinate:coordinate frame:CGRectMake(x, y, width, height) title:weatherTitle parent:self allowSharing:TRUE allowClosing:FALSE verbose:FALSE];
    **/


// Methods:

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
+ (void)showWeatherForAddress:(NSString *)address frame:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose;

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
+ (void)showWeatherForCurrentAddress:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing waitForAddress:(BOOL)waitForAddress verbose:(BOOL)verbose;

// show weather for an latitude and longitude coordinate
//
// NSString * address - location address to get weather for
// CGRect frame - weather view frame
// NSString title - title for weather view
// UIViewController * parent - parent to add weather view to
// BOOL allowSharing - if true adds sharing button to view
// BOOL allowClosing - if true adds close button to view
// BOOL verbose - turn verbose mode on/off
+ (void)showWeatherForCoordinate:(CLLocationCoordinate2D)coordinate frame:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose;

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
//                                       use constructor if want full control)
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
- (id)initWithFrame:(CGRect)frame title:(NSString *)title weather:(NSMutableDictionary *)_weather sunrise:(NSString *)sunrise sunset:(NSString *)sunset percentIlluminated:(NSString *)percentIlluminated ageOfMoon:(NSString *)ageOfMoon parent:(UIViewController *)_parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose;

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
- (void)setAddress:(NSString *)address refreshDetails:(BOOL)refreshDetails verbose:(BOOL)verbose;

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


Example Project Demo
---------------------

The demo example in the Examples/Demo folder demonstrates how you might implement using UIWeatherView.   

When pressed, the app displays a list of videos you have uploaded to Facebook.   

The example is for iOS.
