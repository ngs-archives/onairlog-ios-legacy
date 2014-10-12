//
//  ShortenURL.m
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/8/14.
//
//

#import "ShortenURL.h"
#define MR_SHORTHAND
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import <AFNetworking/AFNetworking.h>
#import <GoogleAnalytics-iOS-SDK/GAI.h>
#import <GoogleAnalytics-iOS-SDK/GAIFields.h>
#import <GoogleAnalytics-iOS-SDK/GAIDictionaryBuilder.h>

@implementation ShortenURL

@dynamic originalURL;
@dynamic shortenURL;

+ (NSString *)entityName {
  return @"ShortenURL";
}

+ (BOOL)findOrCreateByOriginalURL:(NSURL *)originalURL
                  withAccessToken:(NSString *)accessToken
                       completion:(void (^)(NSURL *url))completionHandler {
  ShortenURL *exists = [self findFirstByAttribute:@"originalURL" withValue:originalURL.absoluteString];
  if(exists) {
    completionHandler([NSURL URLWithString:exists.shortenURL]);
    return YES;
  }
  AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
  manager.responseSerializer = [AFJSONResponseSerializer serializer];
  manager.requestSerializer = [AFHTTPRequestSerializer serializer];
  id tracker = [[GAI sharedInstance] defaultTracker];
  NSDictionary *params = @{ @"access_token": accessToken, @"longUrl": originalURL.absoluteString };
  [manager
   GET:@"https://api-ssl.bitly.com/v3/shorten" parameters:params
   success:^(NSURLSessionDataTask *task, id responseObject) {
     if(![responseObject isKindOfClass:[NSDictionary class]] ||
        [responseObject[@"status_code"] integerValue] != 200 ||
        ![responseObject[@"data"] isKindOfClass:[NSDictionary class]] ||
        ![responseObject[@"data"][@"url"] isKindOfClass:[NSString class]]
        ) {
       [tracker send:
        [[GAIDictionaryBuilder
          createExceptionWithDescription:
          [NSString stringWithFormat:@"Invalid data (%@): %@", originalURL, responseObject]
          withFatal:@NO] build]];
       completionHandler(nil);
       return;
     }
     NSString *urlString = responseObject[@"data"][@"url"];
     ShortenURL *newRecord = [self createEntity];
     NSError *error = nil;
     newRecord.shortenURL = urlString;
     newRecord.originalURL = originalURL.absoluteString;
     [newRecord.managedObjectContext save:&error];
     if(!error) {
       completionHandler([NSURL URLWithString:urlString]);
     } else {
       [tracker send:
        [[GAIDictionaryBuilder
          createExceptionWithDescription:error.localizedDescription
          withFatal:@NO] build]];
       completionHandler(nil);
     }
   }
   failure:^(NSURLSessionDataTask *task, NSError *error) {
     [tracker send:
      [[GAIDictionaryBuilder
        createExceptionWithDescription:error.localizedDescription
        withFatal:@NO] build]];
     completionHandler(nil);
   }];
  return NO;
}

@end
