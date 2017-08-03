
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller that sets up the table view and the time zone data.
 */

#import "APLViewController.h"
#import "APLTimeZoneWrapper.h"
#import "APLRegion.h"
#import "APLTimeZoneCell.h"
#import "APLAppDelegate.h"

@interface APLViewController ()

@property (nonatomic) NSArray *displayList;
@property (nonatomic) NSCalendar *calendar;
@property (nonatomic, weak) NSTimer *minuteTimer;

@end

/*
 Table view row height and cell height are defined as 60 in the storyboard.
 */

@implementation APLViewController

#pragma mark - Accessors

- (void)setMinuteTimer:(NSTimer *)newTimer {
    if (_minuteTimer != newTimer) {
        [_minuteTimer invalidate];
        _minuteTimer = newTimer;
    }
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.calendar = calendar;
    self.displayList = [self regionsWithCalendar:calendar];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.minuteTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    /*
     Set up a timer to update the table view every minute on the minute so that it shows the current time.
     */
    NSDate *date = [NSDate date];
    NSDate *oneMinuteFromNow = [date dateByAddingTimeInterval:60];
    
    //  year - month = day - hour - minute
    
    NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    NSDateComponents *timerDateComponents = [self.calendar components:unitFlags fromDate:oneMinuteFromNow];
    // Add one second to ensure time has passed minute update when the timer fires.
    timerDateComponents.second = 1;
    NSDate *minuteTimerDate = [self.calendar dateFromComponents:timerDateComponents];
    
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:minuteTimerDate interval:60 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    self.minuteTimer = timer;
}

#pragma mark - Workers

- (void)update:sender {
    /*
     The following sets the date for the regions, hence also for the time zone wrappers. This has the side-effect of "faulting" the time zone wrappers (see TimeZoneWrapper's setDate: method), so can be used to relieve memory pressure.
     */
    NSDate *date = [NSDate date];
    for (APLRegion *region in self.displayList) {
        [region setDate:date];
    }
}

- (NSArray *)regionsWithCalendar:(NSCalendar *)calendar {
    /*
     Create an array of Region objects.
     Each object represents a geographical region.  Each region contains time zones.
     Much of the information required to display a time zone is expensive to compute, so rather than using NSTimeZone objects directly use wrapper objects that calculate the required derived values on demand and cache the results.
     */
    NSArray *knownTimeZoneNames = [NSTimeZone knownTimeZoneNames];
    
    NSMutableArray *regions = [[NSMutableArray alloc] init];
    
    for (NSString *timeZoneName in knownTimeZoneNames) {
        
        NSArray *components = [timeZoneName componentsSeparatedByString:@"/"];
        NSString *regionName = components[0];
        
        APLRegion *region = [APLRegion regionNamed:regionName];
        if (region == nil) {
            region = [APLRegion newRegionWithName:regionName];
            region.calendar = calendar;
            [regions addObject:region];
        }
        
        NSTimeZone *timeZone = [[NSTimeZone alloc] initWithName:timeZoneName];
        [region addTimeZone:timeZone nameComponents:components];
    }
    
    // Now sort the time zones by name.
    NSDate *date = [[NSDate alloc] init];
    for (APLRegion *region in regions) {
        [region sortZones];
        [region setDate:date];
    }
    
    // Sort the regions by name.
    NSArray *sortedRegions = [regions sortedArrayUsingComparator:^(APLRegion * region1, APLRegion * region2) {
        NSString *name1 = region1.name;
        NSString *name2 = region2.name;
        // Do comparison
        return [name1 localizedStandardCompare:name2];
    }];
    
    return sortedRegions;
}

#pragma mark - Temporal updates

- (void)updateTime:(NSTimer *)timer {
    /*
     To display the current time, redisplay the time labels.
     Don't reload the table view's data as this is unnecessarily expensive -- it recalculates the number of cells and the height of each item to determine the total height of the view etc.  The external dimensions of the cells haven't changed, just their contents.
     */
    NSArray *visibleCells = self.tableView.visibleCells;
    for (APLTimeZoneCell *cell in visibleCells) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        [self configureCell:cell forIndexPath:indexPath];
        [cell setNeedsDisplay];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	// Number of sections is the number of regions
	return self.displayList.count;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	// Number of rows is the number of time zones in the region for the specified section
	APLRegion *region = self.displayList[section];
	NSArray *regionTimeZones = region.timeZoneWrappers;
	return regionTimeZones.count;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	// Section title is the region name
	APLRegion *region = self.displayList[section];
	return region.name;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {

	static NSString *CellIdentifier = @"TimeZoneCell";

	APLTimeZoneCell *cell = (APLTimeZoneCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	// configureCell:cell forIndexPath: sets the text and image for the cell -- the method is factored out because it's also called during minuted-based updates.
	[self configureCell:cell forIndexPath:indexPath];
	return cell;
}

#pragma mark - Configuring table view cells

- (void)configureCell:(APLTimeZoneCell *)cell forIndexPath:(NSIndexPath *)indexPath {

    /*
	 Cache the formatter. Normally you would use one of the date formatter styles (such as NSDateFormatterShortStyle), but here we want a specific format that excludes seconds.
	 */
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"h:mm a" options:0 locale:[NSLocale currentLocale]];
		dateFormatter.dateFormat = dateFormat;
	}

	// Get the time zones for the region for the section
	APLRegion *region = self.displayList[indexPath.section];
	NSArray *regionTimeZones = region.timeZoneWrappers;
	APLTimeZoneWrapper *wrapper = regionTimeZones[indexPath.row];

	// Set the locale name.
	cell.nameLabel.text = wrapper.timeZoneLocaleName;

	// Set the time.
	dateFormatter.timeZone = wrapper.timeZone;
	cell.timeLabel.text = [dateFormatter stringFromDate:[NSDate date]];

	// Set the image.
	cell.timeImageView.image = wrapper.image;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {

	[super didReceiveMemoryWarning];
	[self update:self];
}

- (void)dealloc {
	[_minuteTimer invalidate];
}

@end
