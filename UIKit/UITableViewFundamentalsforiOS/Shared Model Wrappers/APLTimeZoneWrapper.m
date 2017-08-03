
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Object to represent a time zone, caching various derived properties that are expensive to compute.
 */

#import "APLTimeZoneWrapper.h"

static NSString *today;
static NSString *tomorrow;
static NSString *yesterday;

static UIImage *q1Image;
static UIImage *q2Image;
static UIImage *q3Image;
static UIImage *q4Image;

@interface APLTimeZoneWrapper ()

@property (readwrite, nonatomic) NSString *extendedDetailText;
@property (readwrite, nonatomic) NSString *whichDay;
@property (readwrite, nonatomic) NSString *abbreviation;
@property (readwrite, nonatomic) NSString *gmtOffset;
@property (readwrite, nonatomic) UIImage *image;

@end

@implementation APLTimeZoneWrapper

+ (void)initialize {
	// Unlikely to have any subclasses, but check class nevertheless
	if (self == [APLTimeZoneWrapper class]) {
		today = NSLocalizedString(@"Today", "Today");
		tomorrow = NSLocalizedString(@"Tomorrow", "Tomorrow");
		yesterday = NSLocalizedString(@"Yesterday", "Yesterday");
		
        q1Image = [UIImage imageNamed:@"12AM-6AM.png"];
        q2Image = [UIImage imageNamed:@"6AM-12PM.png"];
        q3Image = [UIImage imageNamed:@"12PM-6PM.png"];
        q4Image = [UIImage imageNamed:@"6PM-12AM.png"];
	}
}

- (instancetype)init {
    NSAssert(NO, @"Invalid use of init; use initWithTimeZone:nameComponents: to create APLTimeZoneWrapper");
    return [self init];
}

- (instancetype)initWithTimeZone:(NSTimeZone *)aTimeZone nameComponents:(NSArray *)nameComponents {
	
	self = [super init];
    
    if (self) {
		_timeZone = aTimeZone;
		
		NSString *name = nil;
		if (nameComponents.count == 2) {
			name = nameComponents[1];
		}
		else if (nameComponents.count == 3) {
			name = [NSString stringWithFormat:@"%@ (%@)", nameComponents[2], nameComponents[1]];
		}
		
		_timeZoneLocaleName = [name stringByReplacingOccurrencesOfString:@"_" withString:@" "];
	}
    
	return self;
}

/*
 By default, we don't actually calculate whichDay, abreviation, gmtOffset or image.
 They're expensive to compute, and consume memory.  Calculate them on demand, then cache them.
 */
- (NSString *)whichDay {
    // Return "today", "tomorrow", or "yesterday" as appropriate for the time zone
	
	if (_whichDay == nil) {
		NSDateComponents *dateComponents;
		NSInteger myDay, tzDay;

        NSCalendar *calendar = self.calendar;
        NSDate *date = self.date;

		// Set the calendar's time zone to the default time zone.
		calendar.timeZone = [NSTimeZone defaultTimeZone];
		dateComponents = [calendar components:NSCalendarUnitWeekday fromDate:date];
		myDay = dateComponents.weekday;
		
		calendar.timeZone = self.timeZone;
		dateComponents = [calendar components:NSCalendarUnitWeekday fromDate:date];
		tzDay = dateComponents.weekday;
		
		NSRange dayRange = [calendar maximumRangeOfUnit:NSCalendarUnitWeekday];
		NSInteger maxDay = NSMaxRange(dayRange) - 1;
		
		if (myDay == tzDay) {
			_whichDay = today;
		} else {
			if ((tzDay - myDay) > 0) {
				_whichDay = tomorrow;
			} else {
				_whichDay = yesterday;
			}
			// Special cases for days at the end of the week
			if ((myDay == maxDay) && (tzDay == 1)) {
				self.whichDay = tomorrow;				
			}
			if ((myDay == 1) && (tzDay == maxDay)) {
				_whichDay = yesterday;
			}
		}
	}
	return _whichDay;
}

- (NSString *)abbreviation {
    // Return the abbreviation for the time zone
	if (_abbreviation == nil) {
		_abbreviation = [self.timeZone abbreviationForDate:self.date];
	}
	return _abbreviation;
}

- (NSString *)gmtOffset {
    // Return the offset from GMT for the time zone
	if (_gmtOffset == nil) {
		_gmtOffset = [self.timeZone localizedName:NSTimeZoneNameStyleShortStandard locale:[NSLocale currentLocale]];
	}
	return _gmtOffset;
}

- (NSString *)extendedDetailText {
    //  Return a string of concatendated property values for resizable detail text label
    if( _extendedDetailText == nil ) {
        
        //  Description
        NSString *detailText = [self.timeZone.description stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        
        //  Daylight Savings
        if( !self.timeZone.daylightSavingTime ) {
            detailText = [detailText stringByAppendingString:@" (Not Daylight Savings)"];
        }
        
        //  Which Day
        detailText = [detailText stringByAppendingString:self.whichDay];
        
        _extendedDetailText = detailText;

    }
    return _extendedDetailText;
}

- (UIImage *)image {
    // Return an image that illustrates the quarter of the current day in the time zone
	if (_image == nil) {

        NSCalendar *calendar = self.calendar;
        NSDate *date = self.date;

		calendar.timeZone = self.timeZone;
		NSDateComponents *dateComponents = [calendar components:NSCalendarUnitHour fromDate:date];
		NSInteger hour = dateComponents.hour;
		if (hour > 17) {
			_image = q4Image;
		} else {
			if (hour > 11) {
				_image = q3Image;
			} else {
				if (hour > 5) {
					_image = q2Image;
				} else {
					_image = q1Image;
				}
			}
		}
	}
	return _image;
}

- (void)setDate:(NSDate *)newDate {
	/*
	 Recalculating all the details is expensive.
	 Only change the date if it is not actually equal to the current date.
	 If the date is different, "fault" the receiver: nill out all the cached values -- if accessed, they will be recaulculated.
	 */
	if ([newDate isEqualToDate:_date]) {
		return;
	}
	_date = newDate;
	self.abbreviation = nil;
	self.gmtOffset = nil;
	self.image = nil;
}

@end
