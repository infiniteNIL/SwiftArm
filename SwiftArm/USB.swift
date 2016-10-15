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
        let unreferenceDevices: Int32 = 1
        let device_list = UnsafeMutablePointer(mutating: devices.baseAddress)
        libusb_free_device_list(device_list, unreferenceDevices)

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
        let device = devices.first { device -> Bool in
            var deviceDescriptor = libusb_device_descriptor()
            let ok = libusb_get_device_descriptor(device, &deviceDescriptor) == LIBUSB_SUCCESS.rawValue
            if !ok { fatalError("failed to get device descriptor") }

            return deviceDescriptor.idVendor == vendorID &&
                   deviceDescriptor.idProduct == productID
        }

        if let foundDevice = device {
            return USBDevice(foundDevice!)
        }
        else {
            print("Unable to find device")
            return nil
        }
    }

    private lazy var devices: UnsafeBufferPointer<OpaquePointer?> = {
        var devices: UnsafeMutablePointer<OpaquePointer?>?
        let deviceCount = libusb_get_device_list(nil, &devices)
        if deviceCount < 0 {
            fatalError("Unable to get list of USB devices")
        }
        return UnsafeBufferPointer(start: devices, count: deviceCount)
    }()

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
        var cmds = commands

        let unlimitedTimeout: UInt32 = 0

        let errorOrBytesTransferred = libusb_control_transfer(deviceHandle,
            requestType,        // uint8_t 	bmRequestType,
            request,            // uint8_t 	bRequest,
            value,              // uint16_t wValue,
            index,              // uint16_t wIndex,
            &cmds,
            UInt16(cmds.count),
            unlimitedTimeout)

        if errorOrBytesTransferred < 0 {
            print("Write err \(errorOrBytesTransferred).")
        }

        return errorOrBytesTransferred
    }

    private let device: OpaquePointer
    private var deviceHandle: OpaquePointer?
}

