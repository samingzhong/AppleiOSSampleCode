
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A table view cell to display various pieces of information about a time zone. Since the content is fairly complex and can't readily be rendered using three simple subviews, it uses a TimeZoneView to display the content.
 */

@import UIKit;

@class APLTimeZoneWrapper;

@interface APLTimeZoneCell : UITableViewCell

- (void)setTimeZoneWrapper:(APLTimeZoneWrapper *)newTimeZoneWrapper;
- (void)redisplay;

@end
