# iMac ESP32 PWM Control

The MacOS portion of this software is based on https://github.com/passatgt/imac-pwm-control and has been rewritten to communicate via USB-serial with am ESP32 microcontroller hooked up to your iMac.

# Why?

The 2009–2011 iMacs are nicely upgradeable, thanks to many MacRumors members (especially Nick [D]vB) it is possible to even run rather recent graphics cards on these old iMacs.
The problem is that iMacs run custom GPU vBIOS (video BIOS) software from Apple that, among other stuff, enables backlight control. So when you upgrade your graphics card, you lose backlight control, even with Nick [D]vB's custom vBIOS for many cards. You can regain backlight by running OpenCore but just doing it in hardware seemed like a safer longer term bet.

# Install on the ESP32

Install Micropythpon and use Adafruit's ampy to put the files in `./micropy/src/*.py` onto the ESP32.

Restart the ESP32 and make sure the blue LED turns on as well. Possibly connect via Picocom or another terminal emulator to the ESP32's serial USB port and type in a number to adjust the LED (and PWM sigmal) brightness, 0 => 0%, 100 => 100% brightness.

# Hook up to your iMac

Install the ESP32 inside your iMac, get a short 6-pin PCI-e male to female extension cable and cut the PWM line (looking at the back of female connector, it's the bottom right wire) and disconnect the original PCI-e cable to the LCD controller board, insert the extension cable and hook up original to extension. Run that cut wire to your ESP23 to GPIO23/D23 pin. Connect the ESP32 to an external USB port for testing, you can later wire it to your internal IR port (which is also a USB port).

Install the SiLabs USB VCP drivers for the ESP32 USB/serial port. Build the MacOS app or download from releases and run, configure the serial port in the settings and baud rate (usually "/dev/cu.SLAB_USBtoUART" and "115200") and click done. The app needs access to Accessibility to intercept the Mac keyboard brightness keys, you can also just use the slider 
