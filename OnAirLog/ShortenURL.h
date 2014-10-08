//
//  ShortenURL.h
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/8/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ShortenURL : NSManagedObject

@property (nonatomic, retain) NSString * originalURL;
@property (nonatomic, retain) NSString * shortenURL;

+ (BOOL)findOrCreateByOriginalURL:(NSURL *)originalURL
                  withAccessToken:(NSString *)accessToken
                       completion:(void (^)(NSURL *url))completionHandler;

@end
