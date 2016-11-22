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

struct Poke {
    let address: UInt16
    let byte:    UInt8
    
    init (_ address: UInt16, _ byte: UInt8) {
        self.address = address
        self.byte    = byte
    }
    
    func toCommand() -> [UInt8] {
        return [UInt8( address & 0x00ff      ),
                UInt8((address & 0xff00) >> 8),
                byte]
    }
}

let SID : UInt16 = 0xd400
let sidInit = [
    Poke(SID + 24, 0x0f), // volume
    Poke(SID +  1, 0x20), // freq
    Poke(SID +  5, 0x08), // AD
    Poke(SID +  6, 0x00), // SR
    Poke(SID +  4, 0x00), // * DING *
    Poke(SID +  4, 0x11), // * DING *
]

struct SidVoice {
    var tri:   Bool   =   true
    var saw:   Bool   =  false
    var pulse: Bool   =  false
    var noise: Bool   =  false

    var a:     UInt8  =   0x00
    var d:     UInt8  =   0x0f
    var s:     UInt8  =   0x00
    var r:     UInt8  =   0x00
    var width: UInt16 = 0x0800
    
    var ad:    UInt8  { return (self.a << 4) | self.d }
    var sr:    UInt8  { return (self.s << 4) | self.r }
    
    var ctrl:  UInt8  { return (self.noise ? 0b10000000 : 0) |
                               (self.pulse ? 0b01000000 : 0) |
                               (self.saw   ? 0b00100000 : 0) |
                               (self.tri   ? 0b00010000 : 0) }
    
    var pulseLo: UInt8 { return UInt8( self.width       & 0xff) }
    var pulseHi: UInt8 { return UInt8((self.width >> 8) & 0xff) }
}


func noteOn(note: Int, voice: SidVoice) -> [Poke] {
    return [
        Poke(SID + 0, frequenciesLow  [note]),
        Poke(SID + 1, frequenciesHigh [note]),
        Poke(SID + 2, voice.pulseLo),
        Poke(SID + 3, voice.pulseHi),

        Poke(SID + 5, voice.ad),
        Poke(SID + 6, voice.sr),
        //Poke(SID + 4, voice.ctrl + 0x00),
        Poke(SID + 4, voice.ctrl + 0x01),
    ]
}

func noteOff(voice: SidVoice) -> [Poke] {
    return [Poke(SID + 4, voice.ctrl + 0x00)]
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MidiClientDelegate {
    @IBOutlet weak var window:   NSWindow!
    
    @IBOutlet weak var triangle: NSButton!
    @IBOutlet weak var saw:      NSButton!
    @IBOutlet weak var pulse:    NSButton!
    @IBOutlet weak var noise:    NSButton!
    
    @IBOutlet weak var a:        NSSlider!
    @IBOutlet weak var d:        NSSlider!
    @IBOutlet weak var s:        NSSlider!
    @IBOutlet weak var r:        NSSlider!
    @IBOutlet weak var w:        NSSlider!
    
    let midi = MidiClient(name: "C64")!
    let f = FTDIContext(vendor: 0x0403, product: 0x8738)
    
    var voice = SidVoice()
    var currentNote: Int?

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        midi.createClient()
        midi.delegate = self
        
        do {
            try f.open()
            try f.write(sidInit.flatMap { $0.toCommand() })
        }
        catch {
            print("ERROR > \(error)")
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    override func awakeFromNib() {
        setUi(voice: voice)
    }
    
    func setUi(voice: SidVoice) {
        a.integerValue = Int(voice.a)
        d.integerValue = Int(voice.d)
        s.integerValue = Int(voice.s)
        r.integerValue = Int(voice.r)
        w.integerValue = Int(voice.width)
        
        triangle.intValue = voice.tri   ? 1 : 0
        saw.intValue      = voice.saw   ? 1 : 0
        pulse.intValue    = voice.pulse ? 1 : 0
        noise.intValue    = voice.noise ? 1 : 0
    }
    
    @IBAction func test(_ sender: AnyObject) {
        let pokes = noteOn(note: frequenciesLow.count / 2 , voice: voice)
        print("\(pokes)")
        
        let bytes = pokes.flatMap { $0.toCommand() }
        print("\(bytes)")
        
        try? f.write(bytes)
        //print("\(voice)\n\(x)")
    }
    
    @IBAction func valueChanged(_ sender: AnyObject) {
        guard let theSender = sender as? NSControl else { return }
        
        let nibble  = { (control: NSControl) in UInt8 (control.integerValue &   0x0f) }
        let twelve  = { (control: NSControl) in UInt16(control.integerValue & 0x0fff) }
        let boolean = { (control: NSControl) in control.integerValue != 0 }
        
        if theSender == a { voice.a     = nibble(theSender) }
        if theSender == d { voice.d     = nibble(theSender) }
        if theSender == s { voice.s     = nibble(theSender) }
        if theSender == r { voice.r     = nibble(theSender) }
        
        if theSender == w { voice.width = twelve(theSender) }
        
        if theSender == triangle { voice.tri   = boolean(theSender) }
        if theSender == saw      { voice.saw   = boolean(theSender) }
        if theSender == pulse    { voice.pulse = boolean(theSender) }
        if theSender == noise    { voice.noise = boolean(theSender) }
    }

    func gotMidiPacket(_ midi: Data!) {
        let midiData = midi.toBytes()
        
        if midiData.count == 3 && (midiData[0] == 0x90 && midiData[2] != 0) {
            do {
                let newNote = Int(midiData[1]) - 24
                if newNote >= 0 && newNote < (8 * 12) {
                    try f.write(noteOn(note: newNote, voice: voice).flatMap { $0.toCommand() })
                    currentNote = newNote
                }
            }
            catch {
                print("ERROR > \(error)")
            }
        }
        
        else if midiData.count == 3 && (midiData[0] == 0x80 || (midiData[0] == 0x90 && midiData[2] == 0)) {
            do {
                let newNote = Int(midiData[1]) - 24
                if let currentNote = currentNote, newNote >= 0 && newNote < (8 * 12) {
                    if currentNote == newNote {
                        try f.write(noteOff(voice: voice).flatMap { $0.toCommand() })
                    }
                }
            }
            catch {
                print("ERROR > \(error)")
            }
        }
        
        else if midiData.count == 3 && midiData[0] == 176 {
            let toNibble = { (x : UInt8) in UInt8 ((Double(x) / 127.0) *   0x0f) }
            let toTwelve = { (x : UInt8) in UInt16((Double(x) / 127.0) * 0x0fff) }
            
            if midiData[1] == 59 {
                voice.a = toNibble(midiData[2])
            }
            else if midiData[1] == 60 {
                voice.d = toNibble(midiData[2])
            }
            else if midiData[1] == 61 {
                voice.s = toNibble(midiData[2])
            }
            else if midiData[1] == 63 {
                voice.r = toNibble(midiData[2])
            }
            else if midiData[1] == 37 {
                voice.width = toTwelve(midiData[2])
            }

            else {
                print (midiData[1])
            }
        }
            
        else {
            print (midiData)
        }
        
        DispatchQueue.main.async {
            self.setUi(voice: self.voice)
        }
        
    }
}
