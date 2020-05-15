print('ESP32 connected and responding...')

# Now blink the LED...
import machine
import time
led = machine.Pin(2, machine.Pin.OUT)
for i in range(5):
    led.value(1)
    time.sleep(0.2)
    led.value(0)
    time.sleep(0.2)
