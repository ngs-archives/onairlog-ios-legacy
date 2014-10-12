
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
#import <GoogleAnalytics-iOS-SDK/GAI.h>
#import <GoogleAnalytics-iOS-SDK/GAIFields.h>
#import <GoogleAnalytics-iOS-SDK/GAIDictionaryBuilder.h>

static NSString *ITUNES_LINK_FORMAT = @"https://itunes.apple.com/WebObjects/MZStore.woa/wa/search?mt=1&term=%@&uo=4&at=10l87J";

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
  [[[GAI sharedInstance] defaultTracker] send:
   [[GAIDictionaryBuilder
     createEventWithCategory:@"favorites"
     action:isFavorited ? @"favorited" : @"unfavorited"
     label:self.songID.stringValue value:@1] build]];
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

- (NSString *)timeFormatted {
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

- (NSString *)dateTimeFormatted {
  static NSDateFormatter *fmt = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if(!fmt) {
      fmt = [[NSDateFormatter alloc] init];
      fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:9*60*60];
      [fmt setDateFormat:@"yyyy/MM/dd HH:mm"];
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

- (NSURL *)iTunesSearchURL {
  NSString *urlString =
  [NSString stringWithFormat:ITUNES_LINK_FORMAT,
   [self.searchTerm stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
  return [NSURL URLWithString:urlString];
}

- (NSString *)searchTerm {
  return [NSString stringWithFormat:@"%@ %@", self.title, self.artist];
}

@end
