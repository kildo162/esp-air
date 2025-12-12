# Project ESP8266 with DH11 for Temperature and Humidity Monitoring


- Board ESP8266MOD HW-364A (ESP8266 WiFi module with OLED 0.96" display HW-364a): https://masterlexon.com/en/esp8266-wifi-module-with-oled-0-96-display-hw-364a, https://github.com/peff74/esp8266_OLED_HW-364A/
  - Screen: OLED 0.96" SSD1306 I2C Display Module (128x64 pixels)
  - 
- Sensor DH11 (DHT11 Temperature and Humidity Sensor Module)

- PCB Connect: 
  - VCC (DH11) to 3.3V (ESP8266)
  - GND (DH11) to GND (ESP8266)
  - DATA (DH11) to D1 (GPIO5) (ESP8266)

- PCB Screen onboard:
  #define SCREEN_ADDRESS 0x3C // If this address does not work, scan the device addresses
  #define OLED_SDA 14 // D6
  #define OLED_SCL 12 // D5

- Tools: VSCode with PlatformIO extension.

Boot behavior
- On boot the firmware prints "Booting..." to Serial (115200) and displays "Loading..." on the SSD1306 OLED for 1.5s, then shows "Ready" and a simple uptime counter.

Wiring notes
- The onboard OLED is expected to use I2C pins: `SDA = D6 (GPIO14)`, `SCL = D5 (GPIO12)`. The DHT11 data pin is `D1 (GPIO5)` on this PCB — avoid wiring conflicts between I2C and the DHT pin.

DHT11 (sensor)
- DHT11 data pin: `D1 (GPIO5)`. We read the DHT sensor every 2 seconds and display T/H on the OLED and print values to Serial.