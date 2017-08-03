
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Object to represent a region containing the corresponding time zone wrappers.
 */

#import "APLRegion.h"
#import "APLTimeZoneWrapper.h"

static NSMutableDictionary *regions;

@interface APLRegion ()

@property (nonatomic) NSMutableArray *mutableTimeZoneWrappers;

@end

@implementation APLRegion

/*
 Class methods to manage global regions (pun intended).
 */
+ (void)initialize {
	regions = [[NSMutableDictionary alloc] init];	
}

+ (instancetype)regionNamed:(NSString *)name {
	return regions[name];
}

+ (instancetype)newRegionWithName:(NSString *)regionName {
    // Create a new region with a given name; add it to the regions dictionary.
	APLRegion *newRegion = [[self alloc] init];
	newRegion.name = regionName;
	newRegion.mutableTimeZoneWrappers = [[NSMutableArray alloc] init];
	regions[regionName] = newRegion;
	return newRegion;
}

-(NSArray *)timeZoneWrappers {
    return _mutableTimeZoneWrappers;
}

- (void)addTimeZone:(NSTimeZone *)timeZone nameComponents:(NSArray *)nameComponents {
    // Add a time zone to the region; use nameComponents because it' expensive to compute.
	APLTimeZoneWrapper *timeZoneWrapper = [[APLTimeZoneWrapper alloc] initWithTimeZone:timeZone nameComponents:nameComponents];
	timeZoneWrapper.calendar = self.calendar;
	[self.mutableTimeZoneWrappers addObject:timeZoneWrapper];
}

- (void)sortZones {
    // Sort the zone wrappers by locale name.
    NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeZoneLocaleName" ascending:YES comparator:^(id name1, id name2) {
        return [(NSString *)name1 localizedStandardCompare:(NSString *)name2];
    }];
    
	[self.mutableTimeZoneWrappers sortUsingDescriptors:@[nameSortDescriptor]];
}

// Sets the date for the time zones, which has the side-effect of "faulting" the wrappers (see APLTimeZoneWrapper's setDate: method)
- (void)setDate:(NSDate *)date {
	for (APLTimeZoneWrapper *wrapper in self.timeZoneWrappers) {
		wrapper.date = date;
	}
}

@end
