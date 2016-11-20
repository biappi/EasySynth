//
//  MidiClient.h
//  EasyCart
//
//  Created by Antonio Malara on 03/10/16.
//  Copyright © 2016 Antonio Malara. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MidiClientDelegate <NSObject>

- (void)gotMidiPacket:(NSData *)midi;

@end

@interface MidiClient : NSObject

@property(nonatomic, weak) id<MidiClientDelegate> delegate;

- (id)init __unavailable;
- (id)initWithName:(NSString *)theName;

- (void)createClient;

@end
