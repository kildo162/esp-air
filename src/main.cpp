#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>

// Display configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
// -1 means no reset pin used
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// prototypes
int myFunction(int, int);
void showLoading();

bool display_ok = false;
// DHT config
#define DHTPIN D1
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

void setup() {
  // Initialize serial for debug/monitor
  Serial.begin(115200);
  delay(50);
  Serial.println("Booting...");

  // Initialize I2C (defaults to SDA=D2, SCL=D1 on many NodeMCU boards)
    // Use board-specific pins for the onboard OLED (see README):
    // SDA = D6 (GPIO14), SCL = D5 (GPIO12)
    Wire.begin(14, 12);

  // Initialize OLED display
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    display_ok = false;
  } else {
    display_ok = true;
    showLoading();
    delay(1000);
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("Ready");
    display.display();
  }

  // example usage of myFunction
  int result = myFunction(2, 3);
  Serial.printf("myFunction(2,3)=%d\n", result);
  // initialize DHT sensor
  dht.begin();
}

void loop() {
  // simple heartbeat on the display or serial
  static unsigned long last = 0;
  if (millis() - last > 2000) { // read DHT every 2s
    last = millis();
    if (display_ok) {
      float h = dht.readHumidity();
      float t = dht.readTemperature();
      display.clearDisplay();
      display.setTextSize(2);
      display.setTextColor(SSD1306_WHITE);
      display.setCursor(0, 0);
      if (isnan(t) || isnan(h)) {
        display.println("DHT error");
        Serial.println("DHT read failed");
      } else {
        display.printf("T: %.1fC", t);
        display.setCursor(0, 26);
        display.printf("H: %.1f%%", h);
        Serial.printf("T: %.1f C, H: %.1f %%\n", t, h);
      }
      display.display();
    } else {
      Serial.printf("Uptime: %lu s\n", millis() / 1000);
    }
  }
}

// put function definitions here:
int myFunction(int x, int y) {
  return x + y;
}

void showLoading() {
  display.clearDisplay();
  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Loading...");
  display.display();
}