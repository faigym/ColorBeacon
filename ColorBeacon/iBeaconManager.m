//
//  iBeaconManager.m
//  BeaconConnectionClient
//
//  Created by Luis Abreu on 22/02/2014.
//  Copyright (c) 2014 lmjabreu. All rights reserved.
//

#import "iBeaconManager.h"

static NSString * const kDefaultProximityUUIDString = @"8180E9A0-5C69-4754-A54F-A529F4A38344";
static NSString * const kDefaultRegionIdentifier = @"com.lmjabreu.ColorBeacon";

@interface iBeaconManager () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation iBeaconManager

+ (instancetype)sharedInstance
{
    static iBeaconManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if (self == [super init]) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
    }
    return self;
}

- (void)startRangingBeaconsWithProximityUUID:(NSString *)proximityUUIDString identifier:(NSString *)regionIdentifier
{
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:proximityUUIDString];

    // I belong to this major group (Apple) proximityUUID - I belong to this region (eg: Apple Store)
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID
                                                                      identifier:regionIdentifier];
    beaconRegion.notifyEntryStateOnDisplay = YES;
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];
}

- (void)startRanginBeaconsInDefaultRegion
{
    [self startRangingBeaconsWithProximityUUID:kDefaultProximityUUIDString
                                    identifier:kDefaultRegionIdentifier];
}

- (void)startRanginBeaconsInDefaultRegionWithDelegate:(id<CLLocationManagerDelegate>)delegate
{
    [self startRanginBeaconsInDefaultRegion];
    self.delegate = delegate;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:@"Failed to start ranging"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:@"Got it"
                      otherButtonTitles:nil] show];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if ([self.delegate respondsToSelector:@selector(locationManager:didRangeBeacons:inRegion:)]) {
        [self.delegate locationManager:manager didRangeBeacons:beacons inRegion:region];
    }
}

@end
