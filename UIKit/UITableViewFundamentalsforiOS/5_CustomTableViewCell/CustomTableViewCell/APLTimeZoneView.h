
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A simple view to display various pieces of information about a time zone. Because the the view's content is fairly complex, it draws its content directly in drawRect: to optimize scolling performance.
  The implementation is very basic -- it doesn't attempt to constrain text to particular areas to aviod overlapping and so on. It does, though, illustrate response to highlighting.
 */

@import UIKit;

@class APLTimeZoneWrapper;

@interface APLTimeZoneView : UIView

@property (nonatomic) APLTimeZoneWrapper *timeZoneWrapper;
@property (nonatomic) NSString *abbreviation;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isEditing) BOOL editing;

@end
