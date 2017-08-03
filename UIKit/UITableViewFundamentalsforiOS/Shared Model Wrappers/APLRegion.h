
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Object to represent a region containing the corresponding time zone wrappers.
 */

@import Foundation;

@interface APLRegion : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSCalendar *calendar;

+ (instancetype)regionNamed:(NSString *)name;
+ (instancetype)newRegionWithName:(NSString *)regionName;

- (void)addTimeZone:(NSTimeZone *)timeZone nameComponents:(NSArray *)nameComponents;
- (void)sortZones;
- (void)setDate:(NSDate *)date;

@property (nonatomic) NSArray *timeZoneWrappers;

@end
