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
- (void)saveContext;

- (NSURL *)applicationDocumentsDirectory;

- (NSManagedObjectContext *)managedObjectContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;


@end
