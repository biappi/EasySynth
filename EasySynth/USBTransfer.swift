//
//  USBTransfer.swift
//  EasySynth
//
//  Created by Antonio Malara on 15/07/16.
//  Copyright © 2016 Antonio Malara. All rights reserved.
//

import Foundation

struct FTDIError : Error {
    let code : Int32
    let description : String
}

extension ftdi_context {
    func getErrorString() -> String {
        return String(cString: self.error_str) ?? ""
    }
}

class FTDIContext {
    let vendor  : UInt16
    let product : UInt16
    
    var context = ftdi_context()
    
    init (vendor: UInt16, product: UInt16) {
        ftdi_init(&context)
        
        self.vendor = vendor
        self.product = product
    }
    
    deinit {
        ftdi_usb_close(&context)
        ftdi_deinit(&context)
    }
    
    func open() throws {

        try _ = wrapError(ftdi_usb_open(&context, Int32(vendor), Int32(product)))
        try _ = wrapError(ftdi_usb_reset(&context))
        try _ = wrapError(ftdi_usb_purge_buffers(&context))

        try _ = wrapError(ftdi_set_latency_timer(&context, 1))
        try _ = wrapError(ftdi_write_data_set_chunksize(&context, 1))

    }
    
    func write(_ data: [UInt8]) throws {
        var temp = data
        try _ = wrapError(ftdi_write_data(&context, &temp, Int32(temp.count)))
    }

    
    func read(_ count: Int, timeout: Int = 30) throws -> [UInt8] {
        var buffer = [UInt8].init(repeating: 0, count: count)
        var received = 0
        var retryTimes = timeout * 100
        
        repeat {
            let read = try buffer[received..<buffer.count].withUnsafeMutableBufferPointer({ (x: inout UnsafeMutableBufferPointer<UInt8>) -> Int32 in
                try wrapError(ftdi_read_data(&context, x.baseAddress!, Int32(x.count)))
            })
            
            received += Int(read)
            
            if read == 0 {
                usleep(10000)
                retryTimes -= 1
            }
            
            if retryTimes == 0 {
                throw FTDIError(code: -1, description: "read timeout")
            }
        } while received < count
        
        return buffer
    }
    
    func wrapError(_ ret: Int32) throws -> Int32 {
        guard ret >= 0 else {
            throw FTDIError(code: ret, description: context.getErrorString())
        }
        return ret
    }
}

enum UploadType : String {
    case PRG = "EFSTART:PRG\0"
    case CRT = "EFSTART:CRT\0"
}

enum UploadFileEvent {
    case message(String)
    case completion
}

typealias FileEventObserver = (UploadFileEvent) -> Void

func uploadFileInBackground(_ type: UploadType, data: [UInt8], observer: FileEventObserver) {
    Thread() {
        uploadFile(type, data: data) { event in
            DispatchQueue.main.async(execute: { observer(event) })
        }
    }.start()
}

func uploadFile(_ type: UploadType, data: [UInt8], context: FTDIContext, observer: FileEventObserver) throws {
    observer(.message("Waiting for the cartridge to respond"))

    var waiting = false
    repeat {
        try context.write(type.rawValue.toBytes())
        
        let x = try context.read(5)
        let s = String(bytes: x, encoding: String.Encoding.utf8)
        
        waiting = s == "WAIT\0"
    } while waiting == true
    
    observer(.message("Sending data"))
    
    var sent = 0
    repeat {
        let s = try context.read(2)
        let requestedSize = Int(s[0]) + Int(s[1]) << 8
        
        let lengthToSend = min(data.count, requestedSize)
        try context.write([UInt8(lengthToSend & 0xff), UInt8(lengthToSend >> 8)])
        
        try context.write(Array(data[sent..<sent+lengthToSend]))
        sent += lengthToSend
    } while sent < data.count
    
    observer(.message("Transfer completed"))
}

func uploadFile(_ type: UploadType, data: [UInt8], observer: FileEventObserver) {
    do {
        observer(.message("Opening USB Interface"))
        
        let f = FTDIContext(vendor: 0x0403, product: 0x8738)
        
        try uploadFile(type, data: data, context: f, observer: observer)
    }
    catch {
        observer(.message("Error during transfer: \(error)"))
    }
    
    observer(.completion)
}

class Thread : Foundation.Thread {
    let callback: () -> Void
    
    init(aCallback: () -> Void) {
        callback = aCallback
    }
    
    override func main() {
        callback()
    }
}

extension Data {
    func toBytes() -> [UInt8] {
        return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>((self as NSData).bytes), count: self.count))
    }
}

extension String {
    func toBytes() -> [UInt8] {
        return self.data(using: String.Encoding.utf8)!.toBytes()
    }
}
