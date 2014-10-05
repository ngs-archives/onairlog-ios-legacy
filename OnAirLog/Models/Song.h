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

@property (nonatomic, retain) NSDate * timeStamp;

@end
