
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A simple view to display various pieces of information about a time zone. Because the the view's content is fairly complex, it draws its content directly in drawRect: to optimize scolling performance.
  The implementation is very basic -- it doesn't attempt to constrain text to particular areas to aviod overlapping and so on. It does, though, illustrate response to highlighting.
 */

#import "APLTimeZoneView.h"
#import "APLTimeZoneWrapper.h"

NSUInteger DeviceSystemMajorVersion();

@interface APLTimeZoneView ()

@property (nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation APLTimeZoneView

- (void)setTimeZoneWrapper:(APLTimeZoneWrapper *)newTimeZoneWrapper {
	
	// If the time zone wrapper changes, update the date formatter and abbreviation string.
	if (_timeZoneWrapper != newTimeZoneWrapper) {
		_timeZoneWrapper = newTimeZoneWrapper;
		
		self.dateFormatter.timeZone = _timeZoneWrapper.timeZone;
		
		self.abbreviation = [[NSString alloc] initWithFormat:@"%@ (%@)", _timeZoneWrapper.abbreviation, _timeZoneWrapper.gmtOffset];
	}
	// May be the same wrapper, but the date may have changed, so mark for redisplay.
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)lit {
	// If highlighted state changes, need to redisplay.
	if (_highlighted != lit) {
		_highlighted = lit;
		[self setNeedsDisplay];
	}
}

- (void)drawRect:(CGRect)rect {
	
#define LEFT_COLUMN_OFFSET 10
#define MIDDLE_COLUMN_OFFSET 170
#define RIGHT_COLUMN_OFFSET 270
	
#define UPPER_ROW_TOP 12
#define LOWER_ROW_TOP 44

	// Color for the main text items (time zone name, time).
	UIColor *mainTextColor;

	// Color for the secondary text items (GMT offset, day).
	UIColor *secondaryTextColor;

	// Choose font color based on highlighted state.
	if (self.highlighted) {
		mainTextColor = [UIColor whiteColor];
		secondaryTextColor = [UIColor whiteColor];
	}
	else {
		mainTextColor = [UIColor blackColor];
		secondaryTextColor = [UIColor darkGrayColor];
	}

    /*
     Font attributes for the main text items (time zone name, time).
     For iOS 7 and later, use text styles instead of system fonts.
     */
    UIFont *mainFont;
    if (DeviceSystemMajorVersion() > 6) {
        mainFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    }
    else {
        mainFont = [UIFont systemFontOfSize:17.0];
    }
    
    NSDictionary *mainTextAttributes = @{ NSFontAttributeName : mainFont, NSForegroundColorAttributeName : mainTextColor };

	// Font attributes for the secondary text items (GMT offset, day).
    UIFont *secondaryFont;
    if (DeviceSystemMajorVersion() > 6) {
        secondaryFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    }
    else {
        secondaryFont = [UIFont systemFontOfSize:12.0];
    }
    NSDictionary *secondaryTextAttributes = @{ NSFontAttributeName : secondaryFont, NSForegroundColorAttributeName : secondaryTextColor };
    

	// In this example we will never be editing, but this illustrates the appropriate pattern.
    if (!self.editing) {

		CGPoint point;
		
		/*
		 Draw the locale name top left.
		*/
        NSAttributedString *localeNameAttributedString = [[NSAttributedString alloc] initWithString:self.timeZoneWrapper.timeZoneLocaleName attributes:mainTextAttributes];
		point = CGPointMake(LEFT_COLUMN_OFFSET, UPPER_ROW_TOP);
		[localeNameAttributedString drawAtPoint:point];

		/*
		 Draw the current time in the middle column.
		 */
		NSString *timeString = [self.dateFormatter stringFromDate:[NSDate date]];
        NSAttributedString *timeAttributedString = [[NSAttributedString alloc] initWithString:timeString attributes:mainTextAttributes];
		point = CGPointMake(MIDDLE_COLUMN_OFFSET, UPPER_ROW_TOP);
		[timeAttributedString drawAtPoint:point];
		
		/*
		 Draw the abbreviation botton left.
		 */
        NSAttributedString *abbreviationAttributedString = [[NSAttributedString alloc] initWithString:self.abbreviation attributes:secondaryTextAttributes];
		point = CGPointMake(LEFT_COLUMN_OFFSET, LOWER_ROW_TOP);
		[abbreviationAttributedString drawAtPoint:point];

		/*
		 Draw the whichDay string.
		 */
        APLTimeZoneWrapper *timeZoneWrapper = self.timeZoneWrapper;

        NSAttributedString *whichDayAttributedString = [[NSAttributedString alloc] initWithString:timeZoneWrapper.whichDay attributes:secondaryTextAttributes];
		point = CGPointMake(MIDDLE_COLUMN_OFFSET, LOWER_ROW_TOP);
		[whichDayAttributedString drawAtPoint:point];

		
		// Draw the quarter image.
		CGFloat imageY = (self.bounds.size.height - self.timeZoneWrapper.image.size.height) / 2;
		
		point = CGPointMake(RIGHT_COLUMN_OFFSET, imageY);
		[timeZoneWrapper.image drawAtPoint:point];
	}
}

-(NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"h:mm a" options:0 locale:[NSLocale currentLocale]];
        _dateFormatter.dateFormat = dateFormat;
    }
    return _dateFormatter;
}

@end

NSUInteger DeviceSystemMajorVersion() {
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _deviceSystemMajorVersion = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."][0].integerValue;
    });
    return _deviceSystemMajorVersion;
}
