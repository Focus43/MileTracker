//
//  MTTabBarControllerViewController.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/30/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import "MTTabBarController.h"
#import "Reachability.h"
#import "MTSignUpViewController.h"
#import "MTLoginViewController.h"

@interface MTTabBarController ()

@property (nonatomic, strong)ADBannerView *banner;
@property (nonatomic,assign) BOOL bannerIsVisible;

@end

@implementation MTTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Add ad banner
    _banner = [[ADBannerView alloc] init];
    _banner.delegate = self;
    _banner.frame = CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height - 49, _banner.frame.size.width, _banner.frame.size.height);
    _banner.requiredContentSizeIdentifiers = [NSSet setWithObjects: ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil];
    [_banner setBackgroundColor:[MTViewUtils backGroundColor]];
    
    [self.view insertSubview:_banner belowSubview:self.tabBar];
   
    self.bannerIsVisible = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGFloat dy;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        
        _banner.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
        
        int orientationDiff = orientation - toInterfaceOrientation;
        
        if ( (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) && (abs(orientationDiff) == 1) ) {
                dy = 0;
        } else {
            
            if ( [[UIDevice currentDevice].model isEqualToString:@"iPhone"] ) {
                dy = -([UIScreen mainScreen].bounds.size.height - [UIScreen mainScreen].bounds.size.width - 18);
            } else {
                dy = -([UIScreen mainScreen].bounds.size.height - [UIScreen mainScreen].bounds.size.width);
            }

        }
        
    } else {
        
        _banner.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        
        if ( [[UIDevice currentDevice].model isEqualToString:@"iPhone"] ) {
            dy = [UIScreen mainScreen].bounds.size.height - [UIScreen mainScreen].bounds.size.width - 18;
        } else {
            dy = [UIScreen mainScreen].bounds.size.height - [UIScreen mainScreen].bounds.size.width;
        }
        
    }
    
    _banner.frame = CGRectOffset(_banner.frame, 0.0, dy);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -- Advertising Delegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!self.bannerIsVisible) {
        [UIView animateWithDuration:1 animations:^{
            if ( [[UIDevice currentDevice].model isEqualToString:@"iPhone"] ) {
                banner.frame = CGRectOffset(banner.frame, 0, -50);
            } else {
                banner.frame = CGRectOffset(banner.frame, 0, -66);
            }
        }];
        self.bannerIsVisible = YES;
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (self.bannerIsVisible) {
        [UIView animateWithDuration:1 animations:^{
            if ( [[UIDevice currentDevice].model isEqualToString:@"iPhone"] ) {
                banner.frame = CGRectOffset(banner.frame, 0, 50);
            } else {
                banner.frame = CGRectOffset(banner.frame, 0, 66);
            }
        }];
        self.bannerIsVisible = NO;
    }
}

@end
