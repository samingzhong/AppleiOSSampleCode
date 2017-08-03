
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A table view cell to display various pieces of information about a time zone. Since the content is fairly complex and can't readily be rendered using three simple subviews, it uses a TimeZoneView to display the content.
 */

#import "APLTimeZoneCell.h"
#import "APLTimeZoneWrapper.h"
#import "APLTimeZoneView.h"

@interface APLTimeZoneCell ()

@property (nonatomic, weak) IBOutlet APLTimeZoneView *timeZoneView;

@end

@implementation APLTimeZoneCell

- (void)setTimeZoneWrapper:(APLTimeZoneWrapper *)newTimeZoneWrapper {
	// Pass the time zone wrapper to the view
	self.timeZoneView.timeZoneWrapper = newTimeZoneWrapper;
}

- (void)redisplay {
	[self.timeZoneView setNeedsDisplay];
}

@end
