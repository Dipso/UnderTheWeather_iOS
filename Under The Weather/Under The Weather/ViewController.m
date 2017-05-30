//
//  ViewController.m
//  Under The Weather
//
//  Created by Diorgo Jonkers on 2017/05/29.
//  Copyright © 2017 Diorgo. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>


@interface ViewController ()<CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *LocationManager;
@end


// Const
//------
// Default latitude and longitude to test in XCode simulator (simulator can not detect the device location)
#define kDefaultLatitude -33.310629f
#define kDefaultLongitude 26.525595f

#define kTimerIntervals	0.1f		// Timer intervals to update controls


@implementation ViewController
{
	AppStates state;			// App state
	
	float latitude;				// Detected latitude
	float longitude;			// Detected longitude
	
	NSString *countryCode;		// Country 2-char code
	NSString* countryName;		// Country name
	NSString *cityName;			// City name
	NSString* tempMin;			// Min temperature
	NSString* tempMax;			// Max temperature
	NSString* description;		// Weather description
	NSString* icon;				// Icon name
	NSString* lastErrorMsg;		// Last received error message
	
	BOOL didSetIcon;			// Did set weather icon?
	
	NSTimer *timer;				// Timer for updating UI controls
	AppStates timerLastState;	// Last state when controls were updated
}


@synthesize LocationManager;


// Methods
//--------

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
	
	latitude = kDefaultLatitude;
	longitude = kDefaultLongitude;
	
	[self updateControls:true];
	

	// First get the device's location
	[self setState:AppStateGettingLocation];
	
	// Update UI controls via a timer tick method. (There are errors when trying to update them from the www callbacks.)
	[self startTimer];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Set the weather icon
-(void)setIcon
{
	if (self.weatherIconImage == nil)
	{
		return;
	}
	
	UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", icon]];
	if (img != nil)
	{
		[self.weatherIconImage setImage:img];
		didSetIcon = YES;
	}
}


-(void)startTimer
{
	if (timer != nil)
	{
		return;
	}
	
	timer = [NSTimer scheduledTimerWithTimeInterval: kTimerIntervals
											 target: self
										   selector:@selector(onTick:)
										   userInfo: nil repeats:YES];
	if (timer != nil)
	{
		NSRunLoop *runner = [NSRunLoop currentRunLoop];
		[runner addTimer: timer forMode: NSDefaultRunLoopMode];
	}
}


-(void) stopTimer
{
	if (timer != nil)
	{
		[timer invalidate];
		timer = nil;
	}
}


// Timer update tick.
-(void)onTick:(NSTimer *)timer
{
	if (timerLastState != state)
	{
		timerLastState = state;
		[self updateControls];
		
		// App is done, no need to update anymore
		if (state == AppStateIdle)
		{
			[self stopTimer];
		}
	}
}



// Get the device location
-(void)getLocation
{
	NSLog(@"Getting location...");
	
	// Init location
	LocationManager = [[CLLocationManager alloc] init];
	LocationManager.delegate = self;
	LocationManager.distanceFilter = kCLDistanceFilterNone;
	LocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
	
	if ([[[UIDevice currentDevice]systemVersion ] floatValue]>=8.0) {
		[LocationManager  requestAlwaysAuthorization];
	}
	
	[LocationManager startUpdatingLocation];
	
	NSLog(@"Waiting for location...");
}


// Delegate for location manager.
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	NSLog(@"Latitude: %f", LocationManager.location.coordinate.latitude);
	NSLog(@"Logitude: %f", LocationManager.location.coordinate.longitude);
	
	latitude = LocationManager.location.coordinate.latitude;
	longitude = LocationManager.location.coordinate.longitude;
	
	[LocationManager stopUpdatingLocation];
	
	// Get the weather
	[self setState:AppStateGettingWeather];
}


// Delegate for location manager.
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"Location Failed. Error: %@", error);
	
	#if TARGET_IPHONE_SIMULATOR
	// Simulator: Failed to get the location, but test the weather with the default locations
	[self setState:AppStateError optionalErrorMsg:@"Location failed."];		// First show location error
	[self setState:AppStateGettingWeather];
	#endif
}



// Get the weather
-(void)getWeather
{
	NSLog(@"Getting weather...");
	
	NSString *urlAsString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&type=accurate&mode=json&units=metric&lang=en&appid=ecf9a5ac6225dc979690064f9b8c10cb", latitude, longitude];
	
	NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
	NSString *encodedUrlAsString = [urlAsString stringByAddingPercentEncodingWithAllowedCharacters:set];
	
	NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	
	[[session dataTaskWithURL:[NSURL URLWithString:encodedUrlAsString]
			completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
	  {
		  //NSLog(@"RESPONSE: %@",response);
		  //NSLog(@"DATA: %@",data);
		  
		  // If errorMsg is set then the app state will change to AppStateError
		  NSString* errorMsg = nil;
		  
		  if (!error)
		  {
			  // Success
			  if ([response isKindOfClass:[NSHTTPURLResponse class]])
			  {
				  NSError *jsonError;
				  NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
				  
				  if (jsonError)
				  {
					  // Error Parsing JSON
					  NSLog(@"Error Parsing JSON");
					  
					  errorMsg = @"Error Parsing JSON";
				  }
				  else
				  {
					  // Success Parsing JSON
					  // Log NSDictionary response:
					  NSLog(@"JSON:");
					  NSLog(@"%@", jsonResponse);
					  
					  @try
					  {
						  NSLog(@"");
						  NSLog(@"RESULTS:");
						  
						  cityName = jsonResponse[@"name"];
						  NSLog(@"name: %@", cityName);
						  
						  
						  NSDictionary *sys = jsonResponse[@"sys"];
						  if (sys != nil)
						  {
							  countryCode = sys[@"country"];
							  NSLog(@"country: %@", countryCode);
						  }
						  
						  
						  NSDictionary *main = jsonResponse[@"main"];
						  if (main != nil)
						  {
							  tempMin = main[@"temp_min"];
							  NSLog(@"tempMin: %@", tempMin);
							  
							  tempMax = main[@"temp_max"];
							  NSLog(@"tempMax: %@", tempMax);
						  }
						  
						  
						  NSArray *weather = jsonResponse[@"weather"];
						  if (weather != nil)
						  {
							  NSDictionary *firstObjectDict = [weather objectAtIndex:0];
							  if (firstObjectDict != nil)
							  {
								  description = firstObjectDict[@"description"];
								  NSLog(@"description: %@", description);
								  
								  icon = firstObjectDict[@"icon"];
								  NSLog(@"icon: %@", icon);
							  }
						  }
						  
						  
						  if (countryCode != nil)
						  {
							  // Try to get the country name
							  [self setState:AppStateGettingCountryName];
						  }
						  else
						  {
							  // Could not get the country code, but show weather results
							  [self setState:AppStateIdle];
						  }
					  }
					  @catch (NSException *exception)
					  {
						  // Error Parsing JSON
						  NSLog(@"Error Parsing JSON. Exception: %@", exception.reason);
						  
						  errorMsg = @"Error Parsing JSON";
					  }
				  }
			  }
			  else
			  {
				  //Web server is returning an error
				  NSLog(@"Web server is returning an error");
				  
				  errorMsg = @"Web server is returning an error.";
			  }
		  }
		  else
		  {
			  // Fail
			  NSLog(@"Web error : %@", error.description);
			  
			  errorMsg = [NSString stringWithFormat:@"Web error: %@", error.localizedDescription];
		  }
		  
		  if (errorMsg != nil)
		  {
			  [self setState:AppStateError optionalErrorMsg:errorMsg];
		  }
		  
	  }] resume];
	
	
	NSLog(@"Waiting for weather...");
}


// Get the country name, from the 2-char code.
- (void)getCountryName
{
	NSLog(@"Getting country name...");
	
	NSString *urlAsString = @"http://country.io/names.json";
	
	NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
	NSString *encodedUrlAsString = [urlAsString stringByAddingPercentEncodingWithAllowedCharacters:set];
	
	NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	
	[[session dataTaskWithURL:[NSURL URLWithString:encodedUrlAsString]
			completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
	{
		//NSLog(@"RESPONSE: %@",response);
		//NSLog(@"DATA: %@",data);
		
		if (!error)
		{
			// Success
			if ([response isKindOfClass:[NSHTTPURLResponse class]])
			{
				NSError *jsonError;
				NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
				
				if (jsonError)
				{
					// Error Parsing JSON
					NSLog(@"Error Parsing JSON");
				}
				else
				{
					// Success Parsing JSON
					// Log NSDictionary response:
					//NSLog(@"JSON:");
					//NSLog(@"%@", jsonResponse);
					
					@try
					{
						NSLog(@"");
						NSLog(@"RESULTS:");
						
						countryName = jsonResponse[countryCode];
						NSLog(@"countryName: %@", countryName);
					}
					@catch (NSException *exception)
					{
						// Error Parsing JSON
						NSLog(@"Error Parsing JSON. Exception: %@", exception.reason);
					}
				}
			}
			else
			{
				//Web server is returning an error
				NSLog(@"Web server is returning an error");
			}
		}
		else
		{
			// Fail
			NSLog(@"Web error : %@", error.description);
		}
		
		
		// Show weather results, even if we did Not get the country name.
		[self setState:AppStateIdle];
		
	}] resume];

	
	NSLog(@"Waiting for country name...");
}


// Set the app state
-(void)setState:(AppStates)newState
{
	[self setState:newState optionalErrorMsg:nil];
}


// Set the app state
-(void)setState:(AppStates)newState optionalErrorMsg:(NSString *)errorMsg
{
	NSLog(@"\n");
	if (errorMsg == nil)
	{
		NSLog(@"SetState: %ld", (long)newState);
	}
	else
	{
		NSLog(@"SetState: %ld     error: %@", (long)newState, errorMsg);
	}
	
	
	state = newState;
	
	switch (state)
	{
		case AppStateGettingLocation:
		{
			[self getLocation];
			break;
		}
		case AppStateGettingWeather:
		{
			[self getWeather];
			break;
		}
		case AppStateGettingCountryName:
		{
			[self getCountryName];
			break;
		}
		case AppStateError:
		{
			// TODO: Update UI error message
			break;
		}
			
		default:
			break;
	} //switch
	
	
	if (errorMsg != nil)
	{
		lastErrorMsg = errorMsg;
	}
	
}


// Update the UI controls
-(void)updateControls
{
	[self updateControls:false];
}


// Update the UI controls
-(void)updateControls:(bool)firstTime
{
	BOOL visible;
	
	if (firstTime)
	{
		// Initialise some controls
		
		// Animate the spinner
		if (self.loadingIndicator != nil)
		{
			[self.loadingIndicator startAnimating];
		}
		
		if (self.loadingView != nil)
		{
			self.loadingView.hidden = NO;
		}
		
		if (self.infoView != nil)
		{
			self.infoView.hidden = YES;
		}
		
		
		// Clear labels
		if (self.dateLabel != nil)
		{
			[self.dateLabel setText:@""];
		}
		
		if (self.descriptionLabel != nil)
		{
			[self.descriptionLabel setText:@""];
		}
		
		if (self.temparatureLabel != nil)
		{
			[self.temparatureLabel setText:@""];
		}
		
		if (self.locationLabel != nil)
		{
			[self.locationLabel setText:@""];
		}
		
		if (self.errorLabel != nil)
		{
			[self.errorLabel setText:@""];
		}
	}
	else
	{
		// Show/hide the loading icon
		if ((state == AppStateGettingLocation) || (state == AppStateGettingWeather) ||
			(state == AppStateGettingCountryName))
		{
			visible = YES;
		}
		else
		{
			visible = NO;
		}
		
		if ((self.loadingView != nil) && (self.loadingView.hidden != !visible))
		{
			if (self.loadingIndicator != nil)
			{
				if (visible)
				{
					[self.loadingIndicator startAnimating];
				}
				else
				{
					[self.loadingIndicator stopAnimating];
				}
			}
			
			self.loadingView.hidden = !visible;
		}
		
		
		// Show/hide weather info
		visible = (state == AppStateIdle);
		if ((self.infoView != nil) && (self.infoView.hidden != !visible))
		{
			self.infoView.hidden = !visible;
		}
		
		
		if ((self.errorLabel != nil) && (lastErrorMsg != nil))
		{
			[self.errorLabel setText:lastErrorMsg];
		}
		
		
		if (state == AppStateIdle)
		{
			if (self.locationLabel != nil)
			{
				if ((cityName != nil) && (countryName != nil))
				{
					[self.locationLabel setText:[NSString stringWithFormat:@"%@, %@", cityName, countryName]];
				}
				else if (cityName!= nil)
				{
					[self.locationLabel setText:cityName];
				}
			}
			
			if ((self.temparatureLabel != nil) && (tempMin != nil) && (tempMax != nil))
			{
				[self.temparatureLabel setText:[NSString stringWithFormat:@"min %@    max %@",
												[self formatTemperature:tempMin],
												[self formatTemperature:tempMax]]];
			}
			
			if ((self.descriptionLabel != nil) && (description != nil))
			{
				[self.descriptionLabel setText:[self capitalizedFirstLetter:description]];
			}
			
			if ((didSetIcon == NO) && (icon != nil))
			{
				[self setIcon];
			}
		}
	}
	
	
	// Set the date
	if (self.dateLabel != nil)
	{
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"d MMM yyyy";
		NSString *dateString = [formatter stringFromDate:[NSDate date]];
		[self.dateLabel setText:[NSString stringWithFormat:@"Today, %@", dateString]];
	}
	
}



- (NSString *) capitalizedFirstLetter:(NSString *)str
{
	if (str == nil)
	{
		return (nil);
	}
	
	NSString *firstCapChar = [[str substringToIndex:1] capitalizedString];
	NSString *cappedString = [str stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:firstCapChar];
	
	return (cappedString);
}


// Formats the temperature string
- (NSString *) formatTemperature:(NSString *) temperature
{
	@try
	{
		float number = [temperature floatValue];
		// Round off
		number = lroundf(number);
		return ([NSString stringWithFormat:@"%d° C", (int)number]);
	}
	@catch (NSException *exception)
	{
		return ([NSString stringWithFormat:@"%@° C", temperature]);
	}
	
}

@end
