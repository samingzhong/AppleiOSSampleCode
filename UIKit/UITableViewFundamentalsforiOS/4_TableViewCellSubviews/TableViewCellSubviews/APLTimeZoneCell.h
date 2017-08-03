
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A simple UITableViewCell subclass that provides references to its subviews.
 */

@import UIKit;

@interface APLTimeZoneCell : UITableViewCell

@property (nonatomic, weak, readonly) UILabel *nameLabel;
@property (nonatomic, weak, readonly) UILabel *timeLabel;
@property (nonatomic, weak, readonly) UIImageView *timeImageView;

@end
