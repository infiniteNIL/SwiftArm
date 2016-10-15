//
//  AppDelegate.swift
//  SwiftArm
//
//  Created by Rod Schmidt on 10/8/16.
//  Copyright © 2016 infiniteNIL. All rights reserved.
//

import Cocoa

//#include "arm_command_usb.h"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    @IBOutlet weak var byte0: NSTextField!
    @IBOutlet weak var byte1: NSTextField!
    @IBOutlet weak var byte2: NSTextField!

    @IBOutlet weak var segBase: NSSegmentedControl!
    @IBOutlet weak var segShoulder: NSSegmentedControl!
    @IBOutlet weak var segElbow: NSSegmentedControl!
    @IBOutlet weak var segWrist: NSSegmentedControl!
    @IBOutlet weak var segGrip: NSSegmentedControl!
    @IBOutlet weak var segLight: NSSegmentedControl!

    private var robotArm = OWIRobotArm()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        updateDisplay()
    }

    func applicationWillTerminate(_ notification: Notification) {
        robotArm = nil
    }

    @IBAction func segControlClicked(_ sender: NSSegmentedControl) {
        let segment = sender.selectedSegment
        let direction = self.direction(for: sender.selectedSegment)

        switch sender {
            case segLight:
                robotArm?.light(on: segment == 0)

            case segBase:
                robotArm?.rotateBase(direction: rotateDirection(for: segment))

            case segShoulder:
                robotArm?.moveShoulder(direction: direction)

            case segElbow:
                robotArm?.moveElbow(direction: direction)

            case segWrist:
                robotArm?.moveWrist(direction: direction)

            case segGrip:
                operateGrip()

            default:
                break
        }

        updateDisplay()
    }

    private func operateGrip() {
        switch segGrip.selectedSegment {
            case 0:     robotArm?.openGrip()
            case 2:     robotArm?.closeGrip()
            default:    robotArm?.stopGrip()
        }
    }

    @IBAction func allStopClicked(_ sender: Any) {
        robotArm?.allStop()

        segBase.selectedSegment = 1
        segShoulder.selectedSegment = 1
        segElbow.selectedSegment = 1
        segWrist.selectedSegment = 1
        segGrip.selectedSegment = 1

        updateDisplay()
    }

    private func updateDisplay() {
        byte0.stringValue = String(format: "%02x", robotArm?.commands[0] ?? 0)
        byte1.stringValue = String(format: "%02x", robotArm?.commands[1] ?? 0)
        byte2.stringValue = String(format: "%02x", robotArm?.commands[2] ?? 0)
    }

    private func rotateDirection(for segment: Int) -> OWIRobotArm.RotationDirection {
        switch segment {
        case 0: return .clockwise
        case 2: return .counterClockwise
        default: return .none
        }
    }

    private func direction(for segment: Int) -> OWIRobotArm.JointDirection {
        switch segment {
        case 0:     return .up
        case 2:     return .down
        default:    return .none
        }

    }

}

