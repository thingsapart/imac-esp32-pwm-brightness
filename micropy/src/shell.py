import sys
import pwm

def shell():
    sys.stdout.write(b"ESP32 UART brightness control loop...\n")
    sys.stdout.write(b"Type 'repl' to return to micropython REPL.\n")
    led_ctrl = pwm.iMacBrightnessPWM(2, 1000, 0)
    imac_ctrl = pwm.iMacBrightnessPWM()

    brightness = 0.2
    led_ctrl.set_brightness(brightness)
    imac_ctrl.set_brightness(brightness)

    while True:
        input = sys.stdin.readline().strip()
        if input == "repl":
            led_ctrl.stop()
            imac_ctrl.stop()
            return
        try:
            brightness = int(input) / 100
            led_ctrl.set_brightness(brightness)
            imac_ctrl.set_brightness(brightness)
        except:
            pass
