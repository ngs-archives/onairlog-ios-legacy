
//
//  Song.m
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/5/14.
//
//

#import "Song.h"
#define MR_SHORTHAND
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Song

@dynamic favoritedAt, artist, timeStamp, songID, title, sectionIdentifier;

+ (NSString *)entityName {
  return @"Song";
}

+ (id)findOrCreateWithAttributes:(NSDictionary *)attributes inContext:(NSManagedObjectContext *)context {
  id song = attributes[@"id"] ? [Song findFirstByAttribute:@"songID" withValue:attributes[@"id"] inContext:context] : nil;
  if(!song) song = [self createEntityInContext:context];
  [song updateAttributes:attributes];
  return song;
}

- (BOOL)isFavorited {
  return !!self.favoritedAt;
}

- (void)setIsFavorited:(BOOL)isFavorited {
  if(!isFavorited) {
    self.favoritedAt = nil;
  } else if(!self.favoritedAt) {
    self.favoritedAt = [NSDate date];
  }
}

- (void)updateAttributes:(NSDictionary *)attributes {
  self.songID = attributes[@"id"];
  self.title = attributes[@"title"];
  self.artist = attributes[@"artist"];
  static NSDateFormatter *fmt = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if(!fmt) {
      fmt = [[NSDateFormatter alloc] init];
      fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:9*60*60];
      [fmt setDateFormat:@"yyyy-MM-dd HH:mm"];
    }
  });
  self.timeStamp = [fmt dateFromString:attributes[@"date"]];
  [self updateSectionIdentifier];
}


- (void)updateSectionIdentifier {
  static NSDateFormatter *fmt = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if(!fmt) {
      fmt = [[NSDateFormatter alloc] init];
      fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:9*60*60];
      [fmt setDateFormat:@"yyyyMMddHH"];
    }
  });
  self.sectionIdentifier = [fmt stringFromDate:self.timeStamp];
}

- (NSString *)timeStampFormatted {
  static NSDateFormatter *fmt = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if(!fmt) {
      fmt = [[NSDateFormatter alloc] init];
      fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:9*60*60];
      [fmt setDateFormat:@"HH:mm"];
    }
  });
  return [fmt stringFromDate:self.timeStamp];
}

- (NSString *)sectionTitle {
  static NSDateFormatter *fmt = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if(!fmt) {
      fmt = [[NSDateFormatter alloc] init];
      fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:9*60*60];
      [fmt setDateFormat:@"yyyy/MM/dd HH:00 -"];
    }
  });
  return [fmt stringFromDate:self.timeStamp];
}

@end
