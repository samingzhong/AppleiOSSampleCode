
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Object to represent a time zone, caching various derived properties that are expensive to compute.
 */

@import UIKit;

@interface APLTimeZoneWrapper : NSObject

@property (nonatomic) NSString *timeZoneLocaleName;
@property (nonatomic) NSTimeZone *timeZone;

@property (nonatomic) NSDate *date;
@property (nonatomic) NSCalendar *calendar;

@property (readonly, nonatomic) NSString *extendedDetailText;
@property (readonly, nonatomic) NSString *whichDay;
@property (readonly, nonatomic) NSString *abbreviation;
@property (readonly, nonatomic) NSString *gmtOffset;
@property (readonly, nonatomic) UIImage *image;

- (instancetype)initWithTimeZone:(NSTimeZone *)aTimeZone nameComponents:(NSArray *)nameComponents NS_DESIGNATED_INITIALIZER;

@end
