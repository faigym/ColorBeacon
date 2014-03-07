//
//  iBeaconManager.h
//  BeaconConnectionClient
//
//  Created by Luis Abreu on 22/02/2014.
//  Copyright (c) 2014 lmjabreu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface iBeaconManager : NSObject

@property (nonatomic, strong) id<CLLocationManagerDelegate>delegate;

+ (instancetype)sharedInstance;

- (void)startRangingBeaconsWithProximityUUID:(NSString *)proximityUUIDString identifier:(NSString *)regionIdentifier;

#pragma mark Convenience methods

- (void)startRanginBeaconsInDefaultRegion;
- (void)startRanginBeaconsInDefaultRegionWithDelegate:(id<CLLocationManagerDelegate>)delegate;

@end
