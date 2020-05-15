# Direct serial console
# Install picicom, e.g. `brew install picocom`
# Ctrl-A and then Ctrl-Q to exit.
/usr/local/bin/picocom /dev/cu.SLAB_USBtoUART -b115200

# Serial comms and console
pip3 install adafruit-ampy
# Test that micropython is running
/usr/local/bin/ampy --port /dev/cu.SLAB_USBtoUART run test.py

# Install via micropy-cli
/usr/local/bin/micropy stubs search esp32
/usr/local/bin/micropy stubs add esp32-micropython-1.12.0
# Select options by using cursor keys and space bar to select, then hit return when ready to init
/usr/local/bin/micropy init
