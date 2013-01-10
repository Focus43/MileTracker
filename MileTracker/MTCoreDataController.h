//
//  MTCoreDataController.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/20/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTCoreDataController : NSObject

+ (id)sharedInstance;

- (NSURL *)applicationDocumentsDirectory;

- (NSManagedObjectContext *)masterManagedObjectContext;
- (NSManagedObjectContext *)backgroundManagedObjectContext;
- (NSManagedObjectContext *)newManagedObjectContext;
- (void)saveMasterContext;
- (void)saveBackgroundContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;


@end
