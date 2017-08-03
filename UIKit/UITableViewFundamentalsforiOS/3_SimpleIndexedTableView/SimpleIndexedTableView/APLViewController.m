
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller that serves as the table view's data source and delegate. It uses the current UILocalizedIndexedCollation object to organize the time zones into appropriate sections, and also to provide information about section titles and section index titles.
 */

#import "APLViewController.h"
#import "APLAppDelegate.h"
#import "APLTimeZoneWrapper.h"

// The sections array and the collation are private.
@interface APLViewController ()

@property (nonatomic, strong) NSArray *timeZonesArray;
@property (nonatomic, strong) NSMutableArray *sectionsArray;
@property (nonatomic, strong) UILocalizedIndexedCollation *collation;

- (void)configureSections;

@end

@implementation APLViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.timeZonesArray = [self regions];
}

#pragma mark - Workers

- (NSArray *)regions {
    /*
     Create an array of time zone wrappers and pass to the root view controller.
     */
    NSArray *timeZoneNames = [NSTimeZone knownTimeZoneNames];
    NSMutableArray *timeZones = [[NSMutableArray alloc] initWithCapacity:timeZoneNames.count];
    
    for (NSString *timeZoneName in timeZoneNames) {
        
        NSArray *nameComponents = [timeZoneName componentsSeparatedByString:@"/"];
        // For this example, the time zone itself isn't needed.
        APLTimeZoneWrapper *timeZoneWrapper = [[APLTimeZoneWrapper alloc] initWithTimeZone:nil nameComponents:nameComponents];
        
        [timeZones addObject:timeZoneWrapper];
    }
    
    return  timeZones;
}

/*
 Configuring the sections is a little fiddly, and it's not directly relevant to understanding how sectioned table views themselves work, so there's no need to work though these methods if you don't want to.
 */

- (void)setTimeZonesArray:(NSMutableArray *)newDataArray {
    
	if (newDataArray != _timeZonesArray) {
		_timeZonesArray = [newDataArray mutableCopy];
        if (_timeZonesArray == nil) {
            self.sectionsArray = nil;
        }
        else {
            [self configureSections];
        }
	}
}

- (void)configureSections {

	// Get the current collation and keep a reference to it.
	self.collation = [UILocalizedIndexedCollation currentCollation];

	NSInteger index, sectionTitlesCount = self.collation.sectionTitles.count;

	NSMutableArray *newSectionsArray = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];

	// Set up the sections array: elements are mutable arrays that will contain the time zones for that section.
	for (index = 0; index < sectionTitlesCount; index++) {
		NSMutableArray *array = [[NSMutableArray alloc] init];
		[newSectionsArray addObject:array];
	}

	// Segregate the time zones into the appropriate arrays.
	for (APLTimeZoneWrapper *timeZone in self.timeZonesArray) {

		// Ask the collation which section number the time zone belongs in, based on its locale name.
		NSInteger sectionNumber = [self.collation sectionForObject:timeZone collationStringSelector:@selector(timeZoneLocaleName)];

		// Get the array for the section.
		NSMutableArray *sectionTimeZones = newSectionsArray[sectionNumber];

		//  Add the time zone to the section.
		[sectionTimeZones addObject:timeZone];
	}

	// Now that all the data's in place, each section array needs to be sorted.
	for (index = 0; index < sectionTitlesCount; index++) {

		NSMutableArray *timeZonesArrayForSection = newSectionsArray[index];

		// If the table view or its contents were editable, you would make a mutable copy here.
		NSArray *sortedTimeZonesArrayForSection = [self.collation sortedArrayFromArray:timeZonesArrayForSection collationStringSelector:@selector(timeZoneLocaleName)];

		// Replace the existing array with the sorted array.
		newSectionsArray[index] = sortedTimeZonesArrayForSection;
	}

	self.sectionsArray = newSectionsArray;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // The number of sections is the same as the number of titles in the collation.
    return self.collation.sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // The number of time zones in the section is the count of the array associated with the section in the sections array.
    NSArray *timeZonesInSection = self.sectionsArray[section];
    
    return timeZonesInSection.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"MyIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Get the time zone from the array associated with the section index in the sections array.
    NSArray *timeZonesInSection = self.sectionsArray[indexPath.section];
    
    // Configure the cell with the time zone's name.
    APLTimeZoneWrapper *timeZone = timeZonesInSection[indexPath.row];
    cell.textLabel.text = timeZone.timeZoneLocaleName;
    
    return cell;
}

/*
 Section-related methods: Retrieve the section titles and section index titles from the collation.
 */

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.collation.sectionTitles[section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.collation.sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.collation sectionForSectionIndexTitleAtIndex:index];
}

@end
