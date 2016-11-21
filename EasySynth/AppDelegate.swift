//
//  AppDelegate.swift
//  EasySynth
//
//  Created by Antonio Malara on 20/11/16.
//  Copyright © 2016 Antonio Malara. All rights reserved.
//

import Cocoa

let frequenciesLow : [UInt8] = [
    0x17, 0x27, 0x39, 0x4b, 0x5f, 0x74, 0x8a, 0xa1, 0xba, 0xd4, 0xf0, 0x0e,
    0x2d, 0x4e, 0x71, 0x96, 0xbe, 0xe8, 0x14, 0x43, 0x74, 0xa9, 0xe1, 0x1c,
    0x5a, 0x9c, 0xe2, 0x2d, 0x7c, 0xcf, 0x28, 0x85, 0xe8, 0x52, 0xc1, 0x37,
    0xb4, 0x39, 0xc5, 0x5a, 0xf7, 0x9e, 0x4f, 0x0a, 0xd1, 0xa3, 0x82, 0x6e,
    0x68, 0x71, 0x8a, 0xb3, 0xee, 0x3c, 0x9e, 0x15, 0xa2, 0x46, 0x04, 0xdc,
    0xd0, 0xe2, 0x14, 0x67, 0xdd, 0x79, 0x3c, 0x29, 0x44, 0x8d, 0x08, 0xb8,
    0xa1, 0xc5, 0x28, 0xcd, 0xba, 0xf1, 0x78, 0x53, 0x87, 0x1a, 0x10, 0x71,
    0x42, 0x89, 0x4f, 0x9b, 0x74, 0xe2, 0xf0, 0xa6, 0x0e, 0x33, 0x20, 0xff,
]

let frequenciesHigh : [UInt8] = [
    0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02,
    0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x03, 0x04,
    0x04, 0x04, 0x04, 0x05, 0x05, 0x05, 0x06, 0x06, 0x06, 0x07, 0x07, 0x08,
    0x08, 0x09, 0x09, 0x0a, 0x0a, 0x0b, 0x0c, 0x0d, 0x0d, 0x0e, 0x0f, 0x10,
    0x11, 0x12, 0x13, 0x14, 0x15, 0x17, 0x18, 0x1a, 0x1b, 0x1d, 0x1f, 0x20,
    0x22, 0x24, 0x27, 0x29, 0x2b, 0x2e, 0x31, 0x34, 0x37, 0x3a, 0x3e, 0x41,
    0x45, 0x49, 0x4e, 0x52, 0x57, 0x5c, 0x62, 0x68, 0x6e, 0x75, 0x7c, 0x83,
    0x8b, 0x93, 0x9c, 0xa5, 0xaf, 0xb9, 0xc4, 0xd0, 0xdd, 0xea, 0xf8, 0xff,
]

func poke(lo: UInt8, hi: UInt8, byte: UInt8) -> [UInt8] {
    return [lo, hi, byte]
}

func poke(_ addr: UInt16, _ byte: UInt8) -> [UInt8] {
    return poke(lo:   UInt8( addr & 0x00ff      ),
                hi:   UInt8((addr & 0xff00) >> 8),
                byte: byte)
}

let SID : UInt16 = 0xd400
let sidInit = [
    poke(SID + 24, 0x0f), // volume
    poke(SID +  1, 0x20), // freq
    poke(SID +  5, 0x08), // AD
    poke(SID +  6, 0x00), // SR
    poke(SID +  4, 0x00), // * DING *
    poke(SID +  4, 0x11), // * DING *
    poke(0xd020, 14)
]


func noteOn(note: Int, ad: UInt8, sr: UInt8) -> [UInt8] {
    return [
        poke(SID + 0, frequenciesLow[note]),
        poke(SID + 1, frequenciesHigh[note]),
        poke(SID + 5, ad), // AD
        poke(SID + 6, sr), // SR

        // poke(SID + 4, 0x00),
        poke(SID + 4, 0x11),
    ].flatMap { $0 }
}

let noteOff = poke(SID + 4, 0)

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
            try f.write(Array(sidInit.flatten()))
        }
        catch {
            print("ERROR > \(error)")
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    var notes = 0
    var A = 0
    var D = 8
    var S = 0
    var R = 0
    
    func gotMidiPacket(_ midi: Data!) {
        let midiData = midi.toBytes()
        
        if midiData.count == 3 && midiData[0] == 0x90 {
            do {
                let newNote = Int(midiData[1]) - 24
                if newNote >= 0 && newNote < (8 * 12) {
                    let ad = UInt8((A << 4) | D)
                    let sr = UInt8((S << 4) | R)
                    try f.write(noteOn(note: newNote, ad: ad, sr: sr))
                    notes += 1
                }
            }
            catch {
                print("ERROR > \(error)")
            }
        }
        
        else if midiData.count == 3 && midiData[0] == 0x80 {
            do {
                let newNote = Int(midiData[1]) - 24
                if newNote >= 0 && newNote < (8 * 12) {
                    notes -= 1
                    if notes == 0 {
                        try f.write(noteOff)
                    }
                }
            }
            catch {
                print("ERROR > \(error)")
            }
            
        }
        
        else if midiData.count == 3 && midiData[0] == 176 {
            let toNibble = { (x : UInt8) in Int((Double(x) / 127.0) * 15) }
            
            if midiData[1] == 59 {
                A = toNibble(midiData[2])
            }
            else if midiData[1] == 60 {
                D = toNibble(midiData[2])
            }
            else if midiData[1] == 61 {
                S = toNibble(midiData[2])
            }
            else if midiData[1] == 63 {
                R = toNibble(midiData[2])
            }
            else {
                print (midiData[1])
            }
        }
            
        else {
            print (midiData)
        }
    }
}
