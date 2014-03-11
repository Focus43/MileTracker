//
//  MTFormattingUtilitites.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/9/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import "MTFormatting.h"

@implementation MTFormatting

@synthesize dateFormatter, numberFormatter;

+ (MTFormatting *)sharedUtility
{
    static MTFormatting *sharedUtility = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedUtility = [[MTFormatting alloc] init];
    });
    
    return sharedUtility;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [self.dateFormatter setDateStyle:kCFDateFormatterShortStyle];
    
        self.numberFormatter = [[NSNumberFormatter alloc] init];
        [self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        
        self.currencyFormatter = [[NSNumberFormatter alloc] init];
        [self.currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        NSString *groupingSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator];
        [self.currencyFormatter setGroupingSeparator:groupingSeparator];
        [self.currencyFormatter setGroupingSize:3];
        [self.currencyFormatter setAlwaysShowsDecimalSeparator:NO];
        [self.currencyFormatter setUsesGroupingSeparator:YES];
    }
    
    return self;
}

@end
