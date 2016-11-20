//
//  MidiClient.m
//  EasyCart
//
//  Created by Antonio Malara on 03/10/16.
//  Copyright © 2016 Antonio Malara. All rights reserved.
//

#import "MidiClient.h"
#import <CoreMIDI/CoreMIDI.h>

static void InputPortCallback (const MIDIPacketList *pktlist, void *refCon, void *connRefCon);

@interface MidiClient()
{
    MIDIClientRef   client;
    
    MIDIEndpointRef source;
    MIDIEndpointRef destination;
    
    NSString       * name;

}

@property(nonatomic, readonly) uint8_t  * sysexPrefix;

/* - */

- (void)sendNoteOn:(uint8_t)channel note:(uint8_t)note velocity:(uint8_t)velocity;

- (void)sendMidiBytes:(uint8_t *)bytes count:(size_t)count;

@end

@implementation MidiClient

- (id)initWithName:(NSString *)theName;
{
    if ((self = [super init]) == nil)
        return nil;
    
    name = [theName copy];
    
    return self;
}

- (void)createClient;
{
    CFStringRef cfname = (__bridge CFStringRef)name;
    SInt32 uniqueId = (SInt32) name.hash;
    
    MIDIClientCreate(cfname, NULL, NULL, &client);
    MIDIObjectSetIntegerProperty(client, kMIDIPropertyUniqueID, uniqueId);
    
    MIDISourceCreate(client, cfname, &source);
    MIDIObjectSetIntegerProperty(source, kMIDIPropertyUniqueID, uniqueId + 1);
    
    MIDIDestinationCreate(client, cfname, InputPortCallback, (__bridge void * _Nullable)(self), &destination);
    MIDIObjectSetIntegerProperty(destination, kMIDIPropertyUniqueID, uniqueId + 2);
}

/* - */

- (void)sendNoteOn:(uint8_t)channel note:(uint8_t)note velocity:(uint8_t)velocity;
{
    unsigned char reply[] = { 0x90 | (channel & 0x0F), note, velocity };
    [self sendMidiBytes:reply count:sizeof(reply)];
}


- (void)sendMidiBytes:(uint8_t *)bytes count:(size_t)count;
{
    char packetListData[1024];
    
    MIDIPacketList * packetList = (MIDIPacketList *)packetListData;
    MIDIPacket     * curPacket  = NULL;
    
    curPacket = MIDIPacketListInit(packetList);
    curPacket = MIDIPacketListAdd(packetList, 1024, curPacket, 0, count, bytes);
    
    MIDIReceived(source, packetList);
}

@end

static void InputPortCallback(const MIDIPacketList * pktlist, void * refCon, void * connRefCon)
{
    MIDIPacket        * packet = (MIDIPacket *)pktlist->packet;
    MidiClient        * zelf   = (__bridge MidiClient *)refCon;
    
    @autoreleasepool {
        for (unsigned int j = 0; j < pktlist->numPackets; j++)
        {
            //uint8_t * d = packet->data;
            //uint8_t   c = d[0] & 0xF0;
            
            [zelf.delegate gotMidiPacket:[NSData dataWithBytes:packet->data length:packet->length]];
            
            packet = MIDIPacketNext(packet);		
        }
    }
}
