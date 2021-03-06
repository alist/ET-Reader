//
//  ETBTLEManager.m
//  ET Reader
//
//  Created by Alexander Hoekje List on 11/24/13.
//  Copyright (c) 2013 ET Ears Group, Inc (MIT LICENSE). All rights reserved.
//

#import "ETBTLEManager.h"

@implementation ETBTLEManager

-(void) start{
    self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    EXOLog(@"startScan");
    NSArray	*uuidArray = [NSArray arrayWithObject:[CBUUID UUIDWithString:kBLEShieldServiceUUIDString]];
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [self.cbManager scanForPeripheralsWithServices:uuidArray options:options];
}

-(void) connectPeripheral{
    if (self.peripherals.count >0)
        [self.cbManager connectPeripheral:[self.peripherals anyObject] options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

-(void) disconnectPeripheral{
    if (self.connectedPeripheral != nil && [self.connectedPeripheral state] != CBPeripheralStateDisconnected){
         [self.cbManager cancelPeripheralConnection:self.connectedPeripheral];
    }
}

-(NSMutableSet*) peripherals{
    if (_peripherals == nil){
        _peripherals = [NSMutableSet set];
    }
    
    return _peripherals;
}

-(void) sendDataToPeripheral:(NSData*)data{
    if (!data){
        EXOLog(@"Send error %@", @"no data to send");
        return;
    }else
    
    if ([self.connectedPeripheral state] == CBPeripheralStateConnected){
        [ETBTLEManager writeCharacteristic:self.connectedPeripheral sUUID:kBLEShieldServiceUUIDString cUUID:kBLEShieldCharacteristicTXUUIDString data:data];
        
        EXOLog(@"sent that datas %@", data);
    }else{
        EXOLog(@"Send error %@", @"no connected peripheral");
    }

}

#pragma mark -
#pragma mark CBCentralManagerDelegate methods

/*
 *  @method centralManagerDidUpdateState:
 *
 *  @param central The central whose state has changed.
 *
 *  @discussion Invoked whenever the central's state has been updated.
 *      See the "state" property for more information.
 *
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOff) {
        EXOLog(@"centralManagerDidUpdateState: %@", @"powered off");
    }
    else if (central.state == CBCentralManagerStatePoweredOn) {
        EXOLog(@"centralManagerDidUpdateState: %@", @"powered on");
    }
}


/*
 *  @method centralManager:didRetrievePeripheral:
 *
 *  @discussion Invoked when the central retrieved a list of known peripherals.
 *      See the -[retrievePeripherals:] method for more information.
 *
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    EXOLog(@"%@",@"didRetrievePeripherals");
}

/*
 *  @method centralManager:didRetrieveConnectedPeripherals:
 *
 *  @discussion Invoked when the central retrieved the list of peripherals currently connected to the system.
 *      See the -[retrieveConnectedPeripherals] method for more information.
 *
 */
- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripheralArray {
    EXOLog(@"%@",@"didRetrieveConnectedPeripherals");
}

/*
 *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 *
 *  @discussion Invoked when the central discovered a peripheral while scanning.
 *      The advertisement / scan response data is stored in "advertisementData", and
 *      can be accessed through the CBAdvertisementData* keys.
 *      The peripheral must be retained if any command is to be performed on it.
 *
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    EXOLog(@"Discovered: %@", peripheral.name);
    
    [self.peripherals addObject:peripheral];
    
}

/*
 *  @method centralManager:didConnectPeripheral:
 *
 *  @discussion Invoked whenever a connection has been succesfully created with the peripheral.
 *
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    EXOLog(@"didConnectPeripheral %@",peripheral);
    
    self.connectedPeripheral = peripheral;
    self.connectedPeripheral.delegate = self;
    [self.connectedPeripheral discoverServices:nil];
}

/*
 *  @method centralManager:didFailToConnectPeripheral:error:
 *
 *  @discussion Invoked whenever a connection has failed to be created with the peripheral.
 *      The failure reason is stored in "error".
 *
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    EXOLog(@"didFailToConnectPeripheral %@",peripheral);
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CONNECT_BLE_SHIELD_FAILURE object:peripheral];
}

/*
 *  @method centralManager:didDisconnectPeripheral:error:
 *
 *  @discussion Invoked whenever an existing connection with the peripheral has been teared down.
 *
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    EXOLog(@"didDisconnectPeripheral %@",peripheral);
    
    if (self.connectedPeripheral == peripheral){
        self.connectedPeripheral = nil;
    }
    
    if (error != nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Disconnect Error", @"") message:error.localizedDescription delegate:self cancelButtonTitle:NSLocalizedString(@"OK",@"") otherButtonTitles: nil];
        [alert show];
    }
    else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Disconnected", @"") message:peripheral.name delegate:self cancelButtonTitle:NSLocalizedString(@"OK",@"") otherButtonTitles: nil];
        [alert show];
    }
}


#pragma mark -
#pragma mark peripherals

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    EXOLog(@"didDiscoverServices");
    
    for (CBService *service in peripheral.services ) {
        
        CBUUID *serviceUUID = [CBUUID UUIDWithString:kBLEShieldServiceUUIDString];
        
        if ([service.UUID isEqual:serviceUUID]) {
            EXOLog(@"Discovering Characteristics for service: %@", serviceUUID);
            [self.connectedPeripheral discoverCharacteristics:nil forService:service];
        }
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    EXOLog(@"didDiscoverCharacteristicsForService %@",service);

    [ETBTLEManager setNotificationForCharacteristic:self.connectedPeripheral sUUID:kBLEShieldServiceUUIDString cUUID:kBLEShieldCharacteristicRXUUIDString enable:YES];
}

/*
 *  @method peripheral:didUpdateValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    EXOLog(@"didUpdateValueForCharacteristic %@",characteristic);
    
    
    //NSDate *date = [NSDate date];
    NSData *data = [characteristic value];
    
//    NSString * dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
//    EXOLog(@"Data: %@", dataString);
    
    [self.dataDelegate managerYieldedData:data withManager:self];
}

/*
 *  @method peripheral:didWriteValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link writeValue:forCharacteristic: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    EXOLog(@"didWriteValueForCharacteristic %@", characteristic);
}

/*
 *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    EXOLog(@"didUpdateNotificationStateForCharacteristic %@", characteristic);
}





#pragma mark - static methods
+(void)writeCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID data:(NSData *)data {
    // Sends data to BLE peripheral to process HID and send EHIF command to PC
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    /* EVERYTHING IS FOUND, WRITE characteristic ! */
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                    
                }
            }
        }
    }
}

+(void)readCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID {
    for ( CBService *service in peripheral.services ) {
        if([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    /* Everything is found, read characteristic ! */
                    [peripheral readValueForCharacteristic:characteristic];
                }
            }
        }
    }
}

+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID enable:(BOOL)enable {
    for (CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]])
                {
                    /* Everything is found, set notification ! */
                    [peripheral setNotifyValue:enable forCharacteristic:characteristic];
                }
            }
        }
    }
}


@end
