//
//  ViewController.m
//  NoninOximeterBluetooth
//
//  Created by James Yu on 8/9/16.
//  Copyright © 2016 James Yu. All rights reserved.
//

#import "ViewController.h"

IOBluetoothDeviceInquiry *mBluetoothDeviceInquiry;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    mBluetoothDeviceInquiry = [[IOBluetoothDeviceInquiry alloc] initWithDelegate:self];
    if([mBluetoothDeviceInquiry start] != kIOReturnSuccess)
    {
        NSLog(@"Bluetooth inquiry failed to start");
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry *)sender device:(IOBluetoothDevice *)device
{
    NSString *deviceName = [device name];
    NSLog(@"Found device: %@", deviceName);
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Nonin_Medical_Inc._[0-9]{6}"
                                                                           options:0
                                                                             error:&error];
    
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:deviceName
                                                        options:0
                                                          range:NSMakeRange(0, [deviceName length])];
    if (numberOfMatches > 0)
    {
        NSLog(@"Nonnin medical found");
        _mBluetoothDevice = device;
        
        if([mBluetoothDeviceInquiry stop] != kIOReturnSuccess)
        {
            NSLog(@"Bluetooth inquiry failed to stop");
        }
        
        IOBluetoothSDPUUID *sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
        IOBluetoothSDPServiceRecord	*sppServiceRecord = [device getServiceRecordForUUID:sppServiceUUID];
        
        BluetoothRFCOMMChannelID *rfcommChannelID;
        if ([sppServiceRecord getRFCOMMChannelID:rfcommChannelID] != kIOReturnSuccess)
        {
            NSLog(@"Error - RFCOMM channel ID not found");
        }
        
        IOBluetoothRFCOMMChannel *tmpRFCOMMChannel;
        if (([device openRFCOMMChannelAsync:&tmpRFCOMMChannel withChannelID:*rfcommChannelID delegate:self] != kIOReturnSuccess ))
        {
            NSLog(@"Error - Failed to open RFCOMM channel");
            
            [self closeDeviceConnection:device];
        }
        
        _mRFCOMMChannel = tmpRFCOMMChannel;
    }
}

- (void)closeDeviceConnection:(IOBluetoothDevice *)device
{
    if (_mBluetoothDevice == device)
    {
        if ([_mBluetoothDevice closeConnection] != kIOReturnSuccess)
        {
            NSLog(@"Error - Failed to close the device connection");
        }
        
        _mBluetoothDevice = nil;
    }
}

- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel *)rfcommChannel status:(IOReturn)error
{
    if (error != kIOReturnSuccess)
    {
        NSLog(@"Error - Failed to open the RFCOMM channel");
        
        [self rfcommChannelClosed:rfcommChannel];
    }
}

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
    unsigned char *dataBytes = (unsigned char *)dataPointer;
    
    if(dataLength == 4)
    {
        NSLog(@"Heart rate = %d, Sp02 level = %d", dataBytes[1], dataBytes[2]);
    }
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel *)rfcommChannel
{
    [self performSelector:@selector(closeDeviceConnection:) withObject:_mBluetoothDevice afterDelay:1.0];
}

@end
