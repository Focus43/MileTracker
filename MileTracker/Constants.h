//
//  Constants.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/28/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

// generic object name constants for easy reuse
#define kPFObjectClassName @"Trip"
//#define kPFObjectClassName2 @"Destination"

#define kUnsyncedTripEntityName @"UnsyncedTrip"
#define kMileageTotalFoundNotification @"MileageTotalFoundNotification"
#define kLaunchLoginScreenNotification @"LaunchLoginScreenNotification"

#define kUserDefaultsInitialTallyDoneKey @"initialTallyDone"
#define kUserDefaultsSavingsKey @"savingsToDate"
#define kUserDefaultsSavingsStringKey @"savingsToDateString"
#define kUserDefaultsTotalMilesKey @"mileageToDate"
#define kUserDefaultsLengthUnit @"lengthUnit"
#define kUserDefaultsLengthUnitKilometer @"kilometers"
#define kUserDefaultsLengthUnitMile @"miles"

#define kTripTypeBusiness @"Business"
#define kTripTypeCharitable @"Charitable"
#define kTripTypePersonal @"Personal"
#define kTripTypeOptions @[kTripTypeCharitable, kTripTypeBusiness, kTripTypePersonal]

#define kDollarPerMileTaxDeduction 0.565

#define kDateRangeSegueIdentifier @"DateRangeSegueIdentifier"