//
//  MTSyncEngine.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/21/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTSyncEngine : NSObject


@property (atomic, readonly) BOOL syncInProgress;

typedef enum {
    MTObjectSynced = 0,
    MTObjectCreated,
    MTObjectDeleted,
} MTObjectSyncStatus;

+ (MTSyncEngine *)sharedEngine;

- (void)registerNSManagedObjectClassToSync:(Class)aClass;
- (void)startSync;

- (NSURL *)applicationCacheDirectory;
- (NSURL *)JSONDataRecordsDirectory;

- (void)downloadDataForRegisteredObjects:(BOOL)useUpdatedAtDate;
- (NSDate *)mostRecentUpdatedAtDateForEntityWithName:(NSString *)entityName;

- (void)newManagedObjectWithClassName:(NSString *)className forRecord:(NSDictionary *)record;
- (void)updateManagedObject:(NSManagedObject *)managedObject withRecord:(NSDictionary *)record;
- (void)setValue:(id)value forKey:(NSString *)key forManagedObject:(NSManagedObject *)managedObject;
- (NSArray *)managedObjectsForClass:(NSString *)className withSyncStatus:(MTObjectSyncStatus)syncStatus;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key usingArrayOfIds:(NSArray *)idArray inArrayOfIds:(BOOL)inIds;

- (void)writeJSONResponse:(id)response toDiskForClassWithName:(NSString *)className;
- (NSArray *)JSONDataRecordsForClass:(NSString *)className sortedByKey:(NSString *)key;
- (void)deleteJSONDataRecordsForClassWithName:(NSString *)className;

- (void)processJSONDataRecordsIntoCoreData;

@end
