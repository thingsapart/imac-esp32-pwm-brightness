import machine

class iMacBrightnessPWM:
    MAX_PWM = 1023
    def __init__(self, pin=23, freq=13000, brightness=0.7):
        # Default to pin D23 on DIOT ESP32 Dev Board
        self.pin = machine.Pin(pin)
        self.freq = freq
        self.pwm = None
        self.set_brightness(brightness)

    def set_brightness(self, brightness):
        duty = int(self.MAX_PWM * brightness)
        if self.pwm:
            self.pwm.duty(duty)
        else:
            self.pwm = machine.PWM(self.pin, freq=self.freq, duty=duty)

    def stop(self):
        self.pwm.deinit()

    def led_test(self, t):
        import time, math
        self.set_brightness(0.0)
        for i in range(int(1200)):
            self.set_brightness(math.sin(i / 100 * math.pi) * 0.5 + 0.5)
            time.sleep_ms(t)
        self.stop()

if __name__ == "__main__":
    pwm = iMacBrightnessPWM(2, 1000, 0)
    pwm.led_test(10)
