//
//  ViewController.m
//  NoninOximeterBluetooth
//
//  Created by James Yu on 8/9/16.
//  Copyright © 2016 James Yu. All rights reserved.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>

@implementation ViewController

NSString *sf_client_id = @"3MVG9szVa2RxsqBYmyhpPA4kGtEL7I.wh71flKx52ksRF9P3XW3gf8._WQZ4P043LvETPpHE3UmggetzlS0Rf";
NSString *sf_client_secret = @"2684527054782167756";
NSString *sf_username = @"james89@gmail.com";
NSString *sf_password = @"salesforce1";
NSString *sf_security_token = @"PdYqfjS9H9PT0q2ZZSVN9XLl";
NSString *sf_access_token;
NSString *sf_instanceUrl;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self m2x_clearStreamValues];
    
    _mBluetoothDeviceInquiry = [[IOBluetoothDeviceInquiry alloc] initWithDelegate:self];
    [_mBluetoothDeviceInquiry setInquiryLength:255];
    if([_mBluetoothDeviceInquiry start] != kIOReturnSuccess)
    {
        NSLog(@"Bluetooth inquiry failed to start");
    }
    
    [self salesforce_tokenReq];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)sf_createRecord_btnClick:(id)sender
{
    NSLog(@"SF Create Record clicked");
    [self sf_createRecord];
}

- (void)salesforce_tokenReq
{
    NSURL *url = [NSURL URLWithString:@"https://login.salesforce.com/services/oauth2/token"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:@"password" forKey:@"grant_type"];
    [dict setValue:sf_client_id forKey:@"client_id"];
    [dict setValue:sf_client_secret forKey:@"client_secret"];
    [dict setValue:sf_username forKey:@"username"];
    [dict setValue:sf_password forKey:@"password"];
    
    NSString *body = [NSString stringWithFormat:@"grant_type=password&client_id=%@&client_secret=%@&username=%@&password=%@%@", sf_client_id, sf_client_secret, sf_username, sf_password, sf_security_token];
    
    NSError *error;
    NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    if(!error)
    {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session uploadTaskWithRequest:request fromData:data
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                          // handle response
                          NSError *localError;
                          NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                          
                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                          if([httpResponse statusCode] == 200)
                          {
                              NSLog(@"Salesforce authentication success");
                              
                              sf_access_token = [parsedObject objectForKey:@"access_token"];
                              sf_instanceUrl = [parsedObject objectForKey:@"instance_url"];
                              
                              dispatch_async(dispatch_get_main_queue(), ^(void){
                                  [self sf_getResources];
                                  //[self sf_getObjectList];
                              });
                          }
                          else
                          {
                              NSLog(@"Salesforce authentication failed");
                          }
                      }] resume];
    }
}

- (void)sf_getResources
{
    NSString *url_string = [NSString stringWithFormat:@"%@/services/data/v37.0/", sf_instanceUrl];
    NSURL *url = [NSURL URLWithString:url_string];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", sf_access_token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"1" forHTTPHeaderField:@"X-PrettyPrint"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                      // handle response
                      NSError *localError;
                      NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                      
                      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                      if([httpResponse statusCode] == 200)
                      {
                          NSLog(@"Salesforce authentication success");
                      }
                      else
                      {
                          NSLog(@"Salesforce authentication failed");
                      }
                  }] resume];
}

- (void)sf_getObjectList
{
    NSString *url_string = [NSString stringWithFormat:@"%@/services/data/v37.0/sobjects/", sf_instanceUrl];
    NSURL *url = [NSURL URLWithString:url_string];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", sf_access_token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"1" forHTTPHeaderField:@"X-PrettyPrint"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    // handle response
                    NSError *localError;
                    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                    
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if([httpResponse statusCode] == 200)
                    {
                        NSLog(@"Salesforce authentication success");
                        [self sf_getObjectInfo];
                    }
                    else
                    {
                        NSLog(@"Salesforce authentication failed");
                    }
                }] resume];
}

- (void)sf_getObjectInfo
{
    NSString *url_string = [NSString stringWithFormat:@"%@/services/data/v37.0/sobjects/Sensor__c", sf_instanceUrl];
    NSURL *url = [NSURL URLWithString:url_string];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", sf_access_token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"1" forHTTPHeaderField:@"X-PrettyPrint"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    // handle response
                    NSError *localError;
                    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                    
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if([httpResponse statusCode] == 200)
                    {
                        NSLog(@"Salesforce authentication success");
                        [self sf_objectDesc];
                    }
                    else
                    {
                        NSLog(@"Salesforce authentication failed");
                    }
                }] resume];
}

- (void)sf_objectDesc
{
    NSString *url_string = [NSString stringWithFormat:@"%@/services/data/v37.0/sobjects/Sensor__c/describe", sf_instanceUrl];
    NSURL *url = [NSURL URLWithString:url_string];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", sf_access_token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"1" forHTTPHeaderField:@"X-PrettyPrint"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    // handle response
                    NSError *localError;
                    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                    
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if([httpResponse statusCode] == 200)
                    {
                        NSLog(@"Salesforce authentication success");
                        [self sf_queryTest];
                    }
                    else
                    {
                        NSLog(@"Salesforce authentication failed");
                    }
                }] resume];
}

- (void)sf_queryTest
{
    NSString *url_string = [NSString stringWithFormat:@"%@/services/data/v37.0/query?q=SELECT+name+from+Sensor__c", sf_instanceUrl];
    NSURL *url = [NSURL URLWithString:url_string];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", sf_access_token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"1" forHTTPHeaderField:@"X-PrettyPrint"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    // handle response
                    NSError *localError;
                    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                    
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if([httpResponse statusCode] == 200)
                    {
                        NSLog(@"Salesforce authentication success");
                        [self sf_createRecord];
                    }
                    else
                    {
                        NSLog(@"Salesforce authentication failed");
                    }
                }] resume];
}

- (void)sf_createRecord
{
    NSString *url_string = [NSString stringWithFormat:@"%@/services/data/v37.0/sobjects/Sensor__c", sf_instanceUrl];
    NSURL *url = [NSURL URLWithString:url_string];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", sf_access_token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"1" forHTTPHeaderField:@"X-PrettyPrint"];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:@"Pulse Ox" forKey:@"Name"];
    [dict setValue:[NSNumber numberWithInteger:56] forKey:@"Heart_rate__c"];
    [dict setValue:[NSNumber numberWithInteger:97] forKey:@"SpO2__c"];
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    [request setHTTPBody:data];
    NSLog(@"Request body %@", [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]);
    
    if(!error)
    {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session uploadTaskWithRequest:request fromData:data
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                          // handle response
                          NSError *localError;
                          NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                    
                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                          if([httpResponse statusCode] == 201)
                          {
                              NSLog(@"Salesforce record create success");
                          }
                          else
                          {
                              NSLog(@"Salesforce record create failed");
                          }
                      }] resume];
    }
}

- (void)sf_createNewPulseOxRecord:(NSInteger)heartRate spo2:(NSInteger)value
{
    NSString *url_string = [NSString stringWithFormat:@"%@/services/data/v37.0/sobjects/Sensor__c", sf_instanceUrl];
    //NSString *url_string = @"http://requestb.in/13ou9441";
    NSURL *url = [NSURL URLWithString:url_string];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", sf_access_token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"1" forHTTPHeaderField:@"X-PrettyPrint"];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:@"Pulse Ox" forKey:@"Name"];
    [dict setValue:[NSNumber numberWithInteger:heartRate] forKey:@"Heart_rate__c"];
    [dict setValue:[NSNumber numberWithInteger:value] forKey:@"SpO2__c"];
    [dict setValue:[self getCurrDate] forKey:@"Time__c"];
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    [request setHTTPBody:data];
    NSLog(@"Request body %@", [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]);
    NSLog(@"Headers %@", [request allHTTPHeaderFields]);
    
    if(!error)
    {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session uploadTaskWithRequest:request fromData:data
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                          // handle response
                          NSError *localError;
                          NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                          
                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                          if([httpResponse statusCode] == 201)
                          {
                              NSLog(@"Salesforce record creation successful");
                          }
                          else
                          {
                              NSLog(@"Salesforce record creation failed");
                          }
                      }] resume];
    }
}

- (NSString *)getCurrDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    NSDate *now = [NSDate date];
    return [dateFormatter stringFromDate:now];
}

- (void)deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry *)sender device:(IOBluetoothDevice *)device
{
    NSString *deviceName = [device name];
    NSLog(@"Found device: %@", deviceName);
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Muse-9"
                                                                           options:0
                                                                             error:&error];
    
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:deviceName
                                                        options:0
                                                          range:NSMakeRange(0, [deviceName length])];
    if (numberOfMatches > 0)
    {
        NSLog(@"Muse-9 found");
        _mBluetoothDevice = device;
        
        if([_mBluetoothDeviceInquiry stop] != kIOReturnSuccess)
        {
            NSLog(@"Bluetooth inquiry failed to stop");
        }
        
        IOBluetoothSDPUUID *sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
        IOBluetoothSDPServiceRecord *sppServiceRecord = [device getServiceRecordForUUID:sppServiceUUID];
        
        UInt8 rfcommChannelID;
        if ([sppServiceRecord getRFCOMMChannelID:&rfcommChannelID] != kIOReturnSuccess)
        {
            NSLog(@"Error - RFCOMM channel ID not found");
        }
        
        IOBluetoothRFCOMMChannel *tmpRFCOMMChannel;
        if (([device openRFCOMMChannelAsync:&tmpRFCOMMChannel withChannelID:rfcommChannelID delegate:self] != kIOReturnSuccess ))
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
        
        _mBluetoothDeviceInquiry = [[IOBluetoothDeviceInquiry alloc] initWithDelegate:self];
        [_mBluetoothDeviceInquiry setInquiryLength:255];
        [_mBluetoothDeviceInquiry updateNewDeviceNames];
        if([_mBluetoothDeviceInquiry start] != kIOReturnSuccess)
        {
            NSLog(@"Bluetooth inquiry failed to start");
        }
    }
}

- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel *)rfcommChannel status:(IOReturn)error
{
    if (error != kIOReturnSuccess)
    {
        NSLog(@"Error - Failed to open the RFCOMM channel");
        
        [self rfcommChannelClosed:rfcommChannel];
    }
    else
    {
        [_imgView_bluetooth setImage:[NSImage imageNamed:@"icon-bluetooth-on"]];
        [self sendStart];
    }
}

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
    unsigned char *dataBytes = (unsigned char *)dataPointer;
    NSData *dataData = [NSData dataWithBytes:dataPointer length:dataLength];
    NSLog(@"bytes in hex: %@", [dataData description]);
    
    NSString *string = [[NSString alloc] initWithData:dataData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", string);
    
    /*
    if(dataLength == 4)
    {
        unsigned int heartRate = dataBytes[1];
        unsigned int spO2 = dataBytes[2];
        NSLog(@"Heart rate = %d, SpO2 level = %d", heartRate, spO2);
        
        [_txtField_heartRate setStringValue:[NSString stringWithFormat:@"%d", heartRate]];
        [_txtField_spO2 setStringValue:[NSString stringWithFormat:@"%d", spO2]];
        
        [self m2x_updateHeartRate:[_txtField_heartRate stringValue]];
        [self m2x_updateSpO2:[_txtField_spO2 stringValue]];
        
        //[self sf_createNewPulseOxRecord:(NSInteger)heartRate spo2:(NSInteger)spO2];
    }
     */
}

- (void)sendStart
{
    uint8_t buffer[20];
    
    buffer[0] = 0x76;
    buffer[1] = 0x20;
    buffer[2] = 0x32;
    buffer[3] = 0x0d;
    
    buffer[4] = 0x25;
    buffer[5] = 0x20;
    
    buffer[6] = 0x31;
    buffer[7] = 0x30;
    
    buffer[8] = 0x0d;
    
    buffer[9] = 0x73;
    buffer[10] = 0x20;
    buffer[11] = 0x35;
    buffer[12] = 0x0d;
    
    // Synchronously write the data to the channel.
    if([_mRFCOMMChannel writeSync:&buffer length:13] != kIOReturnSuccess)
    {
        NSLog(@"Send start failed");
    }
    else
    {
        NSLog(@"Start sent");
    }
}

- (void)m2x_clearStreamValues
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    
    NSDate *endDate = [NSDate date];
    NSDate *fromDate = [endDate dateByAddingTimeInterval:-365*24*60*60];
    NSString *fromDateString = [dateFormatter stringFromDate:fromDate];
    NSString *endDateString = [dateFormatter stringFromDate:endDate];
    
    [self m2x_clearHeartRateValues:fromDateString to:endDateString];
    [self m2x_clearSpO2Values:fromDateString to:endDateString];
}

- (void)m2x_clearHeartRateValues:(NSString *)fromDate to:(NSString *)endDate
{
    NSURL *url = [NSURL URLWithString:@"http://api-m2x.att.com/v2/devices/734950b169aa6ef338dd834d2c8ad09f/location/waypoints"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"DELETE";
    [request setValue:@"237fe381dde3294cd2675e20bdbc4f97" forHTTPHeaderField:@"X-M2X-KEY"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *dict = @{@"from": fromDate, @"end": endDate};
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    if(!error)
    {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session uploadTaskWithRequest:request fromData:data
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                          // handle response
                          NSError *localError;
                          NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                          
                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                          if([httpResponse statusCode] == 204)
                          {
                              NSLog(@"M2X: Heart rate values cleared");
                          }
                          else
                          {
                              NSLog(@"M2X: Heart rate values not cleared");
                          }
                      }] resume];
    }
}

- (void)m2x_clearSpO2Values:(NSString *)fromDate to:(NSString *)endDate
{
    NSURL *url = [NSURL URLWithString:@"http://api-m2x.att.com/v2/devices/55aefbdcb5e7e0e6c188d24b6500dbe0/streams/SpO2/values"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"DELETE";
    [request setValue:@"15958ed3adb6b4a2cad43f98dadfb089" forHTTPHeaderField:@"X-M2X-KEY"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *dict = @{@"from": fromDate, @"end": endDate};
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    if(!error)
    {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session uploadTaskWithRequest:request fromData:data
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                          // handle response
                          // NSError *localError;
                          // NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                          
                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                          if([httpResponse statusCode] == 204)
                          {
                              NSLog(@"M2X: SpO2 values cleared");
                          }
                          else
                          {
                              NSLog(@"M2X: SpO2 values not cleared");
                          }
                      }] resume];
    }
}

- (void)m2x_updateHeartRate:(NSString *)heartRate
{
    NSURL *url = [NSURL URLWithString:@"http://api-m2x.att.com/v2/devices/55aefbdcb5e7e0e6c188d24b6500dbe0/streams/HeartRate/value"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"PUT";
    [request setValue:@"15958ed3adb6b4a2cad43f98dadfb089" forHTTPHeaderField:@"X-M2X-KEY"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *dict = @{@"value": heartRate};
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    if(!error)
    {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session uploadTaskWithRequest:request fromData:data
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                          // handle response
                          // NSError *localError;
                          // NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                          
                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                          if([httpResponse statusCode] == 202)
                          {
                              // NSLog(@"M2X success");
                          }
                          else
                          {
                              // NSLog(@"M2X fail");
                          }
                      }] resume];
    }
}

- (void)m2x_updateSpO2:(NSString *)spO2
{
    NSURL *url = [NSURL URLWithString:@"http://api-m2x.att.com/v2/devices/55aefbdcb5e7e0e6c188d24b6500dbe0/streams/SpO2/value"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"PUT";
    [request setValue:@"15958ed3adb6b4a2cad43f98dadfb089" forHTTPHeaderField:@"X-M2X-KEY"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *dict = @{@"value": spO2};
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    if(!error)
    {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session uploadTaskWithRequest:request fromData:data
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                          // handle response
                          // NSError *localError;
                          // NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
                          
                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                          if([httpResponse statusCode] == 202)
                          {
                              // NSLog(@"M2X success");
                          }
                          else
                          {
                              // NSLog(@"M2X fail");
                          }
                      }] resume];
    }
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel *)rfcommChannel
{
    [_imgView_bluetooth setImage:[NSImage imageNamed:@"icon-bluetooth-off"]];
    
    [self performSelector:@selector(closeDeviceConnection:) withObject:_mBluetoothDevice afterDelay:5.0];
}

@end
