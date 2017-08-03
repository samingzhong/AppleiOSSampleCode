
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller that sets up the table view and the time zone data.
 */

#import "APLTableViewController.h"
#import "APLRegion.h"
#import "APLTimeZoneWrapper.h"
#import "APLTimeZoneCell.h"

static NSString *kTableViewCellReuseIdentifierSelfSizingCell = @"Self Sizing Cell";

@interface APLTableViewController ()

@property (nonatomic, strong) NSArray *displayList;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSTimer *minuteTimer;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation APLTableViewController

#pragma mark - Accessors

- (NSDateFormatter *)dateFormatter {
    if( !_dateFormatter ) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"h:mm a" options:0 locale:[NSLocale currentLocale]];
        _dateFormatter.dateFormat = dateFormat;
    }
    return _dateFormatter;
}

- (void)setMinuteTimer:(NSTimer *)newTimer {
    
    if (_minuteTimer != newTimer) {
        [_minuteTimer invalidate];
        _minuteTimer = newTimer;
    }
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.calendar = calendar;
    self.displayList = [self regions];
    
    //  Must set the following properties
    self.tableView.estimatedRowHeight = 85.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSDate *date = [NSDate date];
    NSDate *oneMinuteFromNow = [date dateByAddingTimeInterval:60];
    
    NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    NSDateComponents *timerDateComponents = [self.calendar components:unitFlags fromDate:oneMinuteFromNow];
    timerDateComponents.second = 1;
    NSDate *minuteTimerDate = [self.calendar dateFromComponents:timerDateComponents];
    
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:minuteTimerDate interval:60 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    self.minuteTimer = timer;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.minuteTimer = nil;
}

#pragma mark - Workers

- (void)update {
    NSDate *date = [NSDate date];
    for( APLRegion *region in self.displayList ) {
        [region setDate:date];
    }
}

- (void)updateTimer:(NSTimer *)timer {
    NSArray *visibleCells = self.tableView.visibleCells;
    for( APLTimeZoneCell *cell in visibleCells ) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        [self configureCell:cell forIndexPath:indexPath];
        [cell setNeedsDisplay];
    }
}

- (NSArray *)regions {
    
    NSArray *timeZoneNames = [NSTimeZone knownTimeZoneNames];
    NSMutableArray *regionsList = [[NSMutableArray alloc] initWithCapacity:0];
    
    for( NSString *timeZoneName in timeZoneNames ) {
        
        NSArray *nameComponents = [timeZoneName componentsSeparatedByString:@"/"];
        NSString *regionName = nameComponents.firstObject;
        
        APLRegion *region = [APLRegion regionNamed:regionName];
        if( !region ) {
            region = [APLRegion newRegionWithName:regionName];
            region.calendar = self.calendar;
            [regionsList addObject:region];
        }
        
        NSTimeZone *timeZone = [[NSTimeZone alloc] initWithName:timeZoneName];
        [region addTimeZone:timeZone nameComponents:nameComponents];
    }
    
    //  Sort time zones by name
    NSDate *date = [[NSDate alloc] init];
    for( APLRegion *region in regionsList ) {
        [region sortZones];
        [region setDate:date];
    }
    
    //  Sort regions by name
    NSArray *sortedRegions = [regionsList sortedArrayUsingComparator:^NSComparisonResult(APLRegion* region1, APLRegion* region2) {
        NSString *name1 = region1.name;
        NSString *name2 = region2.name;
        return [name1 localizedStandardCompare:name2];
    }];
    
    return sortedRegions;
}

- (void)configureCell:(APLTimeZoneCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    APLRegion *region = self.displayList[indexPath.section];
    APLTimeZoneWrapper *timeZoneWrapper = (APLTimeZoneWrapper *)region.timeZoneWrappers[indexPath.row];
    
    //  Resizable Locale Name
    NSString *timeZoneLocaleName = ( timeZoneWrapper.timeZoneLocaleName ) ? timeZoneWrapper.timeZoneLocaleName : [region.name stringByAppendingString:@" Locale"];
    cell.nameLabel.text = timeZoneLocaleName;
    
    //  Resizable Detail Text Label
    cell.detailLabel.text = timeZoneWrapper.extendedDetailText;
    
    //  Time
    self.dateFormatter.timeZone = timeZoneWrapper.timeZone;
    cell.timeLabel.text = [self.dateFormatter stringFromDate:[NSDate date]];
    
    //  image
    cell.thumbnailImageView.image = timeZoneWrapper.image;
}

#pragma mark - UITableViewDatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.displayList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    APLRegion *region = self.displayList[section];
    return region.timeZoneWrappers.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    APLRegion *region = self.displayList[section];
    return region.name;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    APLTimeZoneCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellReuseIdentifierSelfSizingCell];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self update];
}

- (void)dealloc {
    [_minuteTimer invalidate];
}

@end
