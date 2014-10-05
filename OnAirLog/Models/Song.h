//
//  Song.h
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/5/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Song : NSManagedObject

@property (nonatomic, retain) NSDate * favoritedAt;
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSNumber * songID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, assign) BOOL isFavorited;

+ (id)createInManagedObjectContext:(NSManagedObjectContext *)context;
- (void)updateAttributes:(NSDictionary *)attributes;

@end
