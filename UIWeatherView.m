//
//  UIWeatherView.m
//
//  Created by Tom Markel on 02/24/2015.
//
//  Copyright (c) 2015 MarkelSoft, Inc. All rights reserved.
//

#import "UIWeatherView.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

// see http://www.wunderground.com/weather/api for Wunderground API setup
// Once setup you will find key in Key Setttings tab
// Weather API key (e.g. Wunderground Weather API Key ID)
static NSString * weatherAPIKey = @"";

// location utilities
static LocationUtils * locationUtils = nil;
static id<LocationUtilsDelegate> locationDelegate = nil;

static CLGeocoder * geocoder = nil;

// weather view just for trackng current address
static UIWeatherView * addressWeatherView = nil;

// whether to monitor location of not.  By default this is turn on
// use UIWeatherView setLocationMonitoring to turn on or off
static BOOL monitorLocation = TRUE;

//
// for Weather dictionary items see #weatherItems below
//
// for Weather sunrise/sunset dictionary see #sunriseSunsetItems below
//

@implementation UIWeatherView

// Start of Weather APIS
//
//

// initialize weather service using your Wunderground API Key
//
// see http://www.wunderground.com/weather/api for Wunderground API setup
// Once setup you will find key in Key Setttings tab
// Weather API key (e.g. Wunderground Weather API Key ID)
//
// NSString * apiKey - Wundeground API Key ID
// id<LocationUtilsDelegate>) delegate - delegage to notify of location changes, if monitoring is on
//
+ (void)initializeWeatherService:(NSString *)apiKey locationDelegate:(id<LocationUtilsDelegate>)_locationDelegate verbose:(BOOL)verbose {
    
    weatherAPIKey = apiKey;
    locationDelegate = _locationDelegate;
    
    if (verbose)
        NSLog(@"Initialized Weather Service using the Weather API Key '%@'", weatherAPIKey);
    
    addressWeatherView = [[UIWeatherView alloc] init];   // Weather View used for receiving address changes
    geocoder = [[CLGeocoder alloc] init];                // geocoder latitude and longitude to address

    if (monitorLocation) {
        locationUtils = [[LocationUtils alloc] init];
        [locationUtils setLocationDelegate:addressWeatherView];
        
        if (verbose) {
            NSLog(@"Monitoring of current location address is enabled.");
        }
    }
}

// show weather for an address
+ (UIWeatherView *)showWeatherForAddress:(NSString *)address frame:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose {
    
    if (address == nil || address.length == 0) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Show Weather Notice" message:@"Please specifiy a valid address to show weather for!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        
        return nil;
    }

    if (verbose)
        NSLog(@"showing weather for the address: '%@'", address);

    NSString * weatherSunrise = nil;
    NSString * weatherSunset = nil;
    NSString * weatherPercentIlluminated = nil;
    NSString * weatherAgeOfMoon = nil;

    // get the location weather...
    // all the main details for the weather.  Does not include sunset, sunrise, moon illumination and age of moon.
    NSMutableDictionary * weatherDict = [UIWeatherView getLocationWeather:address verbose:verbose];
    
    if (weatherDict != nil && weatherDict.count == 1) {
        NSString * _msg = [NSString stringWithFormat:@"Your address\n'%@'\nis not formatted correctly!\n\nMake sure the address has\nCity, State in it!   e.g. Cooperstown, NY and use 2 letter state abbreviation.", address];
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Show Weather Notice" message:_msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        
        return nil;
    }
    
    NSString * weatherTemperature = [UIWeatherView getLocationTemperature:address verbose:verbose];
    if (verbose) {
        NSLog(@"Temperature for %@ is %@", address, weatherTemperature);
    }
    
    // get additional information for the location:
    //     sunrise, sunset, moon illumination and aget of moon information...
    NSMutableDictionary * sunriseSunsetDict = [UIWeatherView getLocationSunriseSunset:address verbose:verbose];
    
    if (sunriseSunsetDict != nil) {
        weatherSunrise = [sunriseSunsetDict valueForKey:@"sunrise"];
        weatherSunset = [sunriseSunsetDict valueForKey:@"sunset"];
        weatherPercentIlluminated = [sunriseSunsetDict valueForKey:@"percentIlluminated"];
        weatherAgeOfMoon = [sunriseSunsetDict valueForKey:@"ageOfMoon"];
        
        if (verbose) {
            NSLog(@"Sunrise time: %@", weatherSunrise);
            NSLog(@"Sunset time: %@", weatherSunset);
            NSLog(@"Moon percent illuminated: %@", weatherPercentIlluminated);
            NSLog(@"Age of moon: %@", weatherAgeOfMoon);
        }
    }

    // create a weather view wih all weather details plus sunrise, sunset, percent illumination and age of of moon
    // and include share and close buttons...
    UIWeatherView * weatherView = [[UIWeatherView alloc] initWithFrame:frame title:title weather:weatherDict sunrise:weatherSunrise sunset:weatherSunset percentIlluminated:weatherPercentIlluminated ageOfMoon:weatherAgeOfMoon parent:parent allowSharing:allowSharing allowClosing:allowClosing verbose:verbose];
    
    if (parent != nil)
        [parent.view addSubview:weatherView];
    
    return weatherView;
}

// show weather for current address address
// optional wait
+ (UIWeatherView *)showWeatherForCurrentAddress:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing waitForAddress:(BOOL)waitForAddress verbose:(BOOL)verbose {
    
    //NSString * _currentAddress = [UIWeatherView getCurrentAddress];
    NSString * _currentAddress = [UIWeatherView getCurrentCityStateAddress];
    
    if (_currentAddress == nil || _currentAddress.length == 0) {
        if (waitForAddress) {
            //NSLog(@"Don't have current address so creating thread to wait then retry...");
            WeatherRequest * weatherRequest = [[WeatherRequest alloc] initWithData:frame title:title parent:parent allowSharing:allowSharing allowClosing:allowClosing verbose:verbose];
            
            [NSThread detachNewThreadSelector:@selector(showWeatherForCurrentAddressThread:) toTarget:self withObject:weatherRequest];

            return nil;
            
        } else {
           UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Show Weather Notice" message:@"Your current address is not known yet so can show associated weather!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
           [alert show];
        
           return nil;
        }
    }
    
    if (verbose)
        NSLog(@"showing weather for the current address: '%@'", _currentAddress);
    
    NSString * weatherSunrise = nil;
    NSString * weatherSunset = nil;
    NSString * weatherPercentIlluminated = nil;
    NSString * weatherAgeOfMoon = nil;
    
    // get the location weather...
    // all the main details for the weather.  Does not include sunset, sunrise, moon illumination and age of moon.
    NSMutableDictionary * weatherDict = [UIWeatherView getLocationWeather:_currentAddress verbose:verbose];
    
    if (weatherDict != nil) {
        // replace cityState address with full address...
        NSString * _currentAddress = [UIWeatherView getCurrentAddress];
        [weatherDict setObject:_currentAddress forKey:@"address"];
    }
    
    NSString * weatherTemperature = [UIWeatherView getLocationTemperature:_currentAddress verbose:verbose];
    if (verbose)
        NSLog(@"Temperature for %@ is %@", _currentAddress, weatherTemperature);
    
    // get additional information for the location:
    //     sunrise, sunset, moon illumination and aget of moon information...
    NSMutableDictionary * sunriseSunsetDict = [UIWeatherView getLocationSunriseSunset:_currentAddress verbose:verbose];
    
    if (sunriseSunsetDict != nil) {
        weatherSunrise = [sunriseSunsetDict valueForKey:@"sunrise"];
        weatherSunset = [sunriseSunsetDict valueForKey:@"sunset"];
        weatherPercentIlluminated = [sunriseSunsetDict valueForKey:@"percentIlluminated"];
        weatherAgeOfMoon = [sunriseSunsetDict valueForKey:@"ageOfMoon"];
        
        NSLog(@"Sunrise time: %@", weatherSunrise);
        NSLog(@"Sunset time: %@", weatherSunset);
        NSLog(@"Moon percent illuminated: %@", weatherPercentIlluminated);
        NSLog(@"Age of moon: %@", weatherAgeOfMoon);
    }
    
    // create a weather view wih all weather details plus sunrise, sunset, percent illumination and age of of moon
    // and include share and close buttons...
    UIWeatherView * weatherView = [[UIWeatherView alloc] initWithFrame:frame title:title weather:weatherDict sunrise:weatherSunrise sunset:weatherSunset percentIlluminated:weatherPercentIlluminated ageOfMoon:weatherAgeOfMoon parent:parent allowSharing:allowSharing allowClosing:allowClosing verbose:verbose];
    
    if (parent != nil)
        [parent.view addSubview:weatherView];
    
    return weatherView;
}

// show weather for an latitude and longitude coordinate
+ (UIWeatherView *)showWeatherForCoordinate:(CLLocationCoordinate2D)coordinate frame:(CGRect)frame title:(NSString *)title parent:(UIViewController *)parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose {
    
    if (coordinate.latitude == 0.0 || coordinate.longitude == 0.0) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Show Weather Notice" message:@"Please specify a valid coordinate to show the weather for!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        
        return nil;
    }

    if (verbose)
        NSLog(@"showing weather for the coordinate: %f, %f", coordinate.latitude, coordinate.longitude);
    
    NSString * weatherSunrise = nil;
    NSString * weatherSunset = nil;
    NSString * weatherPercentIlluminated = nil;
    NSString * weatherAgeOfMoon = nil;
    
    NSString * _coordinateAddress = [UIWeatherView getAddressForCoordinate:coordinate verbose:verbose];
    if (verbose)
        NSLog(@"---> found address to be '%@'", _coordinateAddress);
    
    // get the location weather...
    // all the main details for the weather.  Does not include sunset, sunrise, moon illumination and age of moon.
    NSMutableDictionary * weatherDict = [UIWeatherView getLocationWeather:_coordinateAddress verbose:verbose];
    
    NSString * weatherTemperature = [UIWeatherView getLocationTemperature:_coordinateAddress verbose:verbose];
    if (verbose)
        NSLog(@"Temperature for %@ is %@", _coordinateAddress, weatherTemperature);
    
    // get additional information for the location:
    //     sunrise, sunset, moon illumination and aget of moon information...
    NSMutableDictionary * sunriseSunsetDict = [UIWeatherView getLocationSunriseSunset:_coordinateAddress verbose:verbose];
    
    if (sunriseSunsetDict != nil) {
        weatherSunrise = [sunriseSunsetDict valueForKey:@"sunrise"];
        weatherSunset = [sunriseSunsetDict valueForKey:@"sunset"];
        weatherPercentIlluminated = [sunriseSunsetDict valueForKey:@"percentIlluminated"];
        weatherAgeOfMoon = [sunriseSunsetDict valueForKey:@"ageOfMoon"];
        
        if (verbose) {
            NSLog(@"Sunrise time: %@", weatherSunrise);
            NSLog(@"Sunset time: %@", weatherSunset);
            NSLog(@"Moon percent illuminated: %@", weatherPercentIlluminated);
            NSLog(@"Age of moon: %@", weatherAgeOfMoon);
        }
    }
    
    // create a weather view wih all weather details plus sunrise, sunset, percent illumination and age of of moon
    // and include share and close buttons...
    UIWeatherView * weatherView = [[UIWeatherView alloc] initWithFrame:frame title:title weather:weatherDict sunrise:weatherSunrise sunset:weatherSunset percentIlluminated:weatherPercentIlluminated ageOfMoon:weatherAgeOfMoon parent:parent allowSharing:allowSharing allowClosing:allowClosing verbose:verbose];
    
    if (parent != nil)
        [parent.view addSubview:weatherView];
    
    return weatherView;
}

+ (void)showWeatherForCurrentAddress:(WeatherRequest *)weatherRequest {
    
    if (weatherRequest != nil) {
        //NSString * _currentAddress = [UIWeatherView getCurrentCityStateAddress];
        //NSLog(@"processing weather request: %@.   Trying again using curren address of %@...", weatherRequest, _currentAddress);
        [UIWeatherView showWeatherForCurrentAddress:weatherRequest.frame title:weatherRequest.title parent:weatherRequest.parent allowSharing:weatherRequest.allowSharing allowClosing:weatherRequest.allowClosing waitForAddress:FALSE verbose:weatherRequest.verbose];
        
    } else {
        NSLog(@"nil weather reaquest!");
    }
}

+ (void)showWeatherForCurrentAddressThread:(WeatherRequest *)weatherRequest {
    
    if (weatherRequest.verbose)
        NSLog(@"in thread to wait for current address then retry...");
    
    // wait for current address
    NSString * _currentCityStateAddress = [UIWeatherView getCurrentCityStateAddress];
    
    while (_currentCityStateAddress == nil) {
        //if (weatherRequest.vrbose)
        //    NSLog(@"waiting for current address...");
        [NSThread sleepForTimeInterval:1];
        _currentCityStateAddress = [UIWeatherView getCurrentCityStateAddress];
    }
    
    //if (weatherRequest.verbose)
        NSLog(@"got current cityState address of %@", _currentCityStateAddress);
    // self == addressWeatherView ??
    [self performSelectorOnMainThread:@selector(showWeatherForCurrentAddress:) withObject:weatherRequest waitUntilDone:YES];
}

- (NSString *)getCurrentAddress {
    
    return currentAddress;
}

// get the current address
//
// return NSString * - current address
+ (NSString *)getCurrentAddress {
    NSString * _currentAddress = nil;
    
    if (addressWeatherView != nil) {
        _currentAddress = [addressWeatherView getCurrentAddress];
        //NSLog(@"current address is %@", _currentAddress);
        
        if (_currentAddress != nil)
            _currentAddress = [_currentAddress copy];
    }
    
    return _currentAddress;
}

- (NSString *)getCurrentCityStateAddress {
    
    return currentCityStateAddress;
}

// get the current cityState address
//
// return NSString * - current cityState address
+ (NSString *)getCurrentCityStateAddress {
    NSString * _currentCityStateAddress = nil;
    
    if (addressWeatherView != nil) {
        _currentCityStateAddress = [addressWeatherView getCurrentCityStateAddress];
        //NSLog(@"current cityState address is %@", _currentCityStateAddress);
        
        if (_currentCityStateAddress != nil)
            _currentCityStateAddress = [_currentCityStateAddress copy];
    }
    
    return _currentCityStateAddress;
}

- (NSString *)getCurrentHeading {
    
    return currentHeading;
}

// get the current heading
//
// return NSString * - current heading
+ (NSString *)getCurrentHeading {
    NSString * _currentHeading = nil;
    
    if (addressWeatherView != nil) {
        _currentHeading = [addressWeatherView getCurrentHeading];
        //NSLog(@"current heading is %@", _currentCityStateAddress);
        
        if (_currentHeading != nil)
            _currentHeading = [_currentHeading copy];
    }
    
    return _currentHeading;
}

- (int)getCurrentHeadingAccuracy {
    
    return currentHeadingAccuracy;
}

// get the current heading accuracy
//
// return int - current heading accuracy
+ (int)getCurrentHeadingAccuracy {
    int _currentHeadingAccuracy = 0;
    
    if (addressWeatherView != nil) {
        _currentHeadingAccuracy = [addressWeatherView getCurrentHeadingAccuracy];
        //NSLog(@"current heading accuracy is %d", _currentHeadingAccuracy);
    }
    
    return _currentHeadingAccuracy;
}

// get the Weather for a location address
//
// NSString * _address - location address
// BOOL verbose - turn verbose mode on/off
//
// return NSMutableDictionary - dictionary of weather items (see #weatherItems below)
//
+ (NSMutableDictionary *)getLocationWeather:(NSString *)_address verbose:(BOOL)verbose {
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    
    if (verbose)
        NSLog(@"getting temperature for the address %@", _address);
    
    //[self showFreeMemory:@"getLocation Weather start"];
    
    @try {
        NSString * address = _address;
        BOOL verbose2 = FALSE;
        
        if (address != nil)
            address = [address stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        else {
            if (address == nil) {
                address = [UIWeatherView getCurrentAddress];
            }

            if (address == nil) {
                NSLog(@"The address specified is nil!");
                return nil;
            }
        }
        
        //_address = [UIWeatherView formatAddress:_address];
        //_address = [_address stringByReplacingOccurrencesOfString:@"United States" withString:@""];
        
        if (verbose || verbose2)
            NSLog(@"IN adress is '%@'", address);
        
        NSArray * comps = [address componentsSeparatedByString:@", "];
        
        if (verbose || verbose2)
            NSLog(@"comps count is %lu", (unsigned long)comps.count);
        
        if (comps.count > 2) {
            NSString * newAddress = [NSString stringWithFormat:@"%@, %@", [comps objectAtIndex:0], [comps objectAtIndex:1]];
            
            if (verbose || verbose2)
                NSLog(@"using new address '%@'", newAddress);
            
            comps = [newAddress componentsSeparatedByString:@", "];
            
        } else {
            NSArray * words = [address componentsSeparatedByString:@" "];
            NSString * part1 = @""; // use everything else as start
            NSString * part2 = [words objectAtIndex:words.count-1];  // use last word as part 2 (e.g. Spain)
            
            for (int i = 0; i < words.count-1; i++) {
                part1 = [part1 stringByAppendingFormat:@"%@", [words objectAtIndex:i]];
                
                if (i < words.count-2)
                    part1 = [part1 stringByAppendingString:@" "];
            }
            
            //NSLog(@"part1: '%@' part2: %@'", part1, part2);
            
            NSString * newAddress = [NSString stringWithFormat:@"%@, %@", part1, part2];
            
            if (verbose || verbose2)
                NSLog(@"using new address '%@'", newAddress);
            
            comps = [newAddress componentsSeparatedByString:@", "];
        }
        
        NSString * cityPart = [comps objectAtIndex:0];
        NSString * statePart = [comps objectAtIndex:1];
        
        if (verbose || verbose2) {
            NSLog(@"address is '%@'", address);
            NSLog(@"statePart is '%@'", statePart);
            NSLog(@"cityPart is '%@'", cityPart);
        }
        
        // state
        NSArray * statePartComps = [statePart componentsSeparatedByString:@" "];
        NSString * state = nil;
        
        // if state has more than one words then add underscore...
        if (statePartComps.count == 2)
            state = [statePart stringByReplacingOccurrencesOfString:@" " withString:@"_"]; // %20
        else
            state = [statePartComps objectAtIndex:0];
        
        // city
        NSArray * cityPartComps = [cityPart componentsSeparatedByString:@" "];
        NSString * city = nil;
        
        // if city has more than one words then add underscore...
        if (cityPartComps.count == 2) {
            city = [cityPart stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        } else
            city = [cityPartComps objectAtIndex:cityPartComps.count-1];
        
        if (verbose || verbose2) {
            NSLog(@"state is '%@'", state);
            NSLog(@"city is '%@'", city);
        }
        
        NSString * urlStr = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/conditions/q/%@/%@.json", weatherAPIKey, state, city];
        if (verbose || verbose2)
            NSLog(@"urlStr '%@'", urlStr);
        
        NSURL * url = [NSURL URLWithString:urlStr];
        NSURLResponse * response;
        NSError * error;
        NSURLRequest * request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:90.0];
        NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        //if (data != nil)
        //	NSLog(@"network data was returned.");
        //else
        //	NSLog(@"network data is nil!");
        
        if (error != nil) {
            //NSLog(@"network description: %@", error.localizedDescription);
            //NSLog(@"network error: %@", error.localizedFailureReason);
            //NSLog(@"recovery suggestion: %@", error.localizedRecoverySuggestion);
        }
        
        if (data != nil) {
            NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            if (verbose)
                NSLog(@"temp data %@", dataStr);
            
            SBJSON * parser = [[SBJSON alloc] init];
            NSDictionary * jsonObjects = [parser objectWithString:dataStr error:nil];
            
            if (verbose)
                NSLog(@"JSONObjects %@", jsonObjects);
            
            NSDictionary * current_observation = [jsonObjects valueForKey:@"current_observation"];
            
            // weather items
            //
            // #weatherItems
            NSString * _weather = [current_observation valueForKey:@"weather"];
            NSString * temperature_string = [current_observation valueForKey:@"temperature_string"];
            NSString * temp_f = [current_observation valueForKey:@"temp_f"];
            NSString * temp_c = [current_observation valueForKey:@"temp_c"];
            NSString * relativeHumidity = [current_observation valueForKey:@"relative_humidity"];
            
            NSString * wind = [current_observation valueForKey:@"wind_string"];
            NSString * wind_dir = [current_observation valueForKey:@"wind_dir"];
            NSString * wind_degrees = [current_observation valueForKey:@"wind_degrees"];
            NSString * wind_mph = [current_observation valueForKey:@"wind_mph"];
            NSString * wind_gust_mph = [current_observation valueForKey:@"wind_gust_mph"];
            NSString * wind_kph = [current_observation valueForKey:@"wind_kph"];
            NSString * wind_gust_kph = [current_observation valueForKey:@"wind_gust_kph"];
            NSString * pressure_mb = [current_observation valueForKey:@"pressure_mb"];
            NSString * pressure_in = [current_observation valueForKey:@"pressure_in"];
            NSString * pressure_trend = [current_observation valueForKey:@"pressure_trend"];
            NSString * dewpoint_string = [current_observation valueForKey:@"dewpoint_string"];
            NSString * dewpoint_f = [current_observation valueForKey:@"dewpoint_f"];
            NSString * dewpoint_c = [current_observation valueForKey:@"dewpoint_c"];
            NSString * heat_index_string = [current_observation valueForKey:@"heat_index_string"];
            NSString * heat_index_f = [current_observation valueForKey:@"heat_index_f"];
            NSString * heat_index_c = [current_observation valueForKey:@"heat_index_c"];
            NSString * windchill_string = [current_observation valueForKey:@"windchill_string"];
            NSString * windchill_f = [current_observation valueForKey:@"windchill_f"];
            NSString * windchill_c = [current_observation valueForKey:@"windchill_c"];
            NSString * feelslike_string = [current_observation valueForKey:@"feelslike_string"];
            NSString * feelslike_f = [current_observation valueForKey:@"feelslike_f"];
            NSString * feelslike_c = [current_observation valueForKey:@"feelslike_c"];
            NSString * visibility_mi = [current_observation valueForKey:@"visibility_mi"];
            NSString * visibility_km = [current_observation valueForKey:@"visibility_km"];
            NSString * solarRadiation = [current_observation valueForKey:@"solar_radiation"];
            NSString * uv = [current_observation valueForKey:@"UV"];
            NSString * precip_1hr_string = [current_observation valueForKey:@"precip_1hr_string"];
            NSString * precip_1hr_in = [current_observation valueForKey:@"precip_1hr_in"];
            NSString * precip_1hr_metric = [current_observation valueForKey:@"precip_1hr_metric"];
            NSString * precip_today_string = [current_observation valueForKey:@"precip_today_string"];
            NSString * precip_today_in = [current_observation valueForKey:@"precip_today_in"];
            NSString * precip_today_metric = [current_observation valueForKey:@"precip_today_metric"];
            NSString * icon = [current_observation valueForKey:@"icon"];
            NSString * icon_url = [current_observation valueForKey:@"icon_url"];
            NSString * forecast_url = [current_observation valueForKey:@"forecast_url"];
            NSString * history_url = [current_observation valueForKey:@"history_url"];
            NSString * ob_url = [current_observation valueForKey:@"ob_url"];
            
            [dict setObject:address forKey:@"address"];
             
            if (_weather != nil) {
                if (verbose)
                    NSLog(@"found weather of %@", _weather);
                [dict setObject:_weather forKey:@"weather"];
            }
            
            if (temperature_string != nil) {
                if (verbose)
                    NSLog(@"found temperature_string of %@", temperature_string);
                [dict setObject:temperature_string forKey:@"temperature_string"];
            }
            
            if (temp_f != nil) {
                if (verbose)
                    NSLog(@"found temp_f of %@", temp_f);
                [dict setObject:temp_f forKey:@"temp_f"];
            }
            
            if (temp_c != nil) {
                if (verbose)
                    NSLog(@"found temp_c of %@", temp_c);
                [dict setObject:temp_c forKey:@"temp_c"];
            }
            
            if (relativeHumidity != nil) {
                if (verbose)
                    NSLog(@"found relative_humidity of %@", relativeHumidity);
                [dict setObject:relativeHumidity forKey:@"relative_humidity"];
            }
            
            if (wind != nil) {
                if (verbose)
                    NSLog(@"found wind %@", wind);
                [dict setObject:wind forKey:@"wind"];
            }
            
            if (wind_dir!= nil) {
                if (verbose)
                    NSLog(@"found win_dir %@", wind_dir);
                [dict setObject:wind_dir forKey:@"wind_dir"];
            }
            
            if (wind_degrees != nil) {
                if (verbose)
                    NSLog(@"found wind_degrees %@", wind_degrees);
                [dict setObject:wind_degrees forKey:@"wind_degrees"];
            }
            
            if (wind_mph != nil) {
                if (verbose)
                    NSLog(@"found wind_mph %@", wind_mph);
                [dict setObject:wind_mph forKey:@"wind_mph"];
            }
            
            if (wind_gust_mph != nil) {
                if (verbose)
                    NSLog(@"found wind_gust_mph %@", wind_gust_mph);
                [dict setObject:wind_gust_mph forKey:@"wind_gust_mph"];
            }
            
            if (wind_kph != nil) {
                if (verbose)
                    NSLog(@"found wind_kph %@", wind_kph);
                [dict setObject:wind_kph forKey:@"wind_kph"];
            }
            
            if (wind_gust_kph != nil) {
                if (verbose)
                    NSLog(@"found wind_gust_kph %@", wind_gust_kph);
                [dict setObject:wind_gust_kph forKey:@"wind_gust_kph"];
            }
            
            if (pressure_mb != nil) {
                if (verbose)
                    NSLog(@"found pressure_mb %@", pressure_mb);
                [dict setObject:pressure_mb forKey:@"pressure_mb"];
            }
            
            if (pressure_in != nil) {
                if (verbose)
                    NSLog(@"found presure_in %@", pressure_in);
                [dict setObject:pressure_in forKey:@"pressure_in"];
            }
            
            if (pressure_trend != nil) {
                if (verbose)
                    NSLog(@"found wpresure_trend %@", pressure_trend);
                [dict setObject:pressure_trend forKey:@"presure_trend"];
            }
            
            if (dewpoint_string != nil) {
                if (verbose)
                    NSLog(@"found dewpoint_string %@", dewpoint_string);
                [dict setObject:dewpoint_string forKey:@"dewpoint_string"];
            }
            
            if (dewpoint_f != nil) {
                if (verbose)
                    NSLog(@"found dewpoint_f %@", dewpoint_f);
                [dict setObject:dewpoint_f forKey:@"dewpoint_f"];
            }
            
            if (dewpoint_c != nil) {
                if (verbose)
                    NSLog(@"found dewpoint_c %@", dewpoint_c);
                [dict setObject:dewpoint_c forKey:@"dewpoint_c"];
            }
            
            if (heat_index_string != nil) {
                if (verbose)
                    NSLog(@"found heat_index_string %@", heat_index_string);
                [dict setObject:heat_index_string forKey:@"heat_index_string"];
            }
            
            if (heat_index_f != nil) {
                if (verbose)
                    NSLog(@"found heat_index_f %@", heat_index_f);
                [dict setObject:heat_index_f forKey:@"heat_index_f"];
            }
            
            if (heat_index_c != nil) {
                if (verbose)
                    NSLog(@"found heat_index_c %@", heat_index_c);
                [dict setObject:heat_index_c forKey:@"heat_index_c"];
            }
            
            if (windchill_string != nil) {
                if (verbose)
                    NSLog(@"found windchill_string %@", windchill_string);
                [dict setObject:windchill_string forKey:@"windchill_string"];
            }
            
            if (windchill_f != nil) {
                if (verbose)
                    NSLog(@"found windchill_f %@", windchill_f);
                [dict setObject:windchill_f forKey:@"windchill_f"];
            }
            
            if (windchill_c != nil) {
                if (verbose)
                    NSLog(@"found windchill_c %@", windchill_c);
                [dict setObject:windchill_c forKey:@"windchill_c"];
            }
            
            if (feelslike_string != nil) {
                if (verbose)
                    NSLog(@"found feelslike_string %@", feelslike_string);
                [dict setObject:feelslike_string forKey:@"feelslike_string"];
            }
            
            if (feelslike_f != nil) {
                if (verbose)
                    NSLog(@"found feelslike_f %@", feelslike_f);
                [dict setObject:feelslike_f forKey:@"feelslike_f"];
            }
            
            if (feelslike_c != nil) {
                if (verbose)
                    NSLog(@"found feelslike_c %@", feelslike_c);
                [dict setObject:feelslike_c forKey:@"feelslike_c"];
            }
            
            if (visibility_mi != nil) {
                if (verbose)
                    NSLog(@"found visibility_mi %@", visibility_mi);
                [dict setObject:visibility_mi forKey:@"visibility_mi"];
            }
            
            if (visibility_km != nil) {
                if (verbose)
                    NSLog(@"found visibility_km %@", visibility_km);
                [dict setObject:visibility_km forKey:@"visibility_km"];
            }
            
            if (solarRadiation != nil) {
                if (verbose)
                    NSLog(@"found colar_radiation %@", solarRadiation);
                [dict setObject:solarRadiation forKey:@"solar_radiation"];
            }
            
            if (uv != nil) {
                if (verbose)
                    NSLog(@"found UV %@", uv);
                [dict setObject:uv forKey:@"uv"];
            }
            
            if (precip_1hr_string != nil) {
                if (verbose)
                    NSLog(@"found recip_1hr_string %@", precip_1hr_string);
                [dict setObject:precip_1hr_string forKey:@"precip_1hr_string"];
            }
            
            if (precip_1hr_in != nil) {
                if (verbose)
                    NSLog(@"found precip_1hr_in %@", precip_1hr_in);
                [dict setObject:precip_1hr_in forKey:@"precip_1hr_in"];
            }
            
            if (precip_1hr_metric != nil) {
                if (verbose)
                    NSLog(@"found precip_1hr_metric %@", precip_1hr_metric);
                [dict setObject:precip_1hr_metric forKey:@"precip_1hr_metric"];
            }
            
            if (precip_today_string != nil) {
                if (verbose)
                    NSLog(@"found precip_today_string %@", precip_today_string);
                [dict setObject:precip_today_string forKey:@"precip_today_string"];
            }
            
            if (precip_today_in != nil) {
                if (verbose)
                    NSLog(@"found precip_today_in %@", precip_today_in);
                [dict setObject:precip_today_in forKey:@"precip_today_in"];
            }
            
            if (precip_today_metric != nil) {
                if (verbose)
                    NSLog(@"found precip_today_metric %@", precip_today_metric);
                [dict setObject:precip_today_metric forKey:@"precip_today_metric"];
            }
            
            if (icon != nil) {
                if (verbose)
                    NSLog(@"found icon %@", icon);
                [dict setObject:icon forKey:@"icon"];
            }
            
            if (icon_url != nil) {
                if (verbose)
                    NSLog(@"found icon_url %@", icon_url);
                [dict setObject:icon_url forKey:@"icon_url"];
            }
            
            if (forecast_url != nil) {
                if (verbose)
                    NSLog(@"found forecast_url %@", forecast_url);
                [dict setObject:forecast_url forKey:@"forecast_url"];
            }
            
            if (history_url != nil) {
                if (verbose)
                    NSLog(@"found history_url %@", history_url);
                [dict setObject:history_url forKey:@"history_url"];
            }
            
            if (ob_url != nil) {
                if (verbose)
                    NSLog(@"found ob_url %@", ob_url);
                [dict setObject:ob_url forKey:@"ob_url"];
            }
            
            //[parser release];
            
        }
        
        //NSLog(@"[getWeather] urlStr %@", urlStr);
    }
    @catch (NSException * ex) {
        NSLog(@"[getWeather] error: %@", [ex description]);
    }
    
    //[self showFreeMemory:@"getLocation Weather end"];
    
    return dict;
}

// get the temperature for a location address
//
// NSString * _address - location address
// BOOL verbose - turn verbose mode on/off
//
// return NSString * - the temperature fahrenheit (centigrade)
//
+ (NSString *)getLocationTemperature:(NSString *)_address verbose:(BOOL)verbose {
    NSString * temperature = nil;
    
    if (verbose)
        NSLog(@"getting temperature for the address %@", _address);
    
    @try {
        NSString * address = _address;
        
        if (address != nil)
            address = [address stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        else {
            if (address == nil) {
                address = [UIWeatherView getCurrentAddress];
            }
            
            if (address == nil) {
                NSLog(@"The address specified is nil!");
                return nil;
            }
        }
        
        //_address = [UIWeatherView formatAddress:_address];
        //_address = [_address stringByReplacingOccurrencesOfString:@"United States" withString:@""];
        
        NSArray * comps = [address componentsSeparatedByString:@", "];
        NSString * part1 = [comps objectAtIndex:1];
        
        if (comps.count == 3)
            part1 = [comps objectAtIndex:2];
        
        NSString * part2 = [comps objectAtIndex:0];
        
        //NSLog(@"part1 is '%@'", part1);
        //NSLog(@"part2 is '%@'", part2);
        
        NSArray * part1Comps = [part1 componentsSeparatedByString:@" "];
        NSString * state = nil;
        
        if (part1Comps.count == 2) {
            state = part1;
            state = [state stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        } else
            state = [part1Comps objectAtIndex:0];
        
        NSArray * part2Comps = [part2 componentsSeparatedByString:@" "];
        NSString * city = nil;
        
        if (part2Comps.count == 2) {
            city = part2;
            city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        } else
            city = [part2Comps objectAtIndex:part2Comps.count-1];
        
        //city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        
        NSString * urlStr = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/conditions/q/%@/%@.json", weatherAPIKey, state, city];
        //NSLog(@"urlStr '%@'", urlStr);
        
        NSURL * url = [NSURL URLWithString:urlStr];
        NSURLResponse * response;
        NSError * error;
        NSURLRequest * request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:90.0];
        NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        //if (data != nil)
        //	NSLog(@"network data was returned.");
        //else
        //	NSLog(@"network data is nil!");
        
        if (error != nil) {
            //NSLog(@"network description: %@", error.localizedDescription);
            //NSLog(@"network error: %@", error.localizedFailureReason);
            //NSLog(@"recovery suggestion: %@", error.localizedRecoverySuggestion);
        }
        
        if (data != nil) {
            NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            //NSLog(@"temp data %@", dataStr);
            
            SBJSON * parser = [[SBJSON alloc] init];
            NSDictionary * jsonObjects = [parser objectWithString:dataStr error:nil];
            if (verbose)
                NSLog(@"JSONObjects %@", jsonObjects);
            NSDictionary * current_observation = [jsonObjects valueForKey:@"current_observation"];
            
            // weather sunrise, sunset and more items
            //
            // #sunriseSunsetItems
            NSString * _weather = [current_observation valueForKey:@"weather"];
            NSString * temperature_string = [current_observation valueForKey:@"temperature_string"];
            NSString * temp_f = [current_observation valueForKey:@"temp_f"];
            NSString * temp_c = [current_observation valueForKey:@"temp_c"];
            NSString * relativeHumidity = [current_observation valueForKey:@"relative_humidity"];
            
            if (temperature_string != nil && temperature_string.length > 0) {
                temperature = temperature_string;
                
                if (verbose) {
                    NSLog(@"Weather %@", _weather);
                    NSLog(@"-- temp '%@'", temperature);
                    NSLog(@"-- temp_f '%@'", temp_f);
                    NSLog(@"-- temp_c '%@'", temp_c);
                    NSLog(@"-- relative humidity '%@'", relativeHumidity);
                }
            }
            
            //[parser release];
        }
        
        //NSLog(@"[getLocationTemperature] urlStr %@", urlStr);
        
    }
    @catch (NSException * ex) {
        NSLog(@"[getLocationTemperaure] error: %@", [ex description]);
    }
    
    return temperature;
}

// get the Sunrise and Sunset times for a location address
// (also includes Moon illumination and Moon age)
//
// NSString * _address - location address
// BOOL verbose - turn verbose mode on/off
//
// return NSMutableDictionary - dictionary with sunrise time     "sunrise"
//                                               sunset time      "sunset"
//                               also contains moon illumination  "percentIlluminated"
//                                             moon age           "ageOfMoon"
//
+ (NSMutableDictionary *)getLocationSunriseSunset:(NSString *)_address verbose:(BOOL)verbose {
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    
    if (verbose)
        NSLog(@"getting sunrise for the address %@", _address);
    
    @try {
        
        if (_address != nil)
            _address = [_address stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        else {
            if (_address == nil) {
                _address = [UIWeatherView getCurrentAddress];
            }
            
            if (_address == nil) {
                NSLog(@"The address specified is nil!");
                return nil;
            }
        }
        
        //_address = [UIWeatherView formatAddress:_address];
        //_address = [_address stringByReplacingOccurrencesOfString:@"United States" withString:@""];
        
        NSArray * comps = [_address componentsSeparatedByString:@", "];
        NSString * part1 = [comps objectAtIndex:1];
        
        if (comps.count == 3)
            part1 = [comps objectAtIndex:2];
        
        NSString * part2 = [comps objectAtIndex:0];
        
        //NSLog(@"part1 is '%@'", part1);
        //NSLog(@"part2 is '%@'", part2);
        
        NSArray * part1Comps = [part1 componentsSeparatedByString:@" "];
        NSString * state = nil;
        
        if (part1Comps.count == 2) {
            state = part1;
            state = [state stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        } else
            state = [part1Comps objectAtIndex:0];
        
        NSArray * part2Comps = [part2 componentsSeparatedByString:@" "];
        NSString * city = nil;
        
        //NSLog(@"part2Comps %@", part2Comps);
        //NSLog(@"part2Count %d", part2Comps.count);
        
        if (part2Comps.count == 2) {
            city = part2;
            city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        } else
            city = [part2Comps objectAtIndex:part2Comps.count-1];
        
        //NSLog(@"city %@", city);
        //city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        
        NSString * urlStr = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/astronomy/q/%@/%@.json", weatherAPIKey, state, city];
        if (verbose)
            NSLog(@"urlStr '%@'", urlStr);
        
        NSURL * url = [NSURL URLWithString:urlStr];
        NSURLResponse * response;
        NSError * error;
        NSURLRequest * request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:90.0];
        NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        //if (data != nil)
        //	NSLog(@"network data was returned.");
        //else
        //	NSLog(@"network data is nil!");
        
        if (error != nil) {
            //NSLog(@"network description: %@", error.localizedDescription);
            //NSLog(@"network error: %@", error.localizedFailureReason);
            //NSLog(@"recovery suggestion: %@", error.localizedRecoverySuggestion);
        }
        
        if (data != nil) {
            NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            //NSLog(@"temp data %@", dataStr);
            
            SBJSON * parser = [[SBJSON alloc] init];
            NSDictionary * jsonObjects = [parser objectWithString:dataStr error:nil];
            if (verbose)
                NSLog(@"JSONObjects %@", jsonObjects);
            NSDictionary * moon_phase = [jsonObjects valueForKey:@"moon_phase"];
            if (verbose)
                NSLog(@"moon phase %@", moon_phase);
            
            // astronomy items
            NSDictionary * moon_sunrise = [moon_phase valueForKey:@"sunrise"];
            if (verbose)
                NSLog(@"moon_sunrise %@", moon_sunrise);
            
            // astronomy items
            NSDictionary * moon_sunset = [moon_phase valueForKey:@"sunset"];
            if (verbose)
                NSLog(@"moon_sunset %@", moon_sunset);
            
            NSString * sunrise = nil;
            NSString * sunset = nil;
            NSString * percentIlluminated = nil;
            NSString * ageOfMoon = nil;
            
            NSString * sunrise_hour = [moon_sunrise valueForKey:@"hour"];
            NSString * sunrise_minute = [moon_sunrise valueForKey:@"hour"];
            NSString * sunset_hour = [moon_sunset valueForKey:@"hour"];
            NSString * sunset_minute = [moon_sunset valueForKey:@"minute"];
            NSString * _percentIlluminated = [moon_phase valueForKey:@"percentIlluminated"];
            NSString * _ageOfMoon = [moon_phase valueForKey:@"ageOfMoon"];
            
            if (verbose)
                NSLog(@"sunrise hour %@ minute %@", sunrise_hour, sunrise_minute);
            
            if (sunrise_hour != nil && sunrise_hour.length > 0 && sunrise_minute != nil && sunrise_hour.length > 0) {
                int sunriseHour = [sunrise_hour intValue];
                int sunriseMinute = [sunrise_minute intValue];
                //sunrise = [NSString stringWithFormat:@"%@:%@", sunrise_hour, sunrise_minute];
                sunrise = [NSString stringWithFormat:@"%d:%02d", sunriseHour, sunriseMinute];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- sunrise '%@'", sunrise);
                }
            }
            
            if (sunset_hour != nil && sunset_hour.length > 0 && sunset_minute != nil && sunset_hour.length > 0) {
                int sunsetHour = [sunset_hour intValue];
                int sunsetMinute = [sunset_minute intValue];
                //sunset = [NSString stringWithFormat:@"%@:%@", sunset_hour, sunset_minute];
                sunset = [NSString stringWithFormat:@"%02d:%02d", sunsetHour, sunsetMinute];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- sunset '%@'", sunset);
                }
            }
            
            if (_percentIlluminated != nil && _percentIlluminated.length > 0) {
                percentIlluminated = [NSString stringWithFormat:@"%@%%", _percentIlluminated];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- percentIlluminated '%@'", percentIlluminated);
                }
            }
            
            if (_ageOfMoon != nil && _ageOfMoon.length > 0) {
                ageOfMoon = [_ageOfMoon copy];
                
                if ([ageOfMoon isEqualToString:@"1"])
                    ageOfMoon = [NSString stringWithFormat:@"%@ day", _ageOfMoon];
                else
                    ageOfMoon = [NSString stringWithFormat:@"%@ days", _ageOfMoon];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- percentIlluminated '%@'", percentIlluminated);
                }
            }
            
            if (sunrise != nil && sunset != nil) {
                [dict setObject:sunrise forKey:@"sunrise"];
                [dict setObject:sunset forKey:@"sunset"];
            }
            
            if (percentIlluminated != nil && ageOfMoon != nil) {
                [dict setObject:percentIlluminated forKey:@"percentIlluminated"];
                [dict setObject:ageOfMoon forKey:@"ageOfMoon"];
            }
        }
        
        //NSLog(@"[getLocationSunriseSunset] urlStr %@", urlStr);
        
    }
    @catch (NSException * ex) {
        //NSLog(@"[getLocationSunriseSunset] Error: %@", [ex description]);
    }
    
    return dict;
}

// get the Sunrise time for a location address
//
// NSString * _address - location address
// BOOL verbose - turn verbose mode on/off
//
// return NSString * - sunrise time
//
+ (NSString *)getLocationSunrise:(NSString *)_address verbose:(BOOL)verbose {
    NSString * sunrise = nil;
    
    if (verbose)
        NSLog(@"getting sunrise for the address %@", _address);
    
    @try {
        
        if (_address != nil)
            _address = [_address stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        else {
            if (_address == nil) {
                _address = [UIWeatherView getCurrentAddress];
            }
            
            if (_address == nil) {
                NSLog(@"The address specified is nil!");
                return nil;
            }
        }
        
        //_address = [UIWeatherView formatAddress:_address];
        //_address = [_address stringByReplacingOccurrencesOfString:@"United States" withString:@""];
        
        NSArray * comps = [_address componentsSeparatedByString:@", "];
        NSString * part1 = [comps objectAtIndex:1];
        
        if (comps.count == 3)
            part1 = [comps objectAtIndex:2];
        
        NSString * part2 = [comps objectAtIndex:0];
        
        //NSLog(@"part1 is '%@'", part1);
        //NSLog(@"part2 is '%@'", part2);
        
        NSArray * part1Comps = [part1 componentsSeparatedByString:@" "];
        NSString * state = nil;
        
        if (part1Comps.count == 2) {
            state = part1;
            state = [state stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        } else
            state = [part1Comps objectAtIndex:0];
        
        NSArray * part2Comps = [part2 componentsSeparatedByString:@" "];
        NSString * city = nil;
        
        //NSLog(@"part2Comps %@", part2Comps);
        //NSLog(@"part2Count %d", part2Comps.count);
        
        if (part2Comps.count == 2) {
            city = part2;
            city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        } else
            city = [part2Comps objectAtIndex:part2Comps.count-1];
        
        //NSLog(@"city %@", city);
        //city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        
        NSString * urlStr = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/astronomy/q/%@/%@.json", weatherAPIKey, state, city];
        if (verbose)
            NSLog(@"urlStr '%@'", urlStr);
        
        NSURL * url = [NSURL URLWithString:urlStr];
        NSURLResponse * response;
        NSError * error;
        NSURLRequest * request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:90.0];
        NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        //if (data != nil)
        //	NSLog(@"network data was returned.");
        //else
        //	NSLog(@"network data is nil!");
        
        if (error != nil) {
            //NSLog(@"network description: %@", error.localizedDescription);
            //NSLog(@"network error: %@", error.localizedFailureReason);
            //NSLog(@"recovery suggestion: %@", error.localizedRecoverySuggestion);
        }
        
        if (data != nil) {
            NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            //NSLog(@"temp data %@", dataStr);
            
            SBJSON * parser = [[SBJSON alloc] init];
            NSDictionary * jsonObjects = [parser objectWithString:dataStr error:nil];
            if (verbose)
                NSLog(@"JSONObjects %@", jsonObjects);
            NSDictionary * moon_phase = [jsonObjects valueForKey:@"moon_phase"];
            if (verbose)
                NSLog(@"moon phase %@", moon_phase);
            
            // astronomy items
            NSDictionary * moon_sunrise = [moon_phase valueForKey:@"sunrise"];
            if (verbose)
                NSLog(@"moon_sunrise %@", moon_sunrise);
            
            NSString * sunrise_hour = [moon_sunrise valueForKey:@"hour"];
            NSString * sunrise_minute = [moon_sunrise valueForKey:@"hour"];
            
            if (verbose)
                NSLog(@"sunrise hour %@ minute %@", sunrise_hour, sunrise_minute);
            
            if (sunrise_hour != nil && sunrise_hour.length > 0 && sunrise_minute != nil && sunrise_hour.length > 0) {
                int sunriseHour = [sunrise_hour intValue];
                int sunriseMinute = [sunrise_minute intValue];
                //sunrise = [NSString stringWithFormat:@"%@:%@", sunrise_hour, sunrise_minute];
                sunrise = [NSString stringWithFormat:@"%d:%02d", sunriseHour, sunriseMinute];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- sunrise '%@'", sunrise);
                }
            }
        }
        
        //NSLog(@"[getLocationSunrise] urlStr %@", urlStr);
        
    }
    @catch (NSException * ex) {
        //NSLog(@"[getLocationSunrise] Error: %@", [ex description]);
        //NSLog(@"sunset %@", sunrise);
    }
    
    return sunrise;
}

// get the Sunset time for a location address
//
// NSString * _address - location address
// BOOL verbose - turn verbose mode on/off
//
// return NSString * - sunset time
//
+ (NSString *)getLocationSunset:(NSString *)_address verbose:(BOOL)verbose {
    NSString * sunset = nil;
    
    if (verbose)
        NSLog(@"getting sunset for the address %@", _address);
    
    @try {
        
        if (_address != nil)
            _address = [_address stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        else {
            if (_address == nil) {
                _address = [UIWeatherView getCurrentAddress];
            }
            
            if (_address == nil) {
                NSLog(@"The address specified is nil!");
                return nil;
            }
        }
        
        //_address = [UIWeatherView formatAddress:_address];
        //_address = [_address stringByReplacingOccurrencesOfString:@"United States" withString:@""];
        
        NSArray * comps = [_address componentsSeparatedByString:@", "];
        NSString * part1 = [comps objectAtIndex:1];
        
        if (comps.count == 3)
            part1 = [comps objectAtIndex:2];
        
        NSString * part2 = [comps objectAtIndex:0];
        
        //NSLog(@"part1 is '%@'", part1);
        //NSLog(@"part2 is '%@'", part2);
        
        NSArray * part1Comps = [part1 componentsSeparatedByString:@" "];
        NSString * state = nil;
        
        if (part1Comps.count == 2) {
            state = part1;
            state = [state stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        } else
            state = [part1Comps objectAtIndex:0];
        
        NSArray * part2Comps = [part2 componentsSeparatedByString:@" "];
        NSString * city = nil;
        
        if (part2Comps.count == 2) {
            city = part2;
            city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        } else
            city = [part2Comps objectAtIndex:part2Comps.count-1];
        
        //city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        
        NSString * urlStr = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/astronomy/q/%@/%@.json", weatherAPIKey, state, city];
        if (verbose)
            NSLog(@"urlStr '%@'", urlStr);
        
        NSURL * url = [NSURL URLWithString:urlStr];
        NSURLResponse * response;
        NSError * error;
        NSURLRequest * request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:90.0];
        NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        //if (data != nil)
        //	NSLog(@"network data was returned.");
        //else
        //	NSLog(@"network data is nil!");
        
        if (error != nil) {
            //NSLog(@"network description: %@", error.localizedDescription);
            //NSLog(@"network error: %@", error.localizedFailureReason);
            //NSLog(@"recovery suggestion: %@", error.localizedRecoverySuggestion);
        }
        
        if (data != nil) {
            NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            //NSLog(@"temp data %@", dataStr);
            
            SBJSON * parser = [[SBJSON alloc] init];
            NSDictionary * jsonObjects = [parser objectWithString:dataStr error:nil];
            if (verbose)
                NSLog(@"JSONObjects %@", jsonObjects);
            
            NSDictionary * moon_phase = [jsonObjects valueForKey:@"moon_phase"];
            if (verbose)
                NSLog(@"moon phase %@", moon_phase);
            
            // astronomy items
            NSDictionary * moon_sunset = [moon_phase valueForKey:@"sunset"];
            if (verbose)
                NSLog(@"moon_sunset %@", moon_sunset);
            
            NSString * sunset_hour = [moon_sunset valueForKey:@"hour"];
            NSString * sunset_minute = [moon_sunset valueForKey:@"minute"];
            
            if (verbose)
                NSLog(@"sunset hour %@ minute %@", sunset_hour, sunset_minute);
            
            if (sunset_hour != nil && sunset_hour.length > 0 && sunset_minute != nil && sunset_hour.length > 0) {
                int sunsetHour = [sunset_hour intValue];
                int sunsetMinute = [sunset_minute intValue];
                //sunset = [NSString stringWithFormat:@"%@:%@", sunset_hour, sunset_minute];
                sunset = [NSString stringWithFormat:@"%02d:%02d", sunsetHour, sunsetMinute];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- sunset '%@'", sunset);
                }
            }
        }
        
        
        //NSLog(@"[getLocationSunset] urlStr %@", urlStr);
        
    }
    @catch (NSException * ex) {
        //NSLog(@"[getLocationSunset] Error: %@", [ex description]);
        //NSLog(@"sunset %@", sunset);
    }
    
    return sunset;
}

// get the Moon Illimination for a location address
//
// NSString * _address - location address
// BOOL verbose - turn verbose mode on/off
//
// return NSString * - moon illumination
+ (NSString *)getLocationMoonIllumination:(NSString *)_address verbose:(BOOL)verbose {
    NSString * moonIllumination = nil;
    
    if (verbose)
        NSLog(@"getting moon illumination for the address %@", _address);
    
    @try {
        
        if (_address != nil)
            _address = [_address stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        else {
            if (_address == nil) {
                _address = [UIWeatherView getCurrentAddress];
            }
            
            if (_address == nil) {
                NSLog(@"The address specified is nil!");
                return nil;
            }
        }
        
        //_address = [UIWeatherView formatAddress:_address];
        //_address = [_address stringByReplacingOccurrencesOfString:@"United States" withString:@""];
        
        NSArray * comps = [_address componentsSeparatedByString:@", "];
        NSString * part1 = [comps objectAtIndex:1];
        
        if (comps.count == 3)
            part1 = [comps objectAtIndex:2];
        
        NSString * part2 = [comps objectAtIndex:0];
        
        //NSLog(@"part1 is '%@'", part1);
        //NSLog(@"part2 is '%@'", part2);
        
        NSArray * part1Comps = [part1 componentsSeparatedByString:@" "];
        NSString * state = nil;
        
        if (part1Comps.count == 2) {
            state = part1;
            state = [state stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        } else
            state = [part1Comps objectAtIndex:0];
        
        NSArray * part2Comps = [part2 componentsSeparatedByString:@" "];
        NSString * city = nil;
        
        //NSLog(@"part2Comps %@", part2Comps);
        //NSLog(@"part2Count %d", part2Comps.count);
        
        if (part2Comps.count == 2) {
            city = part2;
            city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        } else
            city = [part2Comps objectAtIndex:part2Comps.count-1];
        
        //NSLog(@"city %@", city);
        //city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        
        NSString * urlStr = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/astronomy/q/%@/%@.json", weatherAPIKey, state, city];
        if (verbose)
            NSLog(@"urlStr '%@'", urlStr);
        
        NSURL * url = [NSURL URLWithString:urlStr];
        NSURLResponse * response;
        NSError * error;
        NSURLRequest * request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:90.0];
        NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        //if (data != nil)
        //	NSLog(@"network data was returned.");
        //else
        //	NSLog(@"network data is nil!");
        
        if (error != nil) {
            //NSLog(@"network description: %@", error.localizedDescription);
            //NSLog(@"network error: %@", error.localizedFailureReason);
            //NSLog(@"recovery suggestion: %@", error.localizedRecoverySuggestion);
        }
        
        if (data != nil) {
            NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            //NSLog(@"temp data %@", dataStr);
            
            SBJSON * parser = [[SBJSON alloc] init];
            NSDictionary * jsonObjects = [parser objectWithString:dataStr error:nil];
            if (verbose)
                NSLog(@"JSONObjects %@", jsonObjects);
            NSDictionary * moon_phase = [jsonObjects valueForKey:@"moon_phase"];
            if (verbose)
                NSLog(@"moon phase %@", moon_phase);
            
            // astronomy items
            NSDictionary * moon_sunrise = [moon_phase valueForKey:@"sunrise"];
            if (verbose)
                NSLog(@"moon_sunrise %@", moon_sunrise);
            
            // astronomy items
            NSDictionary * moon_sunset = [moon_phase valueForKey:@"sunset"];
            if (verbose)
                NSLog(@"moon_sunset %@", moon_sunset);
            
            NSString * sunrise = nil;
            NSString * sunset = nil;
            NSString * percentIlluminated = nil;
            NSString * ageOfMoon = nil;
            
            NSString * sunrise_hour = [moon_sunrise valueForKey:@"hour"];
            NSString * sunrise_minute = [moon_sunrise valueForKey:@"hour"];
            NSString * sunset_hour = [moon_sunset valueForKey:@"hour"];
            NSString * sunset_minute = [moon_sunset valueForKey:@"minute"];
            NSString * _percentIlluminated = [moon_phase valueForKey:@"percentIlluminated"];
            NSString * _ageOfMoon = [moon_phase valueForKey:@"ageOfMoon"];
            
            if (verbose)
                NSLog(@"sunrise hour %@ minute %@", sunrise_hour, sunrise_minute);
            
            if (sunrise_hour != nil && sunrise_hour.length > 0 && sunrise_minute != nil && sunrise_hour.length > 0) {
                int sunriseHour = [sunrise_hour intValue];
                int sunriseMinute = [sunrise_minute intValue];
                //sunrise = [NSString stringWithFormat:@"%@:%@", sunrise_hour, sunrise_minute];
                sunrise = [NSString stringWithFormat:@"%d:%02d", sunriseHour, sunriseMinute];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- sunrise '%@'", sunrise);
                }
            }
            
            if (sunset_hour != nil && sunset_hour.length > 0 && sunset_minute != nil && sunset_hour.length > 0) {
                int sunsetHour = [sunset_hour intValue];
                int sunsetMinute = [sunset_minute intValue];
                //sunset = [NSString stringWithFormat:@"%@:%@", sunset_hour, sunset_minute];
                sunset = [NSString stringWithFormat:@"%02d:%02d", sunsetHour, sunsetMinute];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- sunset '%@'", sunset);
                }
            }
            
            if (_percentIlluminated != nil && _percentIlluminated.length > 0) {
                moonIllumination = [NSString stringWithFormat:@"%@%%", _percentIlluminated];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- percentIlluminated '%@'", moonIllumination);
                }
            }
            
            if (_ageOfMoon != nil && _ageOfMoon.length > 0) {
                ageOfMoon = [_ageOfMoon copy];
                
                if ([ageOfMoon isEqualToString:@"1"])
                    ageOfMoon = [NSString stringWithFormat:@"%@ day", _ageOfMoon];
                else
                    ageOfMoon = [NSString stringWithFormat:@"%@ days", _ageOfMoon];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- percentIlluminated '%@'", percentIlluminated);
                }
            }
        }
    }
    @catch (NSException * ex) {
        //NSLog(@"[getLocationMoonIllumination] Error: %@", [ex description]);
    }

    return moonIllumination;
}

// get the Moon Age for a location address
//
// NSString * _address - location address
// BOOL verbose - turn verbose mode on/off
//
// return NSString * - moon age
+ (NSString *)getLocationMoonAge:(NSString *)_address verbose:(BOOL)verbose {
    NSString * ageOfMoon = nil;
    
    if (verbose)
        NSLog(@"getting moon illumination for the address %@", _address);
    
    @try {
        
        if (_address != nil)
            _address = [_address stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        else {
            if (_address == nil) {
                _address = [UIWeatherView getCurrentAddress];
            }
            
            if (_address == nil) {
                NSLog(@"The address specified is nil!");
                return nil;
            }
        }
        
        //_address = [UIWeatherView formatAddress:_address];
        //_address = [_address stringByReplacingOccurrencesOfString:@"United States" withString:@""];
        
        NSArray * comps = [_address componentsSeparatedByString:@", "];
        NSString * part1 = [comps objectAtIndex:1];
        
        if (comps.count == 3)
            part1 = [comps objectAtIndex:2];
        
        NSString * part2 = [comps objectAtIndex:0];
        
        //NSLog(@"part1 is '%@'", part1);
        //NSLog(@"part2 is '%@'", part2);
        
        NSArray * part1Comps = [part1 componentsSeparatedByString:@" "];
        NSString * state = nil;
        
        if (part1Comps.count == 2) {
            state = part1;
            state = [state stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        } else
            state = [part1Comps objectAtIndex:0];
        
        NSArray * part2Comps = [part2 componentsSeparatedByString:@" "];
        NSString * city = nil;
        
        //NSLog(@"part2Comps %@", part2Comps);
        //NSLog(@"part2Count %d", part2Comps.count);
        
        if (part2Comps.count == 2) {
            city = part2;
            city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        } else
            city = [part2Comps objectAtIndex:part2Comps.count-1];
        
        //NSLog(@"city %@", city);
        //city = [city stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        
        NSString * urlStr = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/astronomy/q/%@/%@.json", weatherAPIKey, state, city];
        if (verbose)
            NSLog(@"urlStr '%@'", urlStr);
        
        NSURL * url = [NSURL URLWithString:urlStr];
        NSURLResponse * response;
        NSError * error;
        NSURLRequest * request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:90.0];
        NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        //if (data != nil)
        //	NSLog(@"network data was returned.");
        //else
        //	NSLog(@"network data is nil!");
        
        if (error != nil) {
            //NSLog(@"network description: %@", error.localizedDescription);
            //NSLog(@"network error: %@", error.localizedFailureReason);
            //NSLog(@"recovery suggestion: %@", error.localizedRecoverySuggestion);
        }
        
        if (data != nil) {
            NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            //NSLog(@"temp data %@", dataStr);
            
            SBJSON * parser = [[SBJSON alloc] init];
            NSDictionary * jsonObjects = [parser objectWithString:dataStr error:nil];
            if (verbose)
                NSLog(@"JSONObjects %@", jsonObjects);
            NSDictionary * moon_phase = [jsonObjects valueForKey:@"moon_phase"];
            if (verbose)
                NSLog(@"moon phase %@", moon_phase);
            
            // astronomy items
            NSDictionary * moon_sunrise = [moon_phase valueForKey:@"sunrise"];
            if (verbose)
                NSLog(@"moon_sunrise %@", moon_sunrise);
            
            // astronomy items
            NSDictionary * moon_sunset = [moon_phase valueForKey:@"sunset"];
            if (verbose)
                NSLog(@"moon_sunset %@", moon_sunset);
            
            NSString * sunrise = nil;
            NSString * sunset = nil;
            
            NSString * sunrise_hour = [moon_sunrise valueForKey:@"hour"];
            NSString * sunrise_minute = [moon_sunrise valueForKey:@"hour"];
            NSString * sunset_hour = [moon_sunset valueForKey:@"hour"];
            NSString * sunset_minute = [moon_sunset valueForKey:@"minute"];
            NSString * _ageOfMoon = [moon_phase valueForKey:@"ageOfMoon"];
            
            if (verbose)
                NSLog(@"sunrise hour %@ minute %@", sunrise_hour, sunrise_minute);
            
            if (sunrise_hour != nil && sunrise_hour.length > 0 && sunrise_minute != nil && sunrise_hour.length > 0) {
                int sunriseHour = [sunrise_hour intValue];
                int sunriseMinute = [sunrise_minute intValue];
                //sunrise = [NSString stringWithFormat:@"%@:%@", sunrise_hour, sunrise_minute];
                sunrise = [NSString stringWithFormat:@"%d:%02d", sunriseHour, sunriseMinute];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- sunrise '%@'", sunrise);
                }
            }
            
            if (sunset_hour != nil && sunset_hour.length > 0 && sunset_minute != nil && sunset_hour.length > 0) {
                int sunsetHour = [sunset_hour intValue];
                int sunsetMinute = [sunset_minute intValue];
                //sunset = [NSString stringWithFormat:@"%@:%@", sunset_hour, sunset_minute];
                sunset = [NSString stringWithFormat:@"%02d:%02d", sunsetHour, sunsetMinute];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- sunset '%@'", sunset);
                }
            }
            
            if (_ageOfMoon != nil && _ageOfMoon.length > 0) {
                ageOfMoon = [_ageOfMoon copy];
                
                if ([ageOfMoon isEqualToString:@"1"])
                    ageOfMoon = [NSString stringWithFormat:@"%@ day", _ageOfMoon];
                else
                    ageOfMoon = [NSString stringWithFormat:@"%@ days", _ageOfMoon];
                
                if (verbose) {
                    NSLog(@"Astronomy %@", moon_phase);
                    NSLog(@"-- ageOfMoon '%@'", ageOfMoon);
                }
            }
        }
    }
    @catch (NSException * ex) {
        //NSLog(@"[getLocationMoonIllumination] Error: %@", [ex description]);
    }
    

    return ageOfMoon;
}


//  set whether monitoring of your location is on or off.  On by default.
//  Note: if you want UIWeatherView to automatically get your current address
//  ,which is needed for getWeatherForCurrentAddress, you should leave this on
+ (void)setLocationMonitoring:(BOOL)_monitorLocation {
    
    monitorLocation = _monitorLocation;
}

// set the location delegate to call when location changes
+ (void)setLocationDelegate:(id<LocationUtilsDelegate>)_locationDelegate {
    
    locationDelegate = _locationDelegate;
}

// get the location delegate to call when monitoring in on
//
// return (id<LocationUtilsDelegate>) locationDelegate
+ (id<LocationUtilsDelegate>)getLocationDelegate {
    
    return locationDelegate;
}

// get the address for a coordinate
//
// return NSString * - the address
+ (NSString *)getAddressForCoordinate:(CLLocationCoordinate2D)coordinate verbose:(BOOL)verbose {
    __block NSString * _address = nil;
    
    if (coordinate.latitude == 0.0 || coordinate.longitude == 0.0)
        return _address;
    
    CLLocation * location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    
    if (verbose)
        NSLog(@"reverse geocode lat %f long %f...", coordinate.latitude, coordinate.longitude);
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray * placemarks, NSError * error) {
        
        dispatch_async(dispatch_get_main_queue() , ^ {
            
            CLPlacemark * placemark = [placemarks lastObject];
            
            if (error == nil) {
                if (verbose)
                    NSLog(@"clGeocoder OK!");
                
                _address = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];
                
                if (verbose)
                    NSLog(@"--> found coordinate address: '%@'", _address);
            } else {
                if (verbose)
                    NSLog(@"clGeocoder Error!");
            }
            
            dispatch_group_leave(group);
        });
    }];
    
    while (dispatch_group_wait(group, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.f]];
    }
    
    if (verbose)
        NSLog(@"leaving with address:'%@'", _address);
    
    return _address;
}

// get the coordinate for an address
//
// NSString * address - the address to validate and expand
// BOOL verbose - turn verbose mode on or off
//
// return CLLocationCoordinate2D coordinate - the coordinate
+ (CLLocationCoordinate2D)getAddressCoordinate:(NSString *)address verbose:(BOOL)verbose {
    __block CLLocationCoordinate2D _coordinate;
    
    if (address == nil || address.length == 0)
        return _coordinate;
    
    if (verbose)
        NSLog(@"forward geocode %@...", address);
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    
    [geocoder geocodeAddressString:address completionHandler:^(NSArray * placemarks, NSError * error) {
        
        dispatch_async(dispatch_get_main_queue() , ^ {
            
            CLPlacemark * placemark = [placemarks lastObject];
            
            if (error == nil) {
                if (verbose)
                    NSLog(@"clGeocoder OK!");
                
                _coordinate = placemark.location.coordinate;
                
                if (verbose)
                    NSLog(@"--> found address coordinate: %.2f, %.2f", _coordinate.latitude, _coordinate.longitude);
            } else {
                if (verbose)
                    NSLog(@"clGeocoder Error!");
            }
            
            dispatch_group_leave(group);
        });
    }];
    
    while (dispatch_group_wait(group, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.f]];
    }
    
    if (verbose)
        NSLog(@"leaving with coordinate: %.2f, %.2f", _coordinate.latitude, _coordinate.longitude);
    
    return _coordinate;
}

// get the full address for an address
//
// NSString * address - the address to expand/validate
//
// return NSString * - the address
+ (NSString *)getFullAddressForAddress:(NSString *)address formatted:(BOOL)formatted verbose:(BOOL)verbose {
    __block NSString * _address = nil;
    
    if (address == nil || address.length == 0)
        return _address;
    
    if (verbose)
        NSLog(@"forward geocode %@...", address);
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    
    [geocoder geocodeAddressString:address completionHandler:^(NSArray * placemarks, NSError * error) {
        
        dispatch_async(dispatch_get_main_queue() , ^ {
            
            CLPlacemark * placemark = [placemarks lastObject];
            
            if (error == nil) {
                if (verbose)
                    NSLog(@"clGeocoder OK!");
                
                if (formatted) {
                    // get formatted address...
                    NSArray * lines = placemark.addressDictionary[@"FormattedAddressLines" ];
                    _address = [lines componentsJoinedByString:@"\n"];
                } else {
                    // get unformattted address...
                    NSArray * lines = placemark.addressDictionary[@"FormattedAddressLines" ];
                    _address = [lines componentsJoinedByString:@", "];
                }
                
                // cityState
                //NSString * _cityStateAddress = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];
                
                if (verbose)
                    NSLog(@"--> found full  address: '%@'", _address);
            } else {
                if (verbose)
                    NSLog(@"clGeocoder Error!");
            }
            
            dispatch_group_leave(group);
        });
    }];
    
    while (dispatch_group_wait(group, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.f]];
    }
    
    if (verbose)
        NSLog(@"leaving with address:'%@'", _address);
    
    return _address;
}

// start of helper APIs

// get the location weather
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location weather (e.g. conditions: cloundy etc...)
+ (NSString *)getLocationWeatherFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _weather = nil;
    
    if (weatherDict != nil) {
        _weather = [weatherDict valueForKey:@"weather"];
    }
    
    return _weather;
}

// get the location temperature
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location temperature
+ (NSString *)getLocationTemperatureFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _temperature = nil;
    
    if (weatherDict != nil) {
        _temperature = [weatherDict valueForKey:@"temperature_string"];
    }
    
    return _temperature;
}

// get the location temperature in fahrenheit
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location temperature in fahrenheit
+ (NSString *)getLocationTemperatureFahrenheitFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _temperature_f = nil;
    
    if (weatherDict != nil) {
        _temperature_f = [weatherDict valueForKey:@"temp_f"];
    }
    
    return _temperature_f;
}

// get the location temperature in centigrade
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location temperature in centigrade
+ (NSString *)getLocationTemperatureCentigradeFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _temperature_c = nil;
    
    if (weatherDict != nil) {
        _temperature_c = [weatherDict valueForKey:@"temp_c"];
    }
    
    return _temperature_c;
}

// get the location relative humidity
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location relaive humidity
+ (NSString *)getLocationRelativeHumidityFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _relativeHumidity = nil;
    
    if (weatherDict != nil) {
        _relativeHumidity = [weatherDict valueForKey:@"relative_humidity"];
    }
    
    return _relativeHumidity;
}

// get the location wind
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind
+ (NSString *)getLocationWindFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _wind = nil;
    
    if (weatherDict != nil) {
        _wind = [weatherDict valueForKey:@"wind_string"];
    }
    
    return _wind;
}

// get the location wind degrees
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind degrees
+ (NSString *)getLocationWindDegreesFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _windDegrees = nil;
    
    if (weatherDict != nil) {
        _windDegrees = [weatherDict valueForKey:@"wind_degrees"];
    }
    
    return _windDegrees;
}

// get the location wind mph
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind mph
+ (NSString *)getLocationWindMphFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _windMph = nil;
    
    if (weatherDict != nil) {
        _windMph = [weatherDict valueForKey:@"wind_mph"];
    }
    
    return _windMph;
}

// get the location wind gust mph
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind gust mph
+ (NSString *)getLocationWindGustMphFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _windGustMph = nil;
    
    if (weatherDict != nil) {
        _windGustMph = [weatherDict valueForKey:@"wind_gust_mph"];
    }
    
    return _windGustMph;
}

// get the location wind kph
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind kph
+ (NSString *)getLocationWindKphFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _windKph = nil;
    
    if (weatherDict != nil) {
        _windKph = [weatherDict valueForKey:@"wind_kph"];
    }
    
    return _windKph;
}

// get the location wind gust kph
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location wind gust kph
+ (NSString *)getLocationWindGustKphFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _windGustKph = nil;
    
    if (weatherDict != nil) {
        _windGustKph = [weatherDict valueForKey:@"wind_gust_kph"];
    }
    
    return _windGustKph;
}

// get the location pressure in Mb
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location pressure in Mb
+ (NSString *)getLocationPressureMbFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _pressureMb = nil;
    
    if (weatherDict != nil) {
        _pressureMb = [weatherDict valueForKey:@"pressure_mb"];
    }
    
    return _pressureMb;
}

// get the location pressure in inches
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location pressure in inches
+ (NSString *)getLocationPressureInchesFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _pressureIn = nil;
    
    if (weatherDict != nil) {
        _pressureIn = [weatherDict valueForKey:@"pressure_in"];
    }
    
    return _pressureIn;
}

// get the location pressure trend
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location pressure trend
+ (NSString *)getLocationPressureTrendFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _pressureTrend = nil;
    
    if (weatherDict != nil) {
        _pressureTrend = [weatherDict valueForKey:@"pressure_trend"];
    }
    
    return _pressureTrend;
}

// get the location dewpoint
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location dewpoint
+ (NSString *)getLocationDewpointFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _dewpoint = nil;
    
    if (weatherDict != nil) {
        _dewpoint = [weatherDict valueForKey:@"dewpoint_string"];
    }
    
    return _dewpoint;
}

// get the location dewpoint in fahrenheit
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location dewpoint in fahrenheit
+ (NSString *)getLocationDewpointFahrenheitFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _dewpoint_f = nil;
    
    if (weatherDict != nil) {
        _dewpoint_f = [weatherDict valueForKey:@"dewpoint_f"];
    }
    
    return _dewpoint_f;
}

// get the location dewpoint in centigrade
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location dewpoint in centigrade
+ (NSString *)getLocationDewpointCentigradeFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _dewpoint_c = nil;
    
    if (weatherDict != nil) {
        _dewpoint_c = [weatherDict valueForKey:@"dewpoint_c"];
    }
    
    return _dewpoint_c;
}

// get the location heat index
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location heat index
+ (NSString *)getLocationHeatIndexFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _heatIndex = nil;
    
    if (weatherDict != nil) {
        _heatIndex = [weatherDict valueForKey:@"heat_index_string"];
    }
    
    return _heatIndex;
}

// get the location heat index n fahrenheit
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location heat index in fahrenheit
+ (NSString *)getLocationHeatIndexFahrenheitFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _heatIndex_f = nil;
    
    if (weatherDict != nil) {
        _heatIndex_f = [weatherDict valueForKey:@"heat_index_f"];
    }
    
    return _heatIndex_f;
}

// get the location heat index n centigrade
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location heat index in centigrade
+ (NSString *)getLocationHeatIndexCentigradeFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _heatIndex_c = nil;
    
    if (weatherDict != nil) {
        _heatIndex_c = [weatherDict valueForKey:@"heat_index_c"];
    }
    
    return _heatIndex_c;
}

// get the location windchill
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location windchill
+ (NSString *)getLocationWindchillFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _windchill = nil;
    
    if (weatherDict != nil) {
        _windchill = [weatherDict valueForKey:@"windchill_string"];
    }
    
    return _windchill;
}

// get the location windchill in fahrenheit
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location windchill in fahrenheit
+ (NSString *)getLocationWindchillFahrenheitFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _windchill_f = nil;
    
    if (weatherDict != nil) {
        _windchill_f = [weatherDict valueForKey:@"windchill_f"];
    }
    
    return _windchill_f;
}

// get the location windchill in centigrade
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location windchill in centigrade
+ (NSString *)getLocationWindchillCentigradeFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _windchill_c = nil;
    
    if (weatherDict != nil) {
        _windchill_c = [weatherDict valueForKey:@"windchill_c"];
    }
    
    return _windchill_c;
}

// get the location feels like temperature
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location feels like temperature
+ (NSString *)getLocationFeelslikeFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _feelslike = nil;
    
    if (weatherDict != nil) {
        _feelslike = [weatherDict valueForKey:@"feelslike_string"];
    }
    
    return _feelslike;
}

// get the location feels like temperature in fahrenheit
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location feels like temperature in fahrenheit
+ (NSString *)getLocationFeelslikeFahrenheitFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _feelslike_f = nil;
    
    if (weatherDict != nil) {
        _feelslike_f = [weatherDict valueForKey:@"feelslike_f"];
    }
    
    return _feelslike_f;
}

// get the location feels like temperature in centigrade
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location feels like temperature in fahrenheit
+ (NSString *)getLocationFeelslikeCentigradeFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _feelslike_c = nil;
    
    if (weatherDict != nil) {
        _feelslike_c = [weatherDict valueForKey:@"feelslike_c"];
    }
    
    return _feelslike_c;
}

// get the location visibility in miles
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location visibility in miles
+ (NSString *)getLocationVisibilityMilesFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _visibilityMi = nil;
    
    if (weatherDict != nil) {
        _visibilityMi = [weatherDict valueForKey:@"visibility_mi"];
    }
    
    return _visibilityMi;
}

// get the location visibility in Km
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location visibility in Km
+ (NSString *)getLocationVisibilityKmFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _visibilityKm = nil;
    
    if (weatherDict != nil) {
        _visibilityKm = [weatherDict valueForKey:@"visibility_km"];
    }

    return _visibilityKm;
}

// get the location solar radiation
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location solar radiation
+ (NSString *)getLocationSolarRadiationFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _solarRadiation = nil;
    
    if (weatherDict != nil) {
        _solarRadiation = [weatherDict valueForKey:@"solar_radiation"];
    }
    
    return _solarRadiation;
}

// get the location UV
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location UV
+ (NSString *)getLocationUVFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _uv = nil;
    
    if (weatherDict != nil) {
        _uv = [weatherDict valueForKey:@"UV"];
    }
    
    return _uv;
}

// get the location pricipitation in last 1 hour
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation in last 1 hours
+ (NSString *)getLocationPrecipitation1HrFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _precip1hr = nil;
    
    if (weatherDict != nil) {
        _precip1hr = [weatherDict valueForKey:@"precip_1hr_string"];
    }
    
    return _precip1hr;
}

// get the location pricipitation in last 1 hour in inches
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation in last 1 hours in inches
+ (NSString *)getLocationPrecipitation1HrInchesFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _precip1hr_in = nil;
    
    if (weatherDict != nil) {
        _precip1hr_in = [weatherDict valueForKey:@"precip_1hr_in"];
    }
    
    return _precip1hr_in;
}

// get the location pricipitation in last 1 hour in metric
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation in last 1 hours in metric
+ (NSString *)getLocationPrecipitation1HrMetricFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _precip1hr_metric = nil;
    
    if (weatherDict != nil) {
        _precip1hr_metric = [weatherDict valueForKey:@"precip_1hr_metric"];
    }
    
    return _precip1hr_metric;
}

// get the location pricipitation today
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation today
+ (NSString *)getLocationPrecipitationTodayFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _precip_today = nil;
    
    if (weatherDict != nil) {
        _precip_today = [weatherDict valueForKey:@"precip_today_string"];
    }
    
    return _precip_today;
}

// get the location pricipitation today in inches
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation today in inches
+ (NSString *)getLocationPrecipitationTodayInchesFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _precip_today_in = nil;
    
    if (weatherDict != nil) {
        _precip_today_in = [weatherDict valueForKey:@"precip_today_in"];
    }
    
    return _precip_today_in;
}

// get the location pricipitation today metric
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location precipitation today metric
+ (NSString *)getLocationPrecipitationTodayMetricFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _precip_today_metric = nil;
    
    if (weatherDict != nil) {
        _precip_today_metric = [weatherDict valueForKey:@"precip_today_metric"];
    }
    
    return _precip_today_metric;
}

// get the location icon
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location icon
+ (NSString *)getLocationIconFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _icon = nil;
    
    if (weatherDict != nil) {
        _icon = [weatherDict valueForKey:@"icon"];
    }
    
    return _icon;
}

// get the location icon url
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location icon url
+ (NSString *)getLocationIconUrlFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _icon_url = nil;
    
    if (weatherDict != nil) {
        _icon_url = [weatherDict valueForKey:@"icon_url"];
    }
    
    return _icon_url;
}

// get the location forecast url
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location forecast url
+ (NSString *)getLocationForecastUrlFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _forecast_url = nil;
    
    if (weatherDict != nil) {
        _forecast_url = [weatherDict valueForKey:@"forecast_url"];
    }
    
    return _forecast_url;
}

// get the location history url
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location history url
+ (NSString *)getLocationHistoryUrlFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _history_url = nil;
    
    if (weatherDict != nil) {
        _history_url = [weatherDict valueForKey:@"history_url"];
    }
    
    return _history_url;
}

// get the location observation url
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationWeather API
//
// return NSString * - location observation url
+ (NSString *)getLocationObservationUrlFromDict:(NSMutableDictionary *)weatherDict {
    NSString * _ob_url = nil;
    
    if (weatherDict != nil) {
        _ob_url = [weatherDict valueForKey:@"ob_url"];
    }
    
    return _ob_url;
}

// get the location sunrise
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationSunriseSunset API
//
// return NSString * - location sunrise
+ (NSString *)getLocationSunriseFromDict:(NSMutableDictionary *)sunriseSunsetDict {
    NSString * _sunrise = nil;
    
    if (sunriseSunsetDict != nil) {
        _sunrise = [sunriseSunsetDict valueForKey:@"sunrise"];
    }
    
    return _sunrise;
}

// get the location sunset
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationSunriseSunset API
//
// return NSString * - location sunset
+ (NSString *)getLocationSunsetFromDict:(NSMutableDictionary *)sunriseSunsetDict {
    NSString * _sunset = nil;
    
    if (sunriseSunsetDict != nil) {
        _sunset = [sunriseSunsetDict valueForKey:@"sunset"];
    }
    
    return _sunset;
    
}

// get the location moon percent illuminated
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationSunriseSunset API
//
// return NSString * - location moon percent illuminated
+ (NSString *)getLocationMoonPercentIllumnatedFromDict:(NSMutableDictionary *)sunriseSunsetDict {
    NSString * _percentIlluminated = nil;
    
    if (sunriseSunsetDict != nil) {
        _percentIlluminated = [sunriseSunsetDict valueForKey:@"percentIlluminated"];
    }
    
    return _percentIlluminated;
}

// get the location moon age
//
// NSMutableDictionary * weatherDict - weather dictionary returned by getLocationSunriseSunset API
//
// return NSString * - location moon age
+ (NSString *)getLocationMoonAgeFromDict:(NSMutableDictionary *)sunriseSunsetDict {
    NSString * _ageOfMoon = nil;
    
    if (sunriseSunsetDict != nil) {
        _ageOfMoon = [sunriseSunsetDict valueForKey:@"ageOfMoon"];
    }
    
    return _ageOfMoon;
}

// end of helper APIs

// end of Weather APIs


// Create using weather view showing weather details already acquired
//
// frame - weatherView frame
// title - title for weatherView
// NSMutableDictionary * weather - dictionary of weather details for location
//                                 Acquire using [UIWeatherView getLocationWeather] call...
// parent - parent view controller
// BOOL includeShare - include share button or not
// BOOL includeClose - include close button or not
// BOOL verbose - turn verbose mode on/off
//
- (id)initWithFrame:(CGRect)frame title:(NSString *)title weather:(NSMutableDictionary *)_weather sunrise:(NSString *)sunrise sunset:(NSString *)sunset percentIlluminated:(NSString *)percentIlluminated ageOfMoon:(NSString *)ageOfMoon parent:(UIViewController *)_parent allowSharing:(BOOL)allowSharing allowClosing:(BOOL)allowClosing verbose:(BOOL)verbose {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
        
        self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
        if ([self isRunningIPad])
            self.layer.cornerRadius = 8;
        
        parent = _parent;
        
        // main scrolling view...
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        //scrollView.delegate = self;
        scrollView.contentSize = CGSizeMake(frame.size.width, frame.size.height + 200);
        [self addSubview:scrollView];
        
        int lineCount = 0;   // number lines of weather information found...
        
        if (_weather == nil) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Show Weather Notice" message:@"Weather is currently not available for this address!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            return nil;
        }
        
        NSString * _address = [_weather valueForKey:@"address"];
        
        if (_address != nil) {
            _address = [_address stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
            address = [_address copy];
        }
        
        htmlText = @"";
        current_observation = [_weather mutableCopy];
        
        if (sunrise != nil)
            weatherSunrise = [sunrise copy];
        if (sunset != nil)
            weatherSunset = [sunset copy];
        if (percentIlluminated != nil)
            weatherPercentIlluminated = [percentIlluminated copy];
        if (ageOfMoon != nil)
            weatherAgeOfMoon = [ageOfMoon copy];
        
        // create html from weather info...
        
        // Weather items
        NSString * _weather = [current_observation valueForKey:@"weather"];
        NSString * temperature_string = [current_observation valueForKey:@"temperature_string"];
        NSString * temp_f = [current_observation valueForKey:@"temp_f"];
        NSString * temp_c = [current_observation valueForKey:@"temp_c"];
        NSString * relative_humidity = [current_observation valueForKey:@"relative_humidity"];
        
        NSString * wind = [current_observation valueForKey:@"wind_string"];
        NSString * wind_dir = [current_observation valueForKey:@"wind_dir"];
        NSString * wind_degrees = [current_observation valueForKey:@"wind_degrees"];
        NSString * wind_mph = [current_observation valueForKey:@"wind_mph"];
        NSString * wind_gust_mph = [current_observation valueForKey:@"wind_gust_mph"];
        NSString * wind_kph = [current_observation valueForKey:@"wind_kph"];
        NSString * wind_gust_kph = [current_observation valueForKey:@"wind_gust_kph"];
        NSString * pressure_mb = [current_observation valueForKey:@"pressure_mb"];
        NSString * pressure_in = [current_observation valueForKey:@"pressure_in"];
        NSString * pressure_trend = [current_observation valueForKey:@"pressure_trend"];
        NSString * dewpoint_string = [current_observation valueForKey:@"dewpoint_string"];
        NSString * dewpoint_f = [current_observation valueForKey:@"dewpoint_f"];
        NSString * dewpoint_c = [current_observation valueForKey:@"dewpoint_c"];
        NSString * heat_index_string = [current_observation valueForKey:@"heat_index_string"];
        NSString * heat_index_f = [current_observation valueForKey:@"heat_index_f"];
        NSString * heat_index_c = [current_observation valueForKey:@"heat_index_c"];
        NSString * windchill_string = [current_observation valueForKey:@"windchill_string"];
        NSString * windchill_f = [current_observation valueForKey:@"windchill_f"];
        NSString * windchill_c = [current_observation valueForKey:@"windchill_c"];
        NSString * feelslike_string = [current_observation valueForKey:@"feelslike_string"];
        NSString * feelslike_f = [current_observation valueForKey:@"feelslike_f"];
        NSString * feelslike_c = [current_observation valueForKey:@"feelslike_c"];
        NSString * visibility_mi = [current_observation valueForKey:@"visibility_mi"];
        NSString * visibility_km = [current_observation valueForKey:@"visibility_km"];
        NSString * solar_radiation = [current_observation valueForKey:@"solar_radiation"];
        NSString * uv = [current_observation valueForKey:@"UV"];
        NSString * precip_1hr_string = [current_observation valueForKey:@"precip_1hr_string"];
        NSString * precip_1hr_in = [current_observation valueForKey:@"precip_1hr_in"];
        NSString * precip_1hr_metric = [current_observation valueForKey:@"precip_1hr_metric"];
        NSString * precip_today_string = [current_observation valueForKey:@"precip_today_string"];
        NSString * precip_today_in = [current_observation valueForKey:@"precip_today_in"];
        NSString * precip_today_metric = [current_observation valueForKey:@"precip_today_metric"];
        NSString * icon = [current_observation valueForKey:@"icon"];
        NSString * icon_url = [current_observation valueForKey:@"icon_url"];
        NSString * forecast_url = [current_observation valueForKey:@"forecast_url"];
        NSString * history_url = [current_observation valueForKey:@"history_url"];
        NSString * ob_url = [current_observation valueForKey:@"ob_url"];
        
        BOOL excludeRedundant = TRUE;
        NSString * sunriseSunsetStr = nil;
        
        if (_weather != nil) {
            if (verbose)
                NSLog(@"found weather of %@", _weather);
            
            if (sunrise != nil && sunset != nil) {
                if (verbose)
                    NSLog(@"Sunrise %@ Sunset %@", sunrise, sunset);
                
                sunriseSunsetStr = [NSString stringWithFormat:@"<br><b>Sunrise:</b> %@<br><b>Sunset:</b> %@", sunrise, sunset];
            }
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Weather:</b> %@  <br><a href='%@'>forecast</a>  <a href='%@'>history</a>            %@<br>", _weather, forecast_url, history_url, sunriseSunsetStr];
            lineCount += 4;
        }
        
        if (percentIlluminated != nil && ageOfMoon != nil) {
            NSString * fullMoonStr = @"";
            //percentIlluminated = @"100%";  // test
            
            if ([percentIlluminated isEqualToString:@"100%"])
                fullMoonStr = @"(full moon)";
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Moon Illumination:</b> %@ %@<br><b>Moon Age:</b> %@<br>", percentIlluminated, fullMoonStr, ageOfMoon];
            lineCount += 2;
        }
        
        if (temperature_string != nil) {
            if (verbose)
                NSLog(@"found temperature_string of %@", temperature_string);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Temperature:</b> %@<br>", temperature_string];
            ++lineCount;
        }
        
        if (windchill_string != nil) {
            if (verbose)
                NSLog(@"found windchill_string %@", windchill_string);
            
            windchill_string = [windchill_string stringByReplacingOccurrencesOfString:@"NA" withString:@"n/a"];
            htmlText = [htmlText stringByAppendingFormat:@"<b>Windchill:</b> %@<br>", windchill_string];
            ++lineCount;
        }
        
        if (temp_f != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found temp_f of %@", temp_f);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Temperature:</b> %@ F<br>", temp_f];
            ++lineCount;
        }
        
        if (temp_c != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found temp_c of %@", temp_c);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Temperature:</b> %@ C<br>", temp_c];
            ++lineCount;
        }
        
        if (relative_humidity != nil) {
            if (verbose)
                NSLog(@"found relative_humidity of %@", relative_humidity);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Relative Humidity:</b> %@<br>", relative_humidity];
            ++lineCount;
        }
        
        if (wind != nil) {
            if (verbose)
                NSLog(@"found wind %@", wind);
            
            wind = [wind stringByReplacingOccurrencesOfString:@"MPH" withString:@"mph"];
            htmlText = [htmlText stringByAppendingFormat:@"<b>Wind:</b> %@<br>", wind];
            ++lineCount;
        }
        
        if (wind_dir!= nil) {
            if (verbose)
                NSLog(@"found win_dir %@", wind_dir);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Wind Direction:</b> %@<br>", wind_dir];
            ++lineCount;
        }
        
        if (wind_degrees != nil) {
            if (verbose)
                NSLog(@"found wind_degrees %@", wind_degrees);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Wind Degrees:</b> %@<br>", wind_degrees];
            ++lineCount;
        }
        
        if (wind_mph != nil && wind_kph != nil) {
            if (verbose)
                NSLog(@"found wind_mph %@", wind_mph);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Wind:</b> %@ mph (%@ kph)<br>", wind_mph, wind_kph];
            ++lineCount;
        }
        
        if (wind_gust_mph != nil && wind_gust_kph != nil) {
            if (verbose)
                NSLog(@"found wind_gust_mph %@", wind_gust_mph);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Wind Gust:</b> %@ mph (%@ kph)<br>", wind_gust_mph, wind_gust_kph];
            ++lineCount;
        }
        
        if (wind_kph != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found wind_kph %@", wind_kph);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Wind:</b> %@ kph<br>", wind_kph];
            ++lineCount;
        }
        
        if (wind_gust_kph != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found wind_gust_kph %@", wind_gust_kph);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Wind Gust:</b> %@ kph<br>", wind_gust_kph];
            ++lineCount;
        }
        
        if (pressure_mb != nil && pressure_in) {
            if (verbose)
                NSLog(@"found pressure_mb %@", pressure_mb);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Pressure:</b> %@ millibars (%@ inches)<br>", pressure_mb, pressure_in];
            ++lineCount;
        }
        
        if (pressure_in != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found presure_in %@", pressure_in);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Pressure:</b> %@ inches<br>", pressure_in];
            ++lineCount;
        }
        
        if (pressure_trend != nil) {
            if (verbose)
                NSLog(@"found wpresure_trend %@", pressure_trend);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Pressure Trend:</b> %@<br>", pressure_trend];
            ++lineCount;
        }
        
        if (dewpoint_string != nil) {
            if (verbose)
                NSLog(@"found dewpoint_string %@", dewpoint_string);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Dewpoint:</b> %@<br>", dewpoint_string];
            ++lineCount;
        }
        
        if (dewpoint_f != nil && dewpoint_c != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found dewpoint_f %@", dewpoint_f);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Dewpoint:</b> %@ F (%@ C)<br>", dewpoint_f, dewpoint_c];
            ++lineCount;
        }
        
        if (dewpoint_c != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found dewpoint_c %@", dewpoint_c);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Dewpoint:</b> %@ C<br>", dewpoint_c];
            ++lineCount;
        }
        
        if (heat_index_string != nil) {
            if (verbose)
                NSLog(@"found heat_index_string %@", heat_index_string);
            
            heat_index_string = [heat_index_string stringByReplacingOccurrencesOfString:@"NA" withString:@"n/a"];
            htmlText = [htmlText stringByAppendingFormat:@"<b>Heat Index:</b> %@<br>", heat_index_string];
            ++lineCount;
        }
        
        if (heat_index_f != nil && heat_index_c != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found heat_index_f %@", heat_index_f);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Heat Index:</b> %@ F (%@ C)<br>", heat_index_f, heat_index_c];
            ++lineCount;
        }
        
        if (heat_index_c != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found heat_index_c %@", heat_index_c);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Heat Index:</b> %@ C<br>", heat_index_c];
            ++lineCount;
        }
        
        if (windchill_f != nil && windchill_c != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found windchill_f %@", windchill_f);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Windchill:</b> %@ F (%@ C)<br>", windchill_f, windchill_c];
            ++lineCount;
        }
        
        if (windchill_c != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found windchill_c %@", windchill_c);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Windchill:</b> %@ C<br>", windchill_c];
            ++lineCount;
        }
        
        if (feelslike_string != nil) {
            if (verbose)
                NSLog(@"found feelslike_string %@", feelslike_string);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Feels Like:</b> %@<br>", feelslike_string];
            ++lineCount;
        }
        
        if (feelslike_f != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found feelslike_f %@", feelslike_f);
            htmlText = [htmlText stringByAppendingFormat:@"<b>Feels Like:</b> %@ F<br>", feelslike_f];
            ++lineCount;
        }
        
        if (feelslike_c != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found feelslike_c %@", feelslike_c);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Feels Like:</b> %@ C<br>", feelslike_c];
            ++lineCount;
        }
        
        if (visibility_mi != nil && visibility_km != nil) {
            if (verbose)
                NSLog(@"found visibility_mi %@", visibility_mi);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Visibility:</b> %@ miles (%@ km)<br>", visibility_mi, visibility_km];
            ++lineCount;
        }
        
        if (visibility_km != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found visibility_km %@", visibility_km);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Visiblity:</b> %@ km<br>", visibility_km];
            ++lineCount;
        }
        
        if (solar_radiation != nil) {
            if (verbose)
                NSLog(@"found colar_radiation %@", solar_radiation);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Solar Radiation</b> %@<br>", solar_radiation];
            ++lineCount;
        }
        
        if (uv != nil) {
            if (verbose)
                NSLog(@"found UV %@", uv);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>UV:</b> %@<br>", uv];
            ++lineCount;
        }
        
        if (precip_1hr_string != nil) {
            if (verbose)
                NSLog(@"found precip_1hr_string %@", precip_1hr_string);
            
            // make -999.00 no report value a 0...
            precip_1hr_string = [precip_1hr_string stringByReplacingOccurrencesOfString:@"-999.00" withString:@"0"];
            precip_1hr_string = [precip_1hr_string stringByReplacingOccurrencesOfString:@"( " withString:@"("];
            htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation 1 hour:</b> %@<br>", precip_1hr_string];
            ++lineCount;
        }
        
        if (precip_1hr_in != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found precip_1hr_in %@", precip_1hr_in);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation 1 hour:</b> %@ inches<br>", precip_1hr_in];
            ++lineCount;
        }
        
        if (precip_1hr_metric != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found precip_1hr_metric %@", wind_gust_kph);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation 1 hour:</b> %@ metric<br>", precip_1hr_metric];
            ++lineCount;
        }
        
        if (precip_today_string != nil) {
            if (verbose)
                NSLog(@"found precip_today_string %@", precip_today_string);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation Today:</b> %@<br>", precip_today_string];
            ++lineCount;
        }
        
        if (precip_today_in != nil && !excludeRedundant) {
            if (verbose)
                NSLog(@"found precip_today_in %@", precip_today_in);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation Today:</b> %@ inches<br>", precip_today_in];
            ++lineCount;
        }
        
        if (precip_today_metric != nil&& !excludeRedundant) {
            if (verbose)
                NSLog(@"found precip_today_metric %@", precip_today_metric);
            
            htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation Today:</b> %@ metric<br>", precip_today_metric];
            ++lineCount;
        }
        
        BOOL includeLinks = FALSE;
        
        if (includeLinks) {
            if (icon != nil) {
                if (verbose)
                    NSLog(@"found icon %@", icon);
                
                htmlText = [htmlText stringByAppendingFormat:@"<b>Icon:</b> %@<br>", icon];
                ++lineCount;
            }
            
            if (icon_url != nil) {
                if (verbose)
                    NSLog(@"found icon_url %@", icon_url);
                
                htmlText = [htmlText stringByAppendingFormat:@"<b>Icon:</b> <a href='%@'>Icon</a> <br>", icon_url];
                ++lineCount;
            }
            
            if (forecast_url != nil) {
                if (verbose)
                    NSLog(@"found forecast_url %@", forecast_url);
                
                htmlText = [htmlText stringByAppendingFormat:@"<b>Forecast:</b> <a href='%@'>Weather Forecast</a> <br>", forecast_url];
                ++lineCount;
            }
            
            if (history_url != nil) {
                if (verbose)
                    NSLog(@"found history_url %@", history_url);
                
                htmlText = [htmlText stringByAppendingFormat:@"<b>History:</b> <a href='%@'>Weather History</a><br>", history_url];
                ++lineCount;
            }
            
            if (ob_url != nil) {
                if (verbose)
                    NSLog(@"found ob_url %@", ob_url);
                
                htmlText = [htmlText stringByAppendingFormat:@"<b>Ob:</b> <a href='%@'>OB</a> <br>", ob_url];
                ++lineCount;
            }
        }
        
        if ([self isRunningIPad] == FALSE)
            lineCount += 5;
        //NSLog(@"html text is '%@ (%d lines)", htmlText, lineCount);
        
        // heaing label...
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 30)];
        if ([self isRunningIPad])
            label.layer.cornerRadius = 8;
        label.font = [UIFont boldSystemFontOfSize:20];
        label.backgroundColor = [UIColor blackColor];
        label.textColor = [UIColor whiteColor];
        if (title != nil && title.length > 0)
            label.text = title;
        else
            label.text = @"Current Weather";
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        
        // address label...
        labelAddress = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, frame.size.width, 20)];
        //labelAddress.layer.cornerRadius = 8;
        labelAddress.font = [UIFont systemFontOfSize:14];
        labelAddress.backgroundColor = [UIColor blackColor];
        labelAddress.textColor = [UIColor yellowColor];
        if (address != nil)
            labelAddress.text = [NSString stringWithFormat:@"%@", address];
        labelAddress.textAlignment = NSTextAlignmentCenter;
        [self addSubview:labelAddress];
        
        // add weather icon, if found...
        if (icon_url != nil) {
            NSURL * iconUrl = [NSURL URLWithString:icon_url];
            //NSLog(@"icon url is %@", icon_url);
            
            NSData * imageWeatherData = [NSData dataWithContentsOfURL:iconUrl];
            UIImage * imageWeather = [[UIImage alloc] initWithData:imageWeatherData];
            
            if (imageWeather != nil) {
                
                // save weather url
                if (forecast_url != nil)
                    weatherForecastUrl = [forecast_url copy];
                
                weatherButton = [UIButton buttonWithType:UIButtonTypeCustom];
                
                if ([self isRunningIPad])
                    weatherButton.frame = CGRectMake(frame.size.width - (frame.size.width * .30), 90, 50, 50);
                else
                    weatherButton.frame = CGRectMake(frame.size.width - (frame.size.width * .20), 130, 50, 50);
                [weatherButton setImage:imageWeather forState:UIControlStateNormal];
                [weatherButton addTarget:self action:@selector(showWeatherForecast) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:weatherButton];
            }
        }
        
        // close button...
        closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        closeButton.frame = CGRectMake(frame.size.width-25, 5, 20, 20);
        UIImageView * iconClose = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"new-close.png"]];
        [closeButton setImage:iconClose.image forState:UIControlStateNormal];
        //[iconClose release];
        [closeButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
        
        if (allowClosing) {
            //NSLog(@"allow closing...");
            [self addSubview:closeButton];
            [self bringSubviewToFront:closeButton];
        } else {
            //NSLog(@"no not allow closing...");
        }
        
        // share button...
        shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        shareButton.showsTouchWhenHighlighted = true;
        shareButton.frame = CGRectMake(4, 4, 20, 20);
        UIImageView * iconShare = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"new-share.png"]];
        [shareButton setImage:iconShare.image forState:UIControlStateNormal];
        [shareButton addTarget:self action:@selector(shareWeather) forControlEvents:UIControlEventTouchUpInside];
        
        if (allowSharing) {
            [self addSubview:shareButton];
            [self bringSubviewToFront:shareButton];
        }
        
        if (icon_url != nil) {
            NSURL * iconUrl = [NSURL URLWithString:icon_url];
            //NSLog(@"icon url is %@", icon_url);
            
            NSData * imageWeatherData = [NSData dataWithContentsOfURL:iconUrl];
            UIImage * imageWeather = [[UIImage alloc] initWithData:imageWeatherData];
            
            UIImageView * background = [[UIImageView alloc] initWithImage:imageWeather];
            background.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
            background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            background.contentMode = UIViewContentModeScaleToFill;
            background.alpha = 0.2;
            [self addSubview:background];
        }
        
        weatherLabel = [[MDHTMLLabel alloc] initWithFrame:CGRectMake(10, 60, frame.size.width - 45, frame.size.height - 60)];
        weatherLabel.linkAttributes = @{NSForegroundColorAttributeName: [UIColor blueColor],
                                        NSFontAttributeName: [UIFont boldSystemFontOfSize:weatherLabel.font.pointSize],
                                        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
        
        weatherLabel.activeLinkAttributes = @{NSForegroundColorAttributeName: [UIColor redColor],
                                              NSFontAttributeName: [UIFont boldSystemFontOfSize:weatherLabel.font.pointSize],
                                              NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
        
        weatherLabel.layer.cornerRadius = 8;
        weatherLabel.numberOfLines = lineCount;
        weatherLabel.shadowColor = [UIColor whiteColor];
        weatherLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        //weatherLabel.translatesAutoresizingMaskIntoConstraints = NO;
        //weatherLabel.backgroundColor = [UIColor greenColor];
        weatherLabel.delegate = self;
        weatherLabel.htmlText = htmlText;
        [scrollView addSubview:weatherLabel];
        
        [scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        
        //[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(resetPosition:) userInfo:nil repeats:NO];
        
    }
    return self;
}

// set the title
//
// NSString * title - the new title
- (void)setTitle:(NSString *)_title {
    
    if (_title != nil && _title.length > 0) {
        label.text = _title;
    }
}

// set the address and optionally refresh weather details...
//
// NSString * address - the new address
// NSString * displayAddress - the new address to display at top of weather view.  if nil, uses address
// BOOL refreshDetails -if TRUE, refresh address weather details also
// BOOL verbose - turn verbose mode on/off
- (void)setAddress:(NSString *)_address displayAddress:(NSString *)_displayAddress refreshDetails:(BOOL)refreshDetails verbose:(BOOL)verbose {
    
    if (_address != nil && _address.length > 0) {
        _address = [_address stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        address = [_address copy];
        
        if (_displayAddress == nil)
           labelAddress.text = address;
        else {
            _displayAddress = [_displayAddress stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
            labelAddress.text = _displayAddress;
        }
        
        if (refreshDetails) {
            NSLog(@"refreshing weather details for '%@'...", _address);
            
            NSMutableDictionary * _weatherDict = [UIWeatherView getLocationWeather:_address verbose:FALSE];
            current_observation = [_weatherDict mutableCopy];

            if (current_observation != nil && weatherSunrise != nil && weatherSunset != nil &&
                weatherPercentIlluminated != nil && weatherAgeOfMoon != nil) {
                
                htmlText = @"";
                
                NSMutableDictionary * _sunriseSunsetDict = [UIWeatherView getLocationSunriseSunset:_address verbose:FALSE];
                NSString * sunrise = [UIWeatherView getLocationSunriseFromDict:_sunriseSunsetDict];
                NSString * sunset = [UIWeatherView getLocationSunsetFromDict:_sunriseSunsetDict];
                NSString * percentIlluminated = [UIWeatherView getLocationMoonPercentIllumnatedFromDict:_sunriseSunsetDict];
                NSString * ageOfMoon = [UIWeatherView getLocationMoonAgeFromDict:_sunriseSunsetDict];
                int lineCount = 0;
                
                // create html from weather info...
                
                // Weather items
                NSString * _weather = [current_observation valueForKey:@"weather"];
                NSString * temperature_string = [current_observation valueForKey:@"temperature_string"];
                NSString * temp_f = [current_observation valueForKey:@"temp_f"];
                NSString * temp_c = [current_observation valueForKey:@"temp_c"];
                NSString * relative_humidity = [current_observation valueForKey:@"relative_humidity"];
                
                NSString * wind = [current_observation valueForKey:@"wind_string"];
                NSString * wind_dir = [current_observation valueForKey:@"wind_dir"];
                NSString * wind_degrees = [current_observation valueForKey:@"wind_degrees"];
                NSString * wind_mph = [current_observation valueForKey:@"wind_mph"];
                NSString * wind_gust_mph = [current_observation valueForKey:@"wind_gust_mph"];
                NSString * wind_kph = [current_observation valueForKey:@"wind_kph"];
                NSString * wind_gust_kph = [current_observation valueForKey:@"wind_gust_kph"];
                NSString * pressure_mb = [current_observation valueForKey:@"pressure_mb"];
                NSString * pressure_in = [current_observation valueForKey:@"pressure_in"];
                NSString * pressure_trend = [current_observation valueForKey:@"pressure_trend"];
                NSString * dewpoint_string = [current_observation valueForKey:@"dewpoint_string"];
                NSString * dewpoint_f = [current_observation valueForKey:@"dewpoint_f"];
                NSString * dewpoint_c = [current_observation valueForKey:@"dewpoint_c"];
                NSString * heat_index_string = [current_observation valueForKey:@"heat_index_string"];
                NSString * heat_index_f = [current_observation valueForKey:@"heat_index_f"];
                NSString * heat_index_c = [current_observation valueForKey:@"heat_index_c"];
                NSString * windchill_string = [current_observation valueForKey:@"windchill_string"];
                NSString * windchill_f = [current_observation valueForKey:@"windchill_f"];
                NSString * windchill_c = [current_observation valueForKey:@"windchill_c"];
                NSString * feelslike_string = [current_observation valueForKey:@"feelslike_string"];
                NSString * feelslike_f = [current_observation valueForKey:@"feelslike_f"];
                NSString * feelslike_c = [current_observation valueForKey:@"feelslike_c"];
                NSString * visibility_mi = [current_observation valueForKey:@"visibility_mi"];
                NSString * visibility_km = [current_observation valueForKey:@"visibility_km"];
                NSString * solar_radiation = [current_observation valueForKey:@"solar_radiation"];
                NSString * uv = [current_observation valueForKey:@"UV"];
                NSString * precip_1hr_string = [current_observation valueForKey:@"precip_1hr_string"];
                NSString * precip_1hr_in = [current_observation valueForKey:@"precip_1hr_in"];
                NSString * precip_1hr_metric = [current_observation valueForKey:@"precip_1hr_metric"];
                NSString * precip_today_string = [current_observation valueForKey:@"precip_today_string"];
                NSString * precip_today_in = [current_observation valueForKey:@"precip_today_in"];
                NSString * precip_today_metric = [current_observation valueForKey:@"precip_today_metric"];
                NSString * icon = [current_observation valueForKey:@"icon"];
                NSString * icon_url = [current_observation valueForKey:@"icon_url"];
                NSString * forecast_url = [current_observation valueForKey:@"forecast_url"];
                NSString * history_url = [current_observation valueForKey:@"history_url"];
                NSString * ob_url = [current_observation valueForKey:@"ob_url"];
                
                BOOL excludeRedundant = TRUE;
                NSString * sunriseSunsetStr = nil;
                
                if (_weather != nil) {
                    if (verbose)
                        NSLog(@"found weather of %@", _weather);
                    
                    if (sunrise != nil && sunset != nil) {
                        if (verbose)
                            NSLog(@"Sunrise %@ Sunset %@", sunrise, sunset);
                        
                        sunriseSunsetStr = [NSString stringWithFormat:@"<br><b>Sunrise:</b> %@<br><b>Sunset:</b> %@", sunrise, sunset];
                    }
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Weather:</b> %@  <br><a href='%@'>forecast</a>  <a href='%@'>history</a>            %@<br>", _weather, forecast_url, history_url, sunriseSunsetStr];
                    lineCount += 4;
                }
                
                if (percentIlluminated != nil && ageOfMoon != nil) {
                    NSString * fullMoonStr = @"";
                    //percentIlluminated = @"100%";  // test
                    
                    if ([percentIlluminated isEqualToString:@"100%"])
                        fullMoonStr = @"(full moon)";
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Moon Illumination:</b> %@ %@<br><b>Moon Age:</b> %@<br>", percentIlluminated, fullMoonStr, ageOfMoon];
                    lineCount += 2;
                }
                
                if (temperature_string != nil) {
                    if (verbose)
                        NSLog(@"found temperature_string of %@", temperature_string);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Temperature:</b> %@<br>", temperature_string];
                    ++lineCount;
                }
                
                if (windchill_string != nil) {
                    if (verbose)
                        NSLog(@"found windchill_string %@", windchill_string);
                    
                    windchill_string = [windchill_string stringByReplacingOccurrencesOfString:@"NA" withString:@"n/a"];
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Windchill:</b> %@<br>", windchill_string];
                    ++lineCount;
                }
                
                if (temp_f != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found temp_f of %@", temp_f);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Temperature:</b> %@ F<br>", temp_f];
                    ++lineCount;
                }
                
                if (temp_c != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found temp_c of %@", temp_c);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Temperature:</b> %@ C<br>", temp_c];
                    ++lineCount;
                }
                
                if (relative_humidity != nil) {
                    if (verbose)
                        NSLog(@"found relative_humidity of %@", relative_humidity);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Relative Humidity:</b> %@<br>", relative_humidity];
                    ++lineCount;
                }
                
                if (wind != nil) {
                    if (verbose)
                        NSLog(@"found wind %@", wind);
                    
                    wind = [wind stringByReplacingOccurrencesOfString:@"MPH" withString:@"mph"];
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Wind:</b> %@<br>", wind];
                    ++lineCount;
                }
                
                if (wind_dir!= nil) {
                    if (verbose)
                        NSLog(@"found win_dir %@", wind_dir);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Wind Direction:</b> %@<br>", wind_dir];
                    ++lineCount;
                }
                
                if (wind_degrees != nil) {
                    if (verbose)
                        NSLog(@"found wind_degrees %@", wind_degrees);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Wind Degrees:</b> %@<br>", wind_degrees];
                    ++lineCount;
                }
                
                if (wind_mph != nil && wind_kph != nil) {
                    if (verbose)
                        NSLog(@"found wind_mph %@", wind_mph);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Wind:</b> %@ mph (%@ kph)<br>", wind_mph, wind_kph];
                    ++lineCount;
                }
                
                if (wind_gust_mph != nil && wind_gust_kph != nil) {
                    if (verbose)
                        NSLog(@"found wind_gust_mph %@", wind_gust_mph);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Wind Gust:</b> %@ mph (%@ kph)<br>", wind_gust_mph, wind_gust_kph];
                    ++lineCount;
                }
                
                if (wind_kph != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found wind_kph %@", wind_kph);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Wind:</b> %@ kph<br>", wind_kph];
                    ++lineCount;
                }
                
                if (wind_gust_kph != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found wind_gust_kph %@", wind_gust_kph);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Wind Gust:</b> %@ kph<br>", wind_gust_kph];
                    ++lineCount;
                }
                
                if (pressure_mb != nil && pressure_in) {
                    if (verbose)
                        NSLog(@"found pressure_mb %@", pressure_mb);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Pressure:</b> %@ millibars (%@ inches)<br>", pressure_mb, pressure_in];
                    ++lineCount;
                }
                
                if (pressure_in != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found presure_in %@", pressure_in);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Pressure:</b> %@ inches<br>", pressure_in];
                    ++lineCount;
                }
                
                if (pressure_trend != nil) {
                    if (verbose)
                        NSLog(@"found wpresure_trend %@", pressure_trend);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Pressure Trend:</b> %@<br>", pressure_trend];
                    ++lineCount;
                }
                
                if (dewpoint_string != nil) {
                    if (verbose)
                        NSLog(@"found dewpoint_string %@", dewpoint_string);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Dewpoint:</b> %@<br>", dewpoint_string];
                    ++lineCount;
                }
                
                if (dewpoint_f != nil && dewpoint_c != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found dewpoint_f %@", dewpoint_f);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Dewpoint:</b> %@ F (%@ C)<br>", dewpoint_f, dewpoint_c];
                    ++lineCount;
                }
                
                if (dewpoint_c != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found dewpoint_c %@", dewpoint_c);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Dewpoint:</b> %@ C<br>", dewpoint_c];
                    ++lineCount;
                }
                
                if (heat_index_string != nil) {
                    if (verbose)
                        NSLog(@"found heat_index_string %@", heat_index_string);
                    
                    heat_index_string = [heat_index_string stringByReplacingOccurrencesOfString:@"NA" withString:@"n/a"];
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Heat Index:</b> %@<br>", heat_index_string];
                    ++lineCount;
                }
                
                if (heat_index_f != nil && heat_index_c != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found heat_index_f %@", heat_index_f);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Heat Index:</b> %@ F (%@ C)<br>", heat_index_f, heat_index_c];
                    ++lineCount;
                }
                
                if (heat_index_c != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found heat_index_c %@", heat_index_c);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Heat Index:</b> %@ C<br>", heat_index_c];
                    ++lineCount;
                }
                
                if (windchill_f != nil && windchill_c != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found windchill_f %@", windchill_f);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Windchill:</b> %@ F (%@ C)<br>", windchill_f, windchill_c];
                    ++lineCount;
                }
                
                if (windchill_c != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found windchill_c %@", windchill_c);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Windchill:</b> %@ C<br>", windchill_c];
                    ++lineCount;
                }
                
                if (feelslike_string != nil) {
                    if (verbose)
                        NSLog(@"found feelslike_string %@", feelslike_string);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Feels Like:</b> %@<br>", feelslike_string];
                    ++lineCount;
                }
                
                if (feelslike_f != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found feelslike_f %@", feelslike_f);
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Feels Like:</b> %@ F<br>", feelslike_f];
                    ++lineCount;
                }
                
                if (feelslike_c != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found feelslike_c %@", feelslike_c);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Feels Like:</b> %@ C<br>", feelslike_c];
                    ++lineCount;
                }
                
                if (visibility_mi != nil && visibility_km != nil) {
                    if (verbose)
                        NSLog(@"found visibility_mi %@", visibility_mi);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Visibility:</b> %@ miles (%@ km)<br>", visibility_mi, visibility_km];
                    ++lineCount;
                }
                
                if (visibility_km != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found visibility_km %@", visibility_km);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Visiblity:</b> %@ km<br>", visibility_km];
                    ++lineCount;
                }
                
                if (solar_radiation != nil) {
                    if (verbose)
                        NSLog(@"found colar_radiation %@", solar_radiation);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Solar Radiation</b> %@<br>", solar_radiation];
                    ++lineCount;
                }
                
                if (uv != nil) {
                    if (verbose)
                        NSLog(@"found UV %@", uv);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>UV:</b> %@<br>", uv];
                    ++lineCount;
                }
                
                if (precip_1hr_string != nil) {
                    if (verbose)
                        NSLog(@"found precip_1hr_string %@", precip_1hr_string);
                    
                    // make -999.00 no report value a 0...
                    precip_1hr_string = [precip_1hr_string stringByReplacingOccurrencesOfString:@"-999.00" withString:@"0"];
                    precip_1hr_string = [precip_1hr_string stringByReplacingOccurrencesOfString:@"( " withString:@"("];
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation 1 hour:</b> %@<br>", precip_1hr_string];
                    ++lineCount;
                }
                
                if (precip_1hr_in != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found precip_1hr_in %@", precip_1hr_in);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation 1 hour:</b> %@ inches<br>", precip_1hr_in];
                    ++lineCount;
                }
                
                if (precip_1hr_metric != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found precip_1hr_metric %@", wind_gust_kph);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation 1 hour:</b> %@ metric<br>", precip_1hr_metric];
                    ++lineCount;
                }
                
                if (precip_today_string != nil) {
                    if (verbose)
                        NSLog(@"found precip_today_string %@", precip_today_string);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation Today:</b> %@<br>", precip_today_string];
                    ++lineCount;
                }
                
                if (precip_today_in != nil && !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found precip_today_in %@", precip_today_in);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation Today:</b> %@ inches<br>", precip_today_in];
                    ++lineCount;
                }
                
                if (precip_today_metric != nil&& !excludeRedundant) {
                    if (verbose)
                        NSLog(@"found precip_today_metric %@", precip_today_metric);
                    
                    htmlText = [htmlText stringByAppendingFormat:@"<b>Precipitation Today:</b> %@ metric<br>", precip_today_metric];
                    ++lineCount;
                }
                
                BOOL includeLinks = FALSE;
                
                if (includeLinks) {
                    if (icon != nil) {
                        if (verbose)
                            NSLog(@"found icon %@", icon);
                        
                        htmlText = [htmlText stringByAppendingFormat:@"<b>Icon:</b> %@<br>", icon];
                        ++lineCount;
                    }
                    
                    if (icon_url != nil) {
                        if (verbose)
                            NSLog(@"found icon_url %@", icon_url);
                        
                        htmlText = [htmlText stringByAppendingFormat:@"<b>Icon:</b> <a href='%@'>Icon</a> <br>", icon_url];
                        ++lineCount;
                    }
                    
                    if (forecast_url != nil) {
                        if (verbose)
                            NSLog(@"found forecast_url %@", forecast_url);
                        
                        htmlText = [htmlText stringByAppendingFormat:@"<b>Forecast:</b> <a href='%@'>Weather Forecast</a> <br>", forecast_url];
                        ++lineCount;
                    }
                    
                    if (history_url != nil) {
                        if (verbose)
                            NSLog(@"found history_url %@", history_url);
                        
                        htmlText = [htmlText stringByAppendingFormat:@"<b>History:</b> <a href='%@'>Weather History</a><br>", history_url];
                        ++lineCount;
                    }
                    
                    if (ob_url != nil) {
                        if (verbose)
                            NSLog(@"found ob_url %@", ob_url);
                        
                        htmlText = [htmlText stringByAppendingFormat:@"<b>Ob:</b> <a href='%@'>OB</a> <br>", ob_url];
                        ++lineCount;
                    }
                }

                if (verbose)
                    NSLog(@"setting weather details for '%@'...", _address);
                
                weatherLabel.htmlText = htmlText;
                
                // add weather icon, if found...
                if (icon_url != nil) {
                    NSURL * iconUrl = [NSURL URLWithString:icon_url];
                    //NSLog(@"icon url is %@", icon_url);
                    
                    NSData * imageWeatherData = [NSData dataWithContentsOfURL:iconUrl];
                    UIImage * imageWeather = [[UIImage alloc] initWithData:imageWeatherData];
                    
                    if (imageWeather != nil) {
                        
                        // save weather url
                        if (forecast_url != nil)
                            weatherForecastUrl = [forecast_url copy];
                        
                        if (weatherButton != nil)
                            [weatherButton setImage:imageWeather forState:UIControlStateNormal];
                    }
                }

            }
        }
    }
}

// Show the weather forecast for the current weather
//
// can be called after using constructor and will show show Wunderground.com
// weather forecast in your browser for the location you used in constructor
- (void)showWeatherForecast {
    
    //NSLog(@"show weather...");
    
    NSURL * url = [NSURL URLWithString:weatherForecastUrl];
    [[UIApplication sharedApplication] openURL: url];
}

// share weather details for the current weather
- (void)shareWeather {
    
    if (htmlText == nil) {
        NSLog(@"the weather details in htmlText have not been set yet!");
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Show Weather Notice" message:@"Weather is currently not available for this address!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        return;
        
    } else if (parent == nil) {
        NSLog(@"parent view controller not set so can not use sharing!");
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Show Weather Notice" message:@"Sharing not enabled since Weather View parent view controller is not set!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }
    
    NSString * textWithNoHTML = [htmlText copy];
    
    // removeHTML markup...
    textWithNoHTML = [textWithNoHTML stringByReplacingOccurrencesOfString:@"<b>" withString:@""];
    textWithNoHTML = [textWithNoHTML stringByReplacingOccurrencesOfString:@"</b>" withString:@""];
    textWithNoHTML = [textWithNoHTML stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    textWithNoHTML = [textWithNoHTML stringByReplacingOccurrencesOfString:@"<a href='" withString:@""];
    textWithNoHTML = [textWithNoHTML stringByReplacingOccurrencesOfString:@"'>" withString:@""];
    textWithNoHTML = [textWithNoHTML stringByReplacingOccurrencesOfString:@"</a>" withString:@""];
    textWithNoHTML = [textWithNoHTML stringByReplacingOccurrencesOfString:@"forecast" withString:@" (forecast) "];
    textWithNoHTML = [textWithNoHTML stringByReplacingOccurrencesOfString:@"history" withString:@" (history) "];
    
    if (address == nil) {
        address = [UIWeatherView getCurrentAddress];
    }
    
    NSString * heading = [NSString stringWithFormat:@"Current Weather for %@", address];
    NSString * shareMsg = [NSString stringWithFormat:@"%@\n%@", heading, textWithNoHTML];
    
    //NSLog(@"text with no HTML is '%@'", shareMsg);
    
    NSArray * postItems = @[shareMsg];
    
    UIActivityViewController * activityController = [[UIActivityViewController alloc] initWithActivityItems:postItems applicationActivities:nil];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        activityController.popoverPresentationController.sourceView = shareButton;
    }
    
    if (parent != nil)
        [parent presentViewController:activityController animated:YES completion:nil];
}

// resize weather view
//
// CGRect frame - new frame
- (void)resizeView:(CGRect)frame {
    
    self.frame = frame;
    scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    label.frame = CGRectMake(0, 0, self.frame.size.width, 30);
    labelAddress.frame = CGRectMake(0, 22, self.frame.size.width, 38);
    
    if (iconImageView != nil)
        iconImageView.frame = CGRectMake(self.frame.size.width - (self.frame.size.width * .30), 60, 50, 50);
    
    if (weatherButton != nil) {
        if ([self isRunningIPad])
            weatherButton.frame = CGRectMake(self.frame.size.width - (self.frame.size.width * .30), 90, 50, 50);
        else
            weatherButton.frame = CGRectMake(self.frame.size.width - (self.frame.size.width * .20), 130, 50, 50);
    }
    
    closeButton.frame = CGRectMake(self.frame.size.width-25, 5, 20, 20);
    shareButton.frame = CGRectMake(4, 4, 20, 20);
    //weatherLabel.frame = CGRectMake(10, 60, self.frame.size.width - 45, self.frame.size.height - 60);
}

// close the weather view
- (void)closeView {
    
    [self removeFromSuperview];
}

// see if running on iPad
//
// return BOOL - TRUE if running on iPad
- (BOOL)isRunningIPad {
    BOOL result = FALSE;
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)]) {
        //NSLog(@"Is running iPad");
        result = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
    } else {
        //NSLog(@"Is running iPad");
    }
    
    return result;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading {
    
    //NSLog(@"heading changed...");
    
    id<LocationUtilsDelegate> _locationDelegate = [UIWeatherView getLocationDelegate];
    
    if (_locationDelegate != nil && monitorLocation)
        [_locationDelegate locationManager:manager didUpdateHeading:heading];
    
    NSString * directionStr = @"Not Available";
    int accuracy = [heading headingAccuracy];
    
    if (accuracy > 0) {
        CLLocationDirection direction = heading.trueHeading;
        //NSLog(@"true heading: %.f", direction);
        //CLLocationDirection direction2 = heading.magneticHeading;
        //NSLog(@"megnetic heading: %.f", direction2);
        
        if (direction == 0)
            directionStr = @"North";
        else if (direction == 90)
            directionStr = @"East";
        else if (direction == 180)
            directionStr = @"South";
        else if (direction == 270)
            directionStr = @"West";
        else if (direction > 0 && direction < 90)
            directionStr = @"Northeast";
        else if  (direction > 90 && direction < 180)
            directionStr = @"Southeast";
        else if (direction > 180 && direction < 270)
            directionStr = @"Southwest";
        else if (direction > 270)
            directionStr = @"Northwest";
    } else {
        directionStr = @"Not Available";
    }

    currentHeadingAccuracy = accuracy;
    currentHeading = [directionStr copy];
    
    //NSLog(@"Current Heading %@.", currentHeading);
    //NSLog(@"Current Heading Accuracy is %d.", currentHeadingAccuracy);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)fromLocation {
    
    //NSLog(@"location changed...");
}

- (void)currentAddressChanged:(CLLocation *)currentLocation currentAddress:(NSString *)_currentAddress oldAddress:(NSString *)oldAddress cityState:(NSString *)cityState {
    
    //NSLog(@"current address changed...");
    
    if (_currentAddress != nil && _currentAddress.length > 0) {
        currentAddress = [_currentAddress copy];
        //NSLog(@"address changed to '%@'", currentAddress);
        currentCityStateAddress = [cityState copy];
        //NSLog(@"address cityState changed to '%@'", currentCityStateAddress);
        
        id<LocationUtilsDelegate> _locationDelegate = [UIWeatherView getLocationDelegate];
        
        if (_locationDelegate != nil && monitorLocation) {
            //NSLog(@"Monitoring of location updates is ON");
            [_locationDelegate currentAddressChanged:currentLocation currentAddress:_currentAddress oldAddress:oldAddress cityState:cityState];
        } else if (!monitorLocation) {
            //NSLog(@"Monitoring of location updates is OFF!");
        }
    }
}

- (void)resetPosition:(NSTimer *)timer {
    
    //NSLog(@"reset position...");
    [scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)view {
    
    //NSLog(@"scroll view did scroll...");
    
    [weatherLabel setNeedsDisplay];
}

- (void)HTMLLabel:(MDHTMLLabel *)label didSelectLinkWithURL:(NSURL *)url {
    
    //NSLog(@"did select %@ so launch browser...", url);
    
    [[UIApplication sharedApplication] openURL: url];
}

- (void)HTMLLabel:(MDHTMLLabel *)label didHoldLinkWithURL:(NSURL *)url {
    
    //NSLog(@"did hold %@", url);
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code.
 }
 */

- (void)dealloc {
    
    //[super dealloc];
}

@end
