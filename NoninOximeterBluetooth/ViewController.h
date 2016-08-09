//
//  ViewController.h
//  NoninOximeterBluetooth
//
//  Created by James Yu on 8/9/16.
//  Copyright © 2016 James Yu. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothDeviceInquiry.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>

@interface ViewController : NSViewController <IOBluetoothDeviceInquiryDelegate>

@property (nonatomic, retain) IOBluetoothDevice         *mBluetoothDevice;
@property (nonatomic, retain) IOBluetoothRFCOMMChannel  *mRFCOMMChannel;

@property IBOutlet NSTextField  *txtField_heartRate;
@property IBOutlet NSTextField  *txtField_spO2;

@end

