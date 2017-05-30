//
//  ViewController.h
//  Under The Weather
//
//  Created by Diorgo Jonkers on 2017/05/29.
//  Copyright © 2017 Diorgo. All rights reserved.
//

#import <UIKit/UIKit.h>

// App states
typedef NS_ENUM(NSInteger, AppStates) {
    AppStateInit,
    AppStateGettingLocation,
    AppStateGettingWeather,
    AppStateGettingCountryName,
    AppStateIdle,
    AppStateError
};


@interface ViewController : UIViewController


// Methods
- (void)getLocation;
-(void)getWeather;
- (void)getCountryName;
-(void)setState:(AppStates)newState;
-(void)setState:(AppStates)newState optionalErrorMsg:(NSString *)errorMsg;
-(void)updateControls;
-(void)updateControls:(bool)firstTime;


// UI elements

@property (weak, nonatomic) IBOutlet UIStackView *mainCentreView;

@property (weak, nonatomic) IBOutlet UIView *loadingView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@property (weak, nonatomic) IBOutlet UIView *infoView;

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UIImageView *weatherIconImage;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *temparatureLabel;

@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@property (weak, nonatomic) IBOutlet UILabel *errorLabel;


@end

