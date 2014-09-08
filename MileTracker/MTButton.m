//
//  MTButton.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 8/27/14.
//  Copyright (c) 2014 Focus43. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MTButton.h"

@interface MTButton () {
    CABasicAnimation *pulseAnimation;
}

@property (assign,nonatomic) BOOL isPulsing;

- (void)pulseOn;
- (void)pulseOff;

@end

@implementation MTButton

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.layer.borderWidth=1.0f;
        self.layer.borderColor=[[UIColor whiteColor] CGColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize: 20];
        CGRect buttonFrame = self.frame;
        buttonFrame.size.height = 40;
        self.frame = buttonFrame;
        [self setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.8]];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
         _isPulsing = NO;
    }
    return self;
}

- (void)startFlashing
{
    if ( !pulseAnimation ) {
        pulseAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [pulseAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [pulseAnimation setBeginTime:CACurrentMediaTime() + 0.3];
        [pulseAnimation setDuration:1.0];
        [pulseAnimation setRepeatCount:HUGE_VAL];
        [pulseAnimation setAutoreverses:YES];
        [pulseAnimation setFromValue:@(0.1)];
        [pulseAnimation setToValue:@(1)];
        [pulseAnimation setRemovedOnCompletion:YES];
    }
    
    [self.layer addAnimation:pulseAnimation forKey:@"opacity"];
}

- (void)stopFlashing
{
    _isPulsing = NO;
    [self.layer removeAnimationForKey:@"opacity"];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
