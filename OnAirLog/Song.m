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

@interface Song ()

// https://developer.apple.com/library/ios/samplecode/DateSectionTitles/Listings/DateSectionTitles_APLEvent_m.html#//apple_ref/doc/uid/DTS40009939-DateSectionTitles_APLEvent_m-DontLinkElementID_6
@property (nonatomic) NSDate *primitiveTimeStamp;
@property (nonatomic) NSString *primitiveSectionIdentifier;

@end


@implementation Song

@dynamic favoritedAt, artist, timeStamp, songID, title, primitiveSectionIdentifier, primitiveTimeStamp;

+ (id)findOrCreateWithAttributes:(NSDictionary *)attributes inContext:(NSManagedObjectContext *)context {
  id song = attributes[@"id"] ? [Song findFirstByAttribute:@"songID" withValue:attributes[@"id"] inContext:context] : nil;
  if(!song) song = [self createInContext:context];
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
}

- (NSString *)sectionIdentifier {
  // Create and cache the section identifier on demand.

  [self willAccessValueForKey:@"sectionIdentifier"];
  NSString *tmp = [self primitiveSectionIdentifier];
  [self didAccessValueForKey:@"sectionIdentifier"];

  if (!tmp) {
    static NSDateFormatter *fmt = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      if(!fmt) {
        fmt = [[NSDateFormatter alloc] init];
        fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:9*60*60];
        [fmt setDateFormat:@"yyyyMMddHH"];
      }
    });
    tmp = [fmt stringFromDate:self.timeStamp];
    [self setPrimitiveSectionIdentifier:tmp];
  }
  return tmp;
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


#pragma mark - Time stamp setter

- (void)setTimeStamp:(NSDate *)newDate {
  // If the time stamp changes, the section identifier become invalid.
  [self willChangeValueForKey:@"timeStamp"];
  [self setPrimitiveTimeStamp:newDate];
  [self didChangeValueForKey:@"timeStamp"];

  [self setPrimitiveSectionIdentifier:nil];
}


#pragma mark - Key path dependencies

+ (NSSet *)keyPathsForValuesAffectingSectionIdentifier {
  // If the value of timeStamp changes, the section identifier may change as well.
  return [NSSet setWithObject:@"timeStamp"];
}


@end
