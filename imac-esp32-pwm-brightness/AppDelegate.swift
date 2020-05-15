//  https://github.com/passatgt/imac-pwm-control
//
//  AppDelegate.swift
//

import Cocoa
import MediaKeyTap

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSTextFieldDelegate {

    @IBOutlet weak var menuView: NSMenu!
    @IBOutlet weak var SettingsButton: NSButton!
    @IBOutlet weak var ConnectionIndicator: NSButton!
    @IBOutlet weak var SettingsWindow: NSWindow!
    @IBOutlet weak var BrightnessSlider: NSSlider!
    @IBOutlet weak var SerialPortCombo: NSComboBox!
    @IBOutlet weak var SerialBaudCombo: NSComboBox!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var windowController: NSWindowController!
    let settings = UserDefaults.standard
    
    var timer: Timer? = nil
    var currentGamma = Float(1.0)
    var mediaKeyTap: MediaKeyTap?
    
    let serialHandler = SerialHandler()
    var serialPorts: [ORSSerialPort] = []
    var serialPort: ORSSerialPort? = nil
    var baud = 115200
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Bundle.main.loadNibNamed("Menu", owner: self, topLevelObjects: nil)

        //Set menubar icon
        let icon = NSImage(named: "mainIcon")
        icon?.isTemplate = true // best for dark mode
        statusItem.image = icon
        
        //Create a new menu item for the slider
        let sliderItem = NSMenuItem()
        sliderItem.title = ""
        sliderItem.view = BrightnessSlider
        menuView.addItem(sliderItem)
        
        //Add parameters to the slider
        BrightnessSlider.target = self
        BrightnessSlider.action = #selector(sliderChange)
        
        //Add settings button to the bottom of the slider
        SettingsButton.setFrameSize(NSSize(width: 24, height: 24))
        SettingsButton.frame.size.width = 24
        let menuItemSettings = NSMenuItem()
        menuItemSettings.view = SettingsButton
        menuView.addItem(menuItemSettings)
        
        ConnectionIndicator.setFrameSize(NSSize(width: 24, height: 24))
        ConnectionIndicator.frame.size.width = 24
        let menuItemConn = NSMenuItem()
        menuItemConn.view = ConnectionIndicator
        menuView.addItem(menuItemConn)

        //Init the settings window
        windowController = NSWindowController()
        windowController.contentViewController = SettingsWindow.contentViewController
        windowController.window = SettingsWindow

        //Show menu
        statusItem.menu = menuView
        
        let currentVal = settings.string(forKey: "brightness") ?? ""
        BrightnessSlider.stringValue = currentVal.isEmpty ? "100" : currentVal
        
        //Media keys listener
        self.startMediaKeyOnAccessibiltiyApiChange()
        self.startMediaKeyTap()
        
        // Serial Ports
        initSerial()
        serialPorts = serialHandler.availableSerialPorts()
        
        // Load saved settings
        let baud = settings.integer(forKey: "serial_baud")
        self.baud = (baud > 0) ? baud : 115200
        self.SerialBaudCombo.stringValue = String(self.baud)
        let port = settings.string(forKey: "serial_port")
        self.serialPort = self.serialPorts.first(where: { $0.path == port})

        if self.serialPort == nil {
            self.openSettings(self)
        } else {
            SerialPortCombo.stringValue = port ?? ""
            self.serialConnect()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let port = self.serialPort {
            if port.isOpen { port.close() }
        }
    }
    
    //On slider change
    @IBAction func sliderChange(_ sender:Any) {
        settings.set(BrightnessSlider.stringValue, forKey: "brightness")
        print(serialPort?.isOpen ?? "serial port not set")
        updatePwmValue(value: BrightnessSlider.floatValue)
    }
    
    //Open settings window
    @IBAction func openSettings(_ sender: Any) {
        windowController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    //Quit button
    @IBAction func QuitApp(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    //Quit button
    @IBAction func CloseSettings(_ sender: Any) {
        if self.serialPort == nil {
            self.serialHandler.postUserNotification(text: "No ESP32 serial port selected, brightness adjustment will not work.")
            updateConnectionStatus()
        } else {
            self.serialConnect()
        }
        windowController.close()
    }
    
    func updatePwmValue(value: Float) {
        if self.serialPort?.isOpen == true {
            let payload = "\(Int(value))\n".data(using: .utf8)
            self.serialPort?.send(payload!)
        } else {
            set_gamma(value: value/100)
        }
    }
    
    //Set screen's gamma table to reduce brigthness
    func set_gamma(value: Float) {
        if(value > 0.1) {
            CGSetDisplayTransferByTable(CGMainDisplayID(), 2, [0, value], [0, value], [0, value])
        } else {
            CGSetDisplayTransferByTable(CGMainDisplayID(), 2, [0, 0.1], [0, 0.1], [0, 0.1])
        }
    }
    
    //If accessibility api changes, try to start media key listener
    private func startMediaKeyOnAccessibiltiyApiChange() {
        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name(rawValue: "com.apple.accessibility.api"), object: nil, queue: nil) { _ in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(100)) {
                self.startMediaKeyTap()
            }
        }
    }
    
    private func serialConnect() {
        if let port = self.serialPort {
            port.delegate = self
            port.baudRate = NSNumber(value: self.baud)
            port.parity = .none
            port.numberOfStopBits = 1
            port.numberOfDataBits = 8
            port.usesRTSCTSFlowControl = false
            port.usesDTRDSRFlowControl = false
            port.usesDCDOutputFlowControl = false
            port.open()
            
            if !port.isOpen {
                let path = serialPort?.path ?? "<unknown>"
                self.serialHandler.postUserNotification(text: "Could not connect to serial port \(path).")
            }
        } else {
            self.serialHandler.postUserNotification(text: "Could not connect to serial port.")
        }
        
        let brightness = settings.string(forKey: "brightness") ?? ""
        if (!brightness.isEmpty) {
            updatePwmValue(value: Float(brightness) ?? 100)
        }
        updateConnectionStatus()
    }
    
    func updateConnectionStatus() {
        ConnectionIndicator.image = (self.serialPort?.isOpen == true)
            ? NSImage(named: "NSStatusAvailable")
            : NSImage(named: "NSStatusUnavailable")
    }
}

extension AppDelegate: NSComboBoxDataSource, NSComboBoxDelegate {
    func numberOfItems(in comboBox: NSComboBox) -> Int{
        return self.serialPorts.count
    }
    
   func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return self.serialPorts[index].path
    }
    
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        return self.serialPorts.firstIndex(where: { $0.path == string}) ?? -1
    }

    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        var returnString = ""
        for serialPort in self.serialPorts {
            let dataString = serialPort.path
            if dataString.commonPrefix(with: string).count > 0 {
                returnString = dataString
                return returnString
            }
        }
        return returnString
    }

    func comboBoxWillPopUp(_ notification: Notification) {
        self.serialPorts = self.serialHandler.availableSerialPorts()
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let combobox = notification.object as! NSComboBox
        
        if combobox == self.SerialPortCombo {
            let index = combobox.indexOfSelectedItem
            self.serialPort = self.serialPorts[index]
            settings.set(self.serialPort?.path, forKey: "serial_port")
        } else if combobox == self.SerialBaudCombo {
            self.baud = Int(combobox.itemObjectValue(at: combobox.indexOfSelectedItem) as! String) ?? 115200
            settings.set(self.baud, forKey: "serial_baud")
        }
    }
}

extension AppDelegate: ORSSerialPortDelegate {
    func initSerial() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(serialPortsWereConnected(_:)), name: NSNotification.Name.ORSSerialPortsWereConnected, object: nil)
    }

    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        let path = self.serialPort?.path ?? "<last used>"
        self.serialHandler.postUserNotification(text: "Serial port \(path) disconnected from system.")
        self.serialPort = nil
        updateConnectionStatus()
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            print(string as String, terminator: "")
        }
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        serialHandler.postUserNotification(text: "SerialPort \(serialPort.path) encountered an error: \(error)")
    }
    
    @objc func serialPortsWereConnected(_ notification: Notification) {
        if serialPort?.isOpen != true {
            if let userInfo = notification.userInfo {
                let connectedPorts = userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]
                print("Ports were connected: \(connectedPorts)")
                for port in connectedPorts {
                    if port.path == settings.string(forKey: "serial_port") {
                        self.serialPort = port
                        self.serialHandler.postUserNotification(text: "Serial ports connected \(connectedPorts). Connecting to \(port.path)...")
                        serialConnect()
                        updatePwmValue(value: BrightnessSlider.floatValue)
                        return
                    }
                }
                self.serialHandler.postUserNotification(text: "Serial ports connected \(connectedPorts). But selected port not found.")
            }
        }
    }
}

//Extend AppDelegate with Media Key Tap functions
extension AppDelegate: MediaKeyTapDelegate {
    func acquirePrivileges() {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let privOptions = [trusted: true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)

        if accessEnabled == true {
            print("OK, access enabled.")
        } else {
            print("Failed, access denied.")
        }
    }
    
    //Try to start the media key tap listeners for brightness down and up
    private func startMediaKeyTap() {
        acquirePrivileges()

        var keys: [MediaKey]
        keys = [.brightnessUp, .brightnessDown]
        
        self.mediaKeyTap?.stop()
        self.mediaKeyTap = MediaKeyTap(delegate: self, for: keys, observeBuiltIn: true)
        self.mediaKeyTap?.start()
        
        let environment = ProcessInfo.processInfo.environment
        print(environment["APP_SANDBOX_CONTAINER_ID"] == nil ? "Not sanboxed" : "Sandboxed")
    }

    //Handle the media key taps
    func handle(mediaKey: MediaKey, event: KeyEvent?, modifiers: NSEvent.ModifierFlags?) {
        let step: Float = 100/16

        switch mediaKey {
            case .brightnessUp:
                let roundedValue = (round(self.BrightnessSlider.floatValue / step) * step) + step
                
                if(roundedValue>100) {
                    self.updatePwmValue(value: self.BrightnessSlider.floatValue)
                } else {
                    self.BrightnessSlider.floatValue = roundedValue
                    self.updatePwmValue(value: roundedValue)
                }

                showOSD()
            case  .brightnessDown:
                let roundedValue = (round(self.BrightnessSlider.floatValue / step) * step) - step
                
                if(roundedValue<0) {
                    self.updatePwmValue(value: self.BrightnessSlider.floatValue)
                } else {
                    self.BrightnessSlider.floatValue = roundedValue
                    self.updatePwmValue(value: roundedValue)
                }
                
                showOSD()
            default: break
        }
    }
    
    func showOSD() {
        guard let manager = OSDManager.sharedManager() as? OSDManager else {
          return
        }
        manager.showImage(Int64(1), onDisplayID: CGMainDisplayID(), priority: 0x1F4, msecUntilFade: 1000, filledChiclets: UInt32(16*self.BrightnessSlider.floatValue/100), totalChiclets: UInt32(16), locked: false)
    }
}
