#include <Wire.h>
#include <Adafruit_MCP4725.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

#define MODE0 16
#define MODE1 17
#define MODE2 18
#define MODE3 19
#define WRITE 4
#define COUNT0 27
#define COUNT1 26
#define COUNT2 25
#define COUNT3 33
#define REQ 32
#define ACK 23
#define SW_FREQ 13  
#define SW_TYPE 14 

Adafruit_MCP4725 dac;

const float M_SLOPE = 0.000816; 
const float C_INTERCEPT = 0.0413;
const float calFactor = 1.0656; 
float T_TABLE[4] = {480.0, 4800.0, 48000.0, 480000.0}; 

uint8_t freqMode = 0;      
uint8_t measureMode = 4;   
uint16_t currentDacValue = 0; 


void setDacVoltage(uint16_t rawValue) {
    if (rawValue == 0) { dac.setVoltage(0, false); return; }
    float targetVolt = (rawValue * 3.3) / 4095.0; 
    float calibratedValue = (targetVolt - C_INTERCEPT) / M_SLOPE;
    uint32_t finalValue = (uint32_t)(calibratedValue * calFactor);
    if (finalValue > 4095) finalValue = 4095;
    dac.setVoltage((uint16_t)finalValue, false);
}

void sendMode(uint8_t modeValue) {
    digitalWrite(MODE0, (modeValue >> 0) & 1);
    digitalWrite(MODE1, (modeValue >> 1) & 1);
    digitalWrite(MODE2, (modeValue >> 2) & 1);
    digitalWrite(MODE3, (modeValue >> 3) & 1);
    delayMicroseconds(10);
    digitalWrite(WRITE, HIGH); delayMicroseconds(20); digitalWrite(WRITE, LOW);
}

uint32_t getCountFromFPGA() {
    uint32_t fullData = 0; 
    for (int i = 0; i < 5; i++) {
        uint32_t timeout = millis();
        while (digitalRead(REQ) == LOW) if (millis() - timeout > 50) return 0; 
        delayMicroseconds(20); 
        uint8_t nibble = (digitalRead(COUNT3) << 3) | (digitalRead(COUNT2) << 2) | 
                         (digitalRead(COUNT1) << 1) | (digitalRead(COUNT0) << 0);
        fullData |= ((uint32_t)nibble << (i * 4)); 
        digitalWrite(ACK, HIGH);
        while (digitalRead(REQ) == HIGH); 
        digitalWrite(ACK, LOW);
        delayMicroseconds(10);
    }
    return fullData;
}

uint32_t getTargetWidth() {
    uint32_t v1 = getCountFromFPGA();
    delay(5);
    uint32_t v2 = getCountFromFPGA();
    return (v1 > v2) ? v1 : v2; 
}

void updateOLED(uint32_t cnt, float deg) {
    float v_actual = (measureMode == 4) ? 0 : (currentDacValue * 3.3 * calFactor) / 4095.0;
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);
    display.setCursor(0,0);
    display.printf("M%d %s", freqMode, (measureMode == 4 ? "PHASE" : "WIDTH"));
    display.setCursor(45, 12); 
    display.printf("%.1f%c", deg, (char)247); 
    display.setCursor(0, 24);
    display.printf("C:%u", cnt);
    display.setCursor(70, 24);
    display.printf("V:%.3fV", v_actual); 
    display.display();
}

void doSarDac() {
    uint16_t sarResult = 0;
    uint32_t targetCount = (uint32_t)(T_TABLE[freqMode] / 6.0); 
    
    display.clearDisplay();
    display.setCursor(0,10);
    display.print("CALIBRATING...");
    display.display();
    
    Serial.printf("\n--- SAR START M%d | Target > %u ---\n", freqMode, targetCount);

    for (int i = 11; i >= 0; i--) {
        uint16_t testValue = sarResult | (1 << i);
        setDacVoltage(testValue);
        delay(120); 
        uint32_t count = getTargetWidth(); 

        if (count > targetCount) {
            sarResult = testValue;
            Serial.printf("Bit %d | DAC:%d | KEEP\n", i, testValue);
        } else {
            Serial.printf("Bit %d | DAC:%d | DROP\n", i, testValue);
        }
    }
    currentDacValue = sarResult;
    setDacVoltage(currentDacValue);
}

void setup() {
    Serial.begin(115200);
    Wire.begin();
    display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
    dac.begin(0x61);
    
    pinMode(MODE0, OUTPUT); 
    pinMode(MODE1, OUTPUT);
    pinMode(MODE2, OUTPUT); 
    pinMode(MODE3, OUTPUT);
    pinMode(WRITE, OUTPUT); 
    pinMode(ACK, OUTPUT);
    pinMode(COUNT0, INPUT); 
    pinMode(COUNT1, INPUT);
    pinMode(COUNT2, INPUT); 
    pinMode(COUNT3, INPUT);
    pinMode(REQ, INPUT);
    pinMode(SW_FREQ, INPUT_PULLUP);
    pinMode(SW_TYPE, INPUT_PULLUP);

    digitalWrite(ACK, LOW);
    digitalWrite(WRITE, LOW);
    
    measureMode = 4;
    currentDacValue = 0;
    setDacVoltage(0);
    
    sendMode(measureMode); 
    delay(100);
    sendMode(freqMode);    
    
    display.clearDisplay();
    display.setCursor(0,10);
    display.print("SYSTEM READY: M4");
    display.display();
    delay(1000);
}

void loop() {
    static uint32_t lastBtn = 0;

    if (digitalRead(SW_FREQ) == LOW && millis() - lastBtn > 500) {
        freqMode = (freqMode + 1) % 4;
        sendMode(freqMode);
        if (measureMode == 5) doSarDac(); 
        lastBtn = millis();
    }

    if (digitalRead(SW_TYPE) == LOW && millis() - lastBtn > 500) {
        measureMode = (measureMode == 4) ? 5 : 4;
        sendMode(measureMode);
        
        if (measureMode == 4) {
            setDacVoltage(0);  
            currentDacValue = 0;
        } else {
            doSarDac();
        }
        lastBtn = millis();
    }

    if (digitalRead(REQ) == HIGH) {
        uint32_t c = (measureMode == 5) ? getTargetWidth() : getCountFromFPGA();
        if (c > 0) {
            float deg = ((float)c / T_TABLE[freqMode]) * 360.0;
            // Offset Correction สำหรับ M0
            if (freqMode == 0 && deg > 0) {
                deg -= 85.0;
                if (deg < 0) deg = 0.0;
            }
            updateOLED(c, deg);
        }
    }
    yield();
}