//
//  USB.swift
//  SwiftArm
//
//  Created by Rod Schmidt on 10/14/16.
//  Copyright © 2016 infiniteNIL. All rights reserved.
//

import Foundation

class USB {

    init?() {
        if libusb_init(nil) != LIBUSB_SUCCESS.rawValue {
            print("failed to initialize libusb")
            return nil
        }

        logLevel = .none
    }

    deinit {
        libusb_exit(nil)
    }
    
    enum LogLevel: Int {
        case none
        case error
        case warning
        case info
        case debug
    }

    var logLevel: LogLevel {
        didSet {
            libusb_set_debug(nil, Int32(logLevel.rawValue))
        }
    }

    func device(vendorID: UInt16, productID: UInt16) -> USBDevice? {
        //  libusb_device **devs;
        var devices: UnsafeMutablePointer<OpaquePointer?>?     // [libusb_device?]?
        let deviceCount = libusb_get_device_list(nil, &devices)

        guard deviceCount > 0, let usbDevices = devices else {
            return nil
        }
        defer { libusb_free_device_list(usbDevices, 1) }

        var deviceDescriptor = libusb_device_descriptor()

        var device = usbDevices
        while device.pointee != nil {
            let ok = libusb_get_device_descriptor(device.pointee, &deviceDescriptor) == 0
            if !ok {
                fputs("failed to get device descriptor", stderr)
                return nil
            }

            if deviceDescriptor.idVendor == vendorID && deviceDescriptor.idProduct == productID {
                return USBDevice(device.pointee!)
            }

            device = device.successor()
        }
        
        return nil
    }

}

class USBDevice {

    init(_ device: OpaquePointer) {
        self.device = device
    }

    deinit {
        close()
    }

    func open() -> Bool {
        guard deviceHandle == nil else { return true }  // already open

        //  struct libusb_device_handle *devh = NULL;
        var handle: OpaquePointer?    // libusb_device_handle?
        let result = libusb_open(device, &handle)
        if result != LIBUSB_SUCCESS.rawValue {
            print("Error opening device")
            return false
        }

        deviceHandle = handle
        return true
    }

    func close() {
        if deviceHandle != nil {
            libusb_close(deviceHandle!)
            deviceHandle = nil
        }
    }

    func send(requestType: UInt8, request: UInt8, value: UInt16, index: UInt16, commands: [UInt8]) -> Int32 {
        var cmd = commands
        print(String(format: "Sending %02X %02X %02X", Int(cmd[0]), Int(cmd[1]), Int(cmd[2])))

        let errorOrBytesTransferred = libusb_control_transfer(deviceHandle,
            requestType,    //uint8_t 	bmRequestType,
            request,        //uint8_t 	bRequest,
            value,          //uint16_t 	wValue,
            index,          //uint16_t 	wIndex,
            &cmd,
            UInt16(cmd.count),  // CMD_DATALEN,
            0)

        if errorOrBytesTransferred < 0 {
            print("Write err \(errorOrBytesTransferred).")
        }

        return errorOrBytesTransferred
    }

    private let device: OpaquePointer
    private var deviceHandle: OpaquePointer?
}

