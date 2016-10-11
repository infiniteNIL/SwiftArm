//
//  OWIRobotArm.swift
//  SwiftArm
//
//  Created by Rod Schmidt on 10/9/16.
//  Copyright © 2016 infiniteNIL. All rights reserved.
//

import Foundation

class OWIRobotArm {

    enum RotationDirection {
        case none
        case clockwise
        case counterClockwise
    }

    enum JointDirection {
        case none
        case up
        case down
    }

    init?() {
        var ok = libusb_init(nil) == 0
        if !ok {
            print("failed to initialize libusb")
            return nil
        }

        libusb_set_debug(nil, 2)

        //  libusb_device **devs;
        var devices: UnsafeMutablePointer<OpaquePointer?>?     // [libusb_device?]?
        let deviceCount = libusb_get_device_list(nil, &devices)

        guard deviceCount > 0, let usbDevices = devices else {
            libusb_exit(nil)
            return nil
        }

        //  libusb_device *dev;
        guard let dev = find_arm(usbDevices) else {
            print("Robot Arm not found")
            libusb_free_device_list(usbDevices, 1)
            libusb_exit(nil)
            return nil
        }

        //  struct libusb_device_handle *devh = NULL;
        var arm: OpaquePointer?    // libusb_device_handle?
        ok = libusb_open(dev.pointee, &arm) == 0
        if !ok {
            print("Error opening device")
            libusb_free_device_list(usbDevices, 1)
            libusb_exit(nil)
            return nil
        }

        libusb_free_device_list(usbDevices, 1)
        armDeviceHandle = arm!
    }

    deinit {
        libusb_close(armDeviceHandle)
        libusb_exit(nil)
    }

    func allStop() {
        commands[0] = 0
        commands[1] = 0
        send(commands: commands)
    }

    func openGrip() {
        commands[0] &= 0xFC		// Turn off bit 1+2
        commands[0] |= 0x02		// Grip Open
        send(commands: commands)
    }

    func closeGrip() {
        commands[0] &= 0xFC		// Turn off bit 1+2
        commands[0] |= 0x01		// Grip Close
        send(commands: commands)
    }

    func stopGrip() {
        commands[0] &= 0xFC		// Turn off bit 1+2
        send(commands: commands)
    }

    func light(on: Bool) {
        commands[2] = on ? 1 : 0
        send(commands: commands)
    }

    func moveElbow(direction: JointDirection) {
        commands[0] &= 0xCF		// Turn off bit 5+6

        switch direction {
            case .up:   commands[0] |= 0x10		// Elbow Up
            case .down: commands[0] |= 0x20		// Elbow Down
            default:    break
        }

        send(commands: commands)
    }

    func moveShoulder(direction: JointDirection) {
        commands[0] &= 0x3F		// Turn off bit 7+8

        switch direction {
            case .up:   commands[0] |= 0x40		// Shoulder Up
            case .down: commands[0] |= 0x80		// Shoulder Down
            case .none: break
        }

        send(commands: commands)
    }

    func moveWrist(direction: JointDirection) {
        commands[0] &= 0xF3		// Turn off bit 3+4

        switch direction {
            case .up:   commands[0] |= 0x04		// Wrist Up
            case .down: commands[0] |= 0x08		// Wrist Down
            case .none: break
        }

        send(commands: commands)
    }

    func rotateBase(direction: RotationDirection) {
        switch direction {
            case .clockwise:        commands[1] = 1
            case .counterClockwise: commands[1] = 2
            default:                commands[1] = 0
        }

        send(commands: commands)
    }

    private(set) var commands: [UInt8] = [0, 0, 0]
    fileprivate let armDeviceHandle: OpaquePointer
}

private let ARM_VENDOR: UInt16 = 0x1267
private let ARM_PRODUCT: UInt16 = 0
private let CMD_DATALEN: UInt16 = 3

fileprivate extension OWIRobotArm {

    func send(commands: [UInt8]) {
        var cmd = commands
        print(String(format: "Sending %02X %02X %02X", Int(cmd[0]), Int(cmd[1]), Int(cmd[2])))

        let errorOrBytesTransferred = libusb_control_transfer(armDeviceHandle,
                                                              0x40,   //uint8_t 	bmRequestType,
                                                              6,      //uint8_t 	bRequest,
                                                              0x100,  //uint16_t 	wValue,
                                                              0,      //uint16_t 	wIndex,
                                                              &cmd,
                                                              CMD_DATALEN,
                                                              0)

        if errorOrBytesTransferred < 0 {
            print("Write err \(errorOrBytesTransferred).")
        }
    }

}

//libusb_device * find_arm(libusb_device **devs)
private func find_arm(_ devices: UnsafePointer<OpaquePointer?>) -> UnsafePointer<OpaquePointer?>? {
    var deviceDescriptor = libusb_device_descriptor()

    var device = devices
    while device.pointee != nil {
        let ok = libusb_get_device_descriptor(device.pointee, &deviceDescriptor) == 0
        if !ok {
            fputs("failed to get device descriptor", stderr)
            return nil
        }

        if deviceDescriptor.idVendor == ARM_VENDOR && deviceDescriptor.idProduct == ARM_PRODUCT {
            return device
        }

        device = device.successor()
    }

    return nil
}
