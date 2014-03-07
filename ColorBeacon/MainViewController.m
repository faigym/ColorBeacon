//
//  MainViewController.m
//  ColorBeacon
//
//  Created by Luis Abreu on 07/03/2014.
//  Copyright (c) 2014 lmjabreu. All rights reserved.
//

#import "MainViewController.h"
#import "iBeaconManager.h"
@import AVFoundation;

static NSString * const kBeaconsKeyPath = @"beacons";

@interface MainViewController () <CLLocationManagerDelegate>
@property (nonatomic, strong) NSArray *beacons;
@property (weak, nonatomic) IBOutlet UILabel *beaconOneRSSILabel;
@property (weak, nonatomic) IBOutlet UILabel *beaconTwoRSSILabel;
@end

@implementation MainViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self addObserver:self forKeyPath:kBeaconsKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [[iBeaconManager sharedInstance] startRanginBeaconsInDefaultRegionWithDelegate:self];
}

#pragma mark - Helpers

- (UIColor *)colorForBeacon:(CLBeacon *)beacon
{
    UIColor *beaconColor;
    if (!beacon) { return [UIColor blackColor]; }

    if ([beacon.minor isEqualToNumber:@(1)]) { beaconColor = [UIColor redColor]; }
    if ([beacon.minor isEqualToNumber:@(2)]) { beaconColor = [UIColor greenColor]; }

    CGFloat hue, saturation, brightness, alpha;
    [beaconColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

    // -30 to -70
    NSInteger RSSI = ABS(beacon.rssi);

    beaconColor = [UIColor colorWithHue:hue saturation:RSSI*0.01f brightness:brightness alpha:alpha];

    return beaconColor;
}

- (CLBeacon *)nearestBeacon
{
    __block CLBeacon *beacon;
    NSInteger minRSSI = [[self.beacons valueForKeyPath:@"@max.rssi"] integerValue];
    [self.beacons enumerateObjectsUsingBlock:^(CLBeacon *currentBeacon, NSUInteger idx, BOOL *stop) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if ([currentBeacon.minor isEqualToNumber:@(1)]) { self.beaconOneRSSILabel.text = [@(currentBeacon.rssi) stringValue]; }
            if ([currentBeacon.minor isEqualToNumber:@(2)]) { self.beaconTwoRSSILabel.text = [@(currentBeacon.rssi) stringValue]; }
        }];

        beacon = (currentBeacon.rssi == minRSSI) ? currentBeacon : nil;
        *stop = YES;
    }];

    return beacon;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:kBeaconsKeyPath]) {
        [self updateViewForBeacons];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    self.beacons = beacons;
};

#pragma mark - View Methods

- (void)updateViewForBeacons
{
    // Get the closest beacon based on RSSI for finer detail
    CLBeacon *nearestBeacon = [self nearestBeacon];
    // Get the color for the beacon
    UIColor *beaconColor = [self colorForBeacon:nearestBeacon];
    // Apply the color to the current view
    [UIView animateWithDuration:.5f animations:^{
        self.view.backgroundColor = beaconColor;
    }];
}

@end
