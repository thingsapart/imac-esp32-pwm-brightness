### iMac 2009 / 2010 / 2011 GPU upgrade — Fixing LED/LCD PWM brightness with an ESP32

### iMac 2009–2011 GPU upgrade PWM backlight mod — regain brightness control after upgrading to an unsupported non-Apple GPU.

<br> 

So you want adjustable brightness in hardware after [installing a better GPU](https://forums.macrumors.com/threads/2011-imac-graphics-card-upgrade.1596614/) in your 2009-2011 iMac?

**Warning!**

It goes without saying that modifying your iMac is dangerous and may destroy your iMac. I am describing how I modified my iMac and if you follow these steps do so at your own risk. I can’t guarantee that these modifications will work for you and you are quite likely to destroy your iMac or hurt yourself in the process if you don’t know what you are doing.

!! Always unplug your power cord when you work inside the iMac, or else *sparks*! Ask me how I know ;) !!

<br> 

**Why?**

The 2009–2011 iMacs are nicely upgradeable, thanks to many MacRumors members (especially *Nick [D]vB*) it is possible to even run rather recent graphics cards on these old iMacs.

The problem is that iMacs run custom GPU vBIOS (video BIOS) software from Apple that, among other stuff, enables backlight control. So when you upgrade your graphics card, you lose backlight control, even with *Nick [D]vB*’s custom vBIOS for many cards. You can regain backlight by running OpenCore but just doing it in hardware seemed like a safer longer term bet.

<br> 

**The Solution**

MacRumors member *wlagarde* [reverse engineered](https://forums.macrumors.com/threads/2011-imac-graphics-card-upgrade.1596614/page-54?post=26876819#post-26876819) how these iMacs control the LED brightness. The LCD controller receives a pulse-width-modulated (PWM) signal from the logic board/GPU and correspondingly adjusts brightness. Since upgraded unofficial GPUs do not send a proper signal, the display always runs at full brightness. That leads to potential heat buildup issues and shorter lifespan as well as problems in low ambient light.

*The PWM signal has a 3.25V amplitude and a frequency of 13kHz, the length (or duty cycle) of these pulses determines the backlight intensity.*

MacRumors posters proposed a couple solutions: using a Dying Light module originally intended for failing MacBook Pro backlights (currently unavailable), a stand-alone potentiometer-configured PWM module, serial PWM modules or even a Raspberry Pi running a Node Red env.

Fortunately, the **ESP32** **microcontroller** supports PWM frequencies of 13kHz and higher (unfortunately the cheaper ESP-8266 only does 1kHz), is easy to obtain for < $10, easy to program and use, and supports Wifi/BT but more importantly Serial comms via USB.

And MacRumors user *passatgt* also [wrote software](https://github.com/passatgt/imac-pwm-control) to dim Mac displays by adjusting the screen’s gamma or using a Raspberry Pi as a PWM source — I have adapted the software to work with an ESP32 hooked up internally and communicate via serial. The Raspi seemed to rely on Wifi/networking and seemed a bit overkill (*running a small, real computer running Linux inside your large computer running MacOS!* **mindburst**).

<br>

**Quick Summary**

But don't just copy&paste this, read below and adjust these steps as needed to your own system.

1. *Install/download the necessary software*
- [brew.sh](https://brew.sh/)
- [Micropython esp32-idf4–20191220-v1.12.bin](https://micropython.org/resources/firmware/esp32-idf3-20191220-v1.12.bin)
- [SiLabs USB serial drivers](https://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers)
- `brew install pip3 esptool.py picocom`
- [MacOS Brightness controller binary](https://github.com/thingsapart/imac-esp32-pwm-brightness/releases/download/0.1/imac-esp32-pwm-brightness.zip)
- `pip3 install adafruit-ampy`
2. *Flash and program the ESP32*
- Install SiLabs drivers and connect ESP32s
- Flash micropython: `/usr/local/bin/esptool.py --port /dev/cu.SLAB_USBtoUART erase_flash` **then immediately** on the
ESP32-D1 dev kit, **hold down “BOOT” first, then briefly press “EN”**, then `/usr/local/bin/esptool.py --chip esp32 --port /dev/cu.SLAB_USBtoUART --baud 460800 write_flash -z 0x1000 ~/Downloads/esp32-idf4-20191220-v1.12.bin` and repeat BOOT + EN as before
- run `./micropy/install_mac.sh` from the GitHub repo local clone to put the files on the ESP32, reboot the ESP32 and check that the blue LED is on
3. *Wire up the 6-pin PCI-e extension cable to the LCD controller board, cut the PWM wire and route the PWM wire to your ESP32 pin D23/GPIO23.*
4. *Wire up your ESP32 to the iMac's internal IR USB port or run a cable to the back of the iMacs normal USB ports.*

<br>


**Parts**

* ESP-32 microcontroller (important, has to be an ESP-32 for PWM freq, not
ESP-8266) — I used the most common “D1 dev kit” board from eBay with headers, no
headers may be preferable.
* PCI-E 6-pin male/female extension harness or splitter
* Extra iMac Infrared sensor cable (if you don’t want to destroy your own)
* 1 or 2 Micro USB cables (one to program the ESP-32, and a sacrificial one)
* Soldering iron, solder and wires

<br> 

**A couple Notes**

* Code blocks in Medium (` backtick) are commands to be executed in your Terminal App, e.g. `ls /dev/cu.*` lists serial devices in the Terminal.
* I am assuming that homebrew installs all applications in “*/usr/loca/bin*”, adjust if necessary.
* Quotes indicate code or a literal, if you enter these literals always omit the quotes.

<br> 

**Steps**

***0. Upgrade your GPU and flash appropriate *Nick [D]vB* bios. Honestly, it is quite risky and not advised if you don’t know what you are doing.***

***1.  Download the software from GitHub, install homebrew, install SiLabs USB VCP drivers.***

  - Download from GitHub: [Source + MicroPython code for ESP32](https://github.com/thingsapart/imac-esp32-pwm-brightness), [MacOS binary](https://github.com/thingsapart/imac-esp32-pwm-brightness/releases/download/0.1/imac-esp32-pwm-brightness.zip) (or build yourself)
  
  - Download [SiLabs USB serial drivers](https://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers) and install

  - Download a [MicroPython binary image](https://micropython.org/download/esp32/) (I used 1.12 — “[esp32-idf4–20191220-v1.12.bin](https://micropython.org/resources/firmware/esp32-idf3-20191220-v1.12.bin)”)

  - Install homebrew: [brew.sh](https://brew.sh/)

  - Install pip3: `brew install pip3`

  - Install esptool: `brew install esptool.py`

  - Install picocom: `brew install picocom` (or use your own fave)

  - Install AdaFruint ampy: `pip3 install adafruit-ampy`

  - Also install Xcode if you want to modify the MacOS brightness app.

<br>

***2. Program the ESP32***

  - Make sure you have the SiLabs USB VCP drivers installed!

  - Connect the ESP32 via micro-USB cable to a working Mac

  - Check if you can see any USB serial devices (High Sierra/Catalina: `ls /dev/cu.*`), I see 2–3 devices depending on computer. Make sure you have a “*/dev/cu.SLAB_USBtoUART*” device. If not, either you didn’t properly install the SiLabs driver, or the ESP32 or your cable are not working.

  - Run `/usr/local/bin/esptool.py flash_id` to check the connection to the ESP with its tools and note the serial port => referred to as `<port>` below, e.g. “*/dev/cu.SLAB_USBtoUART”.*

  - Erase and flash `/usr/local/bin/esptool.py --port <port> erase_flash` on the ESP32-D1 dev kit, hold down “BOOT” first, then briefly press “EN”, esptool should now see your ESP32 and erase it. `/usr/local/bin/esptool.py --chip esp32 --port <port> --baud 460800 write_flash -z 0x1000 ~/Downloads/esp32-idf4-20191220-v1.12.bin`

  - Restart the ESP32 again (push “EN” button) and connect via picocom: `/usr/local/bin/picocom /dev/cu.SLAB_USBtoUART -b115200` — hit enter and you should see the Python REPL “>>>”. Play around, then exit with CTRL+A, CTRL+Q.

  - Try running an LED test if you want: `/usr/local/bin/ampy — port /dev/cu.SLAB_USBtoUART run test.py`.

  - There’s an `./micropy/install_mac.sh` in the GitHub repo, run that script to copy all files from “*./micropy/src*” to the ESP32.

  - Reboot the ESP32 and you should see the blue and red LED both on.

  - If you have a different ESP type or want to use a pin other than D23 / GPIO23 edit “*./micropy/src/pwm.py*” and replace “pin=23” in the “__init__” with your desired pin. Run “*install_mac.sh*” again then.

  - Connect again via picocom: `/usr/local/bin/picocom /dev/cu.SLAB_USBtoUART -b115200`, the script “*./micropy/src/shell.py*” has hijacked the stdin from the REPL and accepts brightness commands only, type “*repl*” if you ever want to exit back to the Python REPL. Try to enter e.g. “*10*” (no quotes) and hit return, the LED should dim to about 10%, then try other numbers. Exit picocom with *CTRL+A, CTRL+Q*.

  - If the LED dims properly when you type in your numbers you’ve got the ESP32 up and running and you can proceed to modding the iMac.

<br>

***3. Open up your iMac (carefully!) and unplug the IR module towards the bottom of the screen behind the front Apple logo (see iFixit e.g.) and connect the ESP32 to the IR module’s USB port.***

**!! Warning: look at schematics to make sure this applies to your vintage of iMac, mine is Late 2009 with i7, the schematic I saw online didn’t work for me and had D+/D- crossed !!**


  - Remember which way the IR connector is facing when plugged into the logic board, I will count pins left-to-right as it is when plugged in.

  - Cut your sacrificial micro-USB cable, strip the wires.

  - Cut the wires on the IR module’s logic board connector.

  - Look at schematics, verify which pins on the connector are 5V and ground! If you mess these up you may fry the ESP32 or unlikely even your logic board.

  - For iMac 11,1: Connect IR left-most pin (pin 1) to USB GND/black, pin 2 to USB 5V/red, pin 3 to USB D-/green, pin 4 USB D+/white.

  - According to [this post](https://forums.macrumors.com/threads/2011-imac-graphics-card-upgrade.1596614/page-187?post=28231640#post-28231640) the data pins may be switched on newer iMacs (or I got something else mixed up).

My ESP32 wasn’t showing up as USB device via IR port when I first wired it up, if I read the online schematics correctly pins 3/4 were D+/D- but I had to rewire to D-/D+ with my 2009 iMac and it worked.

<br>

***4. Remove the LCD driver board and disconnect the 6-pin PCI-e cable at the top.***

  - On your extension cable (not the original if you want this hack to be reversible!), when looking at the female connector from the back, cut the bottom right cable and extend it so that you can solder/connect it to pin D23 on your ESP32 when it’s plugged into the logic board IR connector and stowed away.
  - Solder/connect the cable from the PCI-e cable to your ESP32 pin D23/GPIO23, plug the PCI-e extension cable in to the LCD driver board and reinstall the LCD driver board.

  - Connect the extension cable to the original PCI-e LCD driver board cable and tuck the cables away — they need to be neatly tucked away for the LCD to fit back on.

  - Don’t reinstall the LCD panel yet, briefly connect the power cable and turn on the iMac. Both the blue and red LED on the ESP32 should turn on. Turn off the iMac before it boots.

  - Unplug the iMac, reinstall the LCD panel, plug back in and boot into MacOS.

<br>

***5. All Done?***

If everything went well, your screen should run at about 70% brightness at boot now. Boot into MacOS and run the “imac_esp32_pwm_brightness” app, MacOS will ask for permissions you will need to grant “Accessibility permissions” in System Prefs if you want to use the brightness keys to adjust brightness. Otherwise you can use a slider in MacOS menu bar (little brightness icon).

The first time the app runs, it shows the preferences dialog and asks for serial port and baud rate, you probably want “115200” baud and “/dev/cu.SLAB_USBtoUART”. Click “Done”. If you want to quit the app, click the brightness icon on the right side menu bar, click the preferences logo and “Quit” in the dialog.

Thanks to everyone who contributed to the GPU mod thread on MacRumors! Special thanks *Nick [D]vB* for making all this even possible with his vBIOS, *wlagarde* for reverse engineering the iMac PWM protocol and *passatgt* for open-sourcing “imac-pwm-control” which I based the Mac software on.

And BTW: It’s been 10+ years since I’ve done Mac/iOS development, never in Swift, and I haven’t had time to clean up the code yet — so don’t judge ;)
