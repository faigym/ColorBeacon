//
//  MainViewController.m
//  ColorBeacon
//
//  Created by Luis Abreu on 07/03/2014.
//  Copyright (c) 2014 lmjabreu. All rights reserved.
//

#import "MainViewController.h"
#import "iBeaconManager.h"
#import <SimpleAudioPlayer.h>
@import AVFoundation;

static NSString * const kBeaconsKeyPath = @"beacons";

// Absolute RSSI values: (max - min)
static CGFloat const kBeaconRSSIAbsoluteMax = 80.0f;
static CGFloat const kBeaconRSSIAbsoluteMin = 30.0f;
static CGFloat const kBeaconRSSIRange = (kBeaconRSSIAbsoluteMax - kBeaconRSSIAbsoluteMin);

NSInteger RSSIPercentValue(NSInteger oldValue)
{
    NSInteger oldAbsoluteValue = ABS(oldValue);
    NSInteger oldNormalizedValue = (oldAbsoluteValue - kBeaconRSSIAbsoluteMax);
    NSInteger percentValue = ((oldNormalizedValue * 100.0f) / kBeaconRSSIRange);

    return ABS(percentValue);
};

@interface MainViewController () <CLLocationManagerDelegate>
@property (nonatomic, strong) NSArray *beacons;
@property (weak, nonatomic) IBOutlet UILabel *beaconOneRSSILabel;
@property (weak, nonatomic) IBOutlet UILabel *beaconTwoRSSILabel;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) NSString *currentTrack;
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
    if (!beacon) { return [UIColor grayColor]; }

    if ([beacon.minor isEqualToNumber:@(1)]) { beaconColor = [UIColor redColor]; }
    if ([beacon.minor isEqualToNumber:@(2)]) { beaconColor = [UIColor greenColor]; }

    CGFloat hue, saturation, brightness, alpha;
    [beaconColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

    // -30 to -70; -30 == 0; -40 == 0.2
    NSInteger RSSI = RSSIPercentValue(beacon.rssi);
    saturation = RSSI/100.0f;

    beaconColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];

    return beaconColor;
}

- (void)updateRSSILabels
{
    [self.beacons enumerateObjectsUsingBlock:^(CLBeacon *currentBeacon, NSUInteger idx, BOOL *stop) {
        UILabel *beaconLabel = ([currentBeacon.minor isEqualToNumber:@(1)]) ? self.beaconOneRSSILabel : self.beaconTwoRSSILabel;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSString *beaconLabelText = [NSString stringWithFormat:@"%ld, (%ld%%)",
                                         (long)currentBeacon.rssi,
                                         (long)RSSIPercentValue(currentBeacon.rssi)];

            beaconLabel.text = beaconLabelText;
        }];
    }];
}

- (CLBeacon *)nearestBeacon
{
    __block CLBeacon *beacon;
    NSInteger minRSSI = [[self.beacons valueForKeyPath:@"@max.rssi"] integerValue];
    [self.beacons enumerateObjectsUsingBlock:^(CLBeacon *currentBeacon, NSUInteger idx, BOOL *stop) {
        beacon = (currentBeacon.rssi == minRSSI) ? currentBeacon : nil;
        *stop = YES;
    }];

    return beacon;
}

- (void)playAudioForBeacon:(CLBeacon *)beacon
{
    //
    NSString *filename;
    if ([beacon.minor isEqualToNumber:@(1)]) { filename = @"kids.mp3"; }
    if ([beacon.minor isEqualToNumber:@(2)]) { filename = @"lounge.mp3"; }

    if (self.currentTrack != filename) {
        self.currentTrack = filename;
        [SimpleAudioPlayer stopAllPlayers];
        self.audioPlayer = [SimpleAudioPlayer playFile:filename volume:1 loops:-1];
    }

    if (self.audioPlayer) {
        CGFloat volume = RSSIPercentValue(beacon.rssi);
        self.audioPlayer.volume = volume;
    }
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
    // Update the label
    [self updateRSSILabels];
    // Play the correct audio
    [self playAudioForBeacon:nearestBeacon];
}

@end
