SwiftArm
=========

Controls the OWI robot arm with Swift 3.

**Example:**

```swift
let arm = OWIRobot()
arm.light(on: true)
arm.light(on: false)

arm.allStop()

arm.moveElbow(direction: .up)
arm.moveElbow(direction: .down)
arm.moveElbow(direction: .none)

arm.moveShoulder(direction: .up)
arm.moveShoulder(direction: .down)
arm.moveShoulder(direction: .none)

arm.moveWrist(direction: .up)
arm.moveWrist(direction: .down)
arm.moveWrist(direction: .none)

arm.openGrip()
arm.closeGrip()
arm.stopGrip()

arm.rotateBase(direction: .clockwise)
arm.rotateBase(direction: .counterClockwise)
arm.rotateBase(direction: .none)
```

**Dependencies**

Requires libusb to be installed. On Raspberry Pi you can do that with:

```
sudo apt-get install libusb-1.0
```

On Mac OS X do:

```
brew install libusb
```

You are using brew, aren't you? ;)

**References**

Two references helped me to get this working

- Simple Controller for the OWI / Maplin USB Robot Arm Kit on Mac OS X (https://armctrl.codeplex.com)

- OWI Robotic Arm Protocol (http://notbrainsurgery.livejournal.com/38622.html). Vadim Zaliva reference engineered the protocol and published online for all to use. Thanks Vadim!
