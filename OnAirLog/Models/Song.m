//
//  Song.m
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/5/14.
//
//

#import "Song.h"


@implementation Song

@dynamic favoritedAt;
@dynamic artist;
@dynamic timeStamp;
@dynamic songID;
@dynamic title;

- (BOOL)isFavorited {
  return !!self.favoritedAt;
}

- (void)setIsFavorited:(BOOL)isFavorited {
  self.favoritedAt = isFavorited ? [NSDate date] : nil;
}

+ (id)createInManagedObjectContext:(NSManagedObjectContext *)context {
  id newObject = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self.class)
                                               inManagedObjectContext:context];
  return newObject;
}

- (void)updateAttributes:(NSDictionary *)attributes {
}

@end
