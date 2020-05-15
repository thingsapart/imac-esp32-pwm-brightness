import Foundation
import ORSSerial

class SerialHandler: NSObject, NSUserNotificationCenterDelegate {
    @objc let serialPortManager = ORSSerialPortManager.shared()
    
    override init() {
        super.init()
    }
    
    func availableSerialPorts() -> [ORSSerialPort] {
        return ORSSerialPortManager.shared().availablePorts
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }

    func postUserNotification(text: String) {
        let unc = NSUserNotificationCenter.default
        let userNote = NSUserNotification()
        let title = "ESP32 PWM Brightness Controller"
        userNote.title = NSLocalizedString(title, comment: title)
        userNote.informativeText = text;
        userNote.soundName = nil;
        print("\(title) :: \(text)")
        unc.deliver(userNote)
    }
}
