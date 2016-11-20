//
//  AppDelegate.swift
//  EasySynth
//
//  Created by Antonio Malara on 20/11/16.
//  Copyright © 2016 Antonio Malara. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MidiClientDelegate {
    @IBOutlet weak var window: NSWindow!

    let midi = MidiClient(name: "C64")!
    let f = FTDIContext(vendor: 0x0403, product: 0x8738)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        midi.createClient()
        midi.delegate = self
        
        do {
            try f.open()
            try f.write([16, 15, 18, 3, 15, 4, 4, 9, 15])
        }
        catch {
            print("ERROR > \(error)")
        }
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    var porcoddio = 0
    
    func gotMidiPacket(_ midi: Data!) {
        let midiData = midi.toBytes()
        
        /*
         if midiData.count == 1 && midiData[0] == 0xf8 {
         
         print("\(porcoddio) \(midi)")
         
         if porcoddio % 12 == 0 {
         do {
         try f.write(midi.toBytes())
         }
         catch {
         print("ERROR > \(error)")
         }
         }
         
         porcoddio = porcoddio + 1
         }
         */
        if midiData.count == 3 && midiData[0] == 0x90 {
            do {
                let newNote = Int(midiData[1]) - 24
                if newNote >= 0 && newNote < (8 * 12) {
                    try f.write([0x90, UInt8(newNote)])
                }
            }
            catch {
                print("ERROR > \(error)")
            }
        }
        
        if midiData.count == 3 && midiData[0] == 0x80 {
            do {
                let newNote = Int(midiData[1]) - 24
                if newNote >= 0 && newNote < (8 * 12) {
                    try f.write([0x80, UInt8(newNote)])
                }
            }
            catch {
                print("ERROR > \(error)")
            }
            
        }
    }
}
