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
        guard let usb = USB() else {
            return nil
        }

        self.usb = usb

        usb.logLevel = .warning

        let ARM_VENDOR: UInt16 = 0x1267
        let ARM_PRODUCT: UInt16 = 0

        arm = usb.device(vendorID: ARM_VENDOR, productID: ARM_PRODUCT)
        if arm == nil {
            print("Robot arm not found")
            return nil
        }

        if !arm.open() {
            print("Can't connect to arm")
            return nil
        }
    }

    deinit {
        light(on: false)
        allStop()
        arm.close()
        arm = nil
    }

    func allStop() {
        commands[0] = 0
        commands[1] = 0
        send()
    }

    func openGrip() {
        commands[0] &= 0xFC		// Turn off bit 1+2
        commands[0] |= 0x02		// Grip Open
        send()
    }

    func closeGrip() {
        commands[0] &= 0xFC		// Turn off bit 1+2
        commands[0] |= 0x01		// Grip Close
        send()
    }

    func stopGrip() {
        commands[0] &= 0xFC		// Turn off bit 1+2
        send()
    }

    func light(on: Bool) {
        commands[2] = on ? 1 : 0
        send()
    }

    func moveElbow(direction: JointDirection) {
        commands[0] &= 0xCF		// Turn off bit 5+6

        switch direction {
            case .up:   commands[0] |= 0x10		// Elbow Up
            case .down: commands[0] |= 0x20		// Elbow Down
            default:    break
        }

        send()
    }

    func moveShoulder(direction: JointDirection) {
        commands[0] &= 0x3F		// Turn off bit 7+8

        switch direction {
            case .up:   commands[0] |= 0x40		// Shoulder Up
            case .down: commands[0] |= 0x80		// Shoulder Down
            case .none: break
        }

        send()
    }

    func moveWrist(direction: JointDirection) {
        commands[0] &= 0xF3		// Turn off bit 3+4

        switch direction {
            case .up:   commands[0] |= 0x04		// Wrist Up
            case .down: commands[0] |= 0x08		// Wrist Down
            case .none: break
        }

        send()
    }

    func rotateBase(direction: RotationDirection) {
        switch direction {
            case .clockwise:        commands[1] = 1
            case .counterClockwise: commands[1] = 2
            default:                commands[1] = 0
        }

        send()
    }

    private func send() {
        print(String(format: "Sending %02X %02X %02X", Int(commands[0]), Int(commands[1]), Int(commands[2])))

        let result = arm.send(requestType: UInt8(LIBUSB_REQUEST_TYPE_VENDOR.rawValue),
                              request: 6,
                              value: 0x100,
                              index: 0,
                              commands: commands)

        if result < 0 || result != Int32(commands.count) {
            print("Error sending commands to arm")
        }
    }

    private let usb: USB
    private var arm: USBDevice!
    private(set) var commands: [UInt8] = [0, 0, 0]
}
