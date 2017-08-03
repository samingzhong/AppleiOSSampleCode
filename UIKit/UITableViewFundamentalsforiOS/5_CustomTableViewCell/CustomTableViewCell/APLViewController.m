
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller that sets up the table view and the time zone data.
 */

#import "APLViewController.h"
#import "APLTimeZoneCell.h"
#import "APLTimeZoneWrapper.h"
#import "APLRegion.h"

#import "APLAppDelegate.h"

@interface APLViewController ()

@property (nonatomic) NSArray *displayList;
@property (nonatomic) NSCalendar *calendar;
@property (nonatomic, weak) NSTimer *minuteTimer;
@property (nonatomic, weak) NSTimer *regionsTimer;

@end

@implementation APLViewController

#pragma mark - Accessors

- (void)setMinuteTimer:(NSTimer *)newTimer {
    if (_minuteTimer != newTimer) {
        [_minuteTimer invalidate];
        _minuteTimer = newTimer;
    }
}

- (void)setRegionsTimer:(NSTimer *)newTimer {
    if (_regionsTimer != newTimer) {
        [_regionsTimer invalidate];
        _regionsTimer = newTimer;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.displayList = [self regions];
    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    /*
     Set up two timers, one that fires every minute, the other every fifteen minutes.
     
     1/ The time displayed for each time zone must be updated every minute on the minute.
     2/ Time zone data is cached. Some time zones are based on 15 minute differences from GMT, so update the cache every 15 minutes, on the "quarter".
     */
    
    NSTimer *timer;
    NSDate *date = [NSDate date];
    
    /*
     Set up a timer to update the table view every minute on the minute so that it shows the current time.
     */
    NSDate *oneMinuteFromNow = [date dateByAddingTimeInterval:60];
    
    NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    
    NSCalendar *calendar = self.calendar;
    
    NSDateComponents *timerDateComponents = [calendar components:unitFlags fromDate:oneMinuteFromNow];
    // Add 1 second to make sure the minute update has passed when the timer fires.
    timerDateComponents.second = 1;
    NSDate *minuteTimerDate = [calendar dateFromComponents:timerDateComponents];
    
    timer = [[NSTimer alloc] initWithFireDate:minuteTimerDate interval:60 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    self.minuteTimer = timer;
    
    /*
     Set up a timer to update the region data every 15 minutes on the quarter, so that the regions show the current date.
     */
    NSInteger minutesToNextQuarter = 15 - (timerDateComponents.minute % 15);
    NSDateComponents *minutesToNextQuarterComponents = [[NSDateComponents alloc] init];
    minutesToNextQuarterComponents.minute = minutesToNextQuarter;
    NSDate *regionTimerDate = [calendar dateByAddingComponents:minutesToNextQuarterComponents toDate:minuteTimerDate options:0];
    
    timer = [[NSTimer alloc] initWithFireDate:regionTimerDate interval:15*60 target:self selector:@selector(updateRegions:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    self.regionsTimer = timer;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.minuteTimer = nil;
    self.regionsTimer = nil;
}

#pragma mark - Workers

- (NSArray *)regions {
    /*
     Return an array of Region objects.
     Each object represents a geographical region.  Each region contains time zones.
     Much of the information required to display a time zone is expensive to compute, so rather than using NSTimeZone objects directly use wrapper objects that calculate the required derived values on demand and cache the results.
     */
    NSArray *knownTimeZoneNames = [NSTimeZone knownTimeZoneNames];
    
    NSMutableArray *regions = [NSMutableArray array];
    
    for (NSString *timeZoneName in knownTimeZoneNames) {
        
        NSArray *components = [timeZoneName componentsSeparatedByString:@"/"];
        NSString *regionName = components[0];
        
        APLRegion *region = [APLRegion regionNamed:regionName];
        if (region == nil) {
            region = [APLRegion newRegionWithName:regionName];
            region.calendar = self.calendar;
            [regions addObject:region];
        }
        
        NSTimeZone *timeZone = [[NSTimeZone alloc] initWithName:timeZoneName];
        [region addTimeZone:timeZone nameComponents:components];
    }
    
    NSDate *date = [NSDate date];
    // Now sort the time zones by name
    for (APLRegion *region in regions) {
        [region sortZones];
        [region setDate:date];
    }
    // Sort the regions
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [regions sortUsingDescriptors:@[sortDescriptor]];
    
    return regions;
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

	APLTimeZoneCell *timeZoneCell = (APLTimeZoneCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	// Get the time zones for the region for the section
	APLRegion *region = self.displayList[indexPath.section];
	NSArray *regionTimeZones = region.timeZoneWrappers;

	// Get the time zone wrapper for the row
	[timeZoneCell setTimeZoneWrapper:regionTimeZones[indexPath.row]];
	return timeZoneCell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	/*
	 To illustrate the effect of highlighting the cell, don't set the selection style to None in the storyboard, instead implement this method to immediately deselect the cell.
	 */
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark - Temporal updates

- (void)updateTime:(NSTimer *)timer {
    /*
     To display the current time, redisplay the time labels.
     Don't reload the table view's data as this is unnecessarily expensive -- it recalculates the number of cells and the height of each item to determine the total height of the view etc.  The external dimensions of the cells haven't changed, just their contents.
     */
    NSArray *visibleCells = self.tableView.visibleCells;
    for (APLTimeZoneCell *cell in visibleCells) {
        [cell redisplay];
    }
}

- (void)updateRegions:(id)sender {
	/*
	 The following sets the date for the regions, hence also for the time zone wrappers. This has the side-effect of "faulting" the time zone wrappers (see TimeZoneWrapper's setDate: method), so can be used to relieve memory pressure.
	 */
	NSDate *date = [NSDate date];
	for (APLRegion *region in self.displayList) {
		[region setDate:date];
	}
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {

	[super didReceiveMemoryWarning];
	[self updateRegions:self];
}

- (void)dealloc {
	[_minuteTimer invalidate];
	[_regionsTimer invalidate];
}

@end
