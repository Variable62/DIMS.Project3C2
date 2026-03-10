#include <Wire.h>
#include <Adafruit_MCP4725.h>

// --- Pin Definitions ---
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

// *** ต้องวาง struct ไว้ตรงนี้เพื่อให้ฟังก์ชันข้างล่างรู้จัก ***
struct MeasResult {
    uint32_t count;
    float degree;
};

uint8_t freqMode = 0;     
uint8_t measureMode = 5;  
uint16_t currentDacValue = 2048; 

// --- Functions ---
void triggerWrite() {
  digitalWrite(WRITE, HIGH);
  delayMicroseconds(20); 
  digitalWrite(WRITE, LOW);
}

void sendMode(uint8_t modeValue) {
  digitalWrite(MODE0, (modeValue >> 0) & 1);
  digitalWrite(MODE1, (modeValue >> 1) & 1);
  digitalWrite(MODE2, (modeValue >> 2) & 1);
  digitalWrite(MODE3, (modeValue >> 3) & 1);
  delayMicroseconds(5);
  triggerWrite(); 
}

uint32_t getCountFromFPGA() {
    uint32_t fullData = 0; 
    for (int i = 0; i < 5; i++) {
        uint32_t timeout = millis();
        while (digitalRead(REQ) == LOW) {
            if (millis() - timeout > 100) return 0; 
        }
        delayMicroseconds(10); 
        uint8_t nibble = (digitalRead(COUNT3) << 3) | (digitalRead(COUNT2) << 2) | 
                         (digitalRead(COUNT1) << 1) | (digitalRead(COUNT0) << 0);
        fullData |= ((uint32_t)nibble << (i * 4)); 
        digitalWrite(ACK, HIGH);
        while (digitalRead(REQ) == HIGH); 
        digitalWrite(ACK, LOW);
        delayMicroseconds(5); 
    }
    return fullData;
}

MeasResult getMeasurement(int samples) {
    MeasResult res = {0, -1.0};
    uint64_t sumCount = 0;
    int countValid = 0;
    
    for (int i = 0; i < samples; i++) {
        uint32_t val = getCountFromFPGA();
        if (val > 0) {
            sumCount += val;
            countValid++;
        }
        delay(5);
    }
    
    if (countValid > 0) {
        res.count = (uint32_t)(sumCount / countValid);
        float T_val = (freqMode == 0) ? 480.0 : (freqMode == 1) ? 4800.0 : (freqMode == 2) ? 48000.0 : 480000.0;
        res.degree = ((float)res.count / T_val) * 360.0;
    }
    return res;
}

void runSAR() {
  Serial.println("\n********************************************************************");
  Serial.println(">>> [SAR START] TARGET 60.0 DEG <<<");
  Serial.println("Bit |   DAC |  Vdac(V) |    Count |  Degree | Status");
  Serial.println("--------------------------------------------------------------------");
  
  uint16_t sarResult = 0;
  sendMode(5); 

  for (int i = 11; i >= 0; i--) {
    uint16_t testValue = sarResult | (1 << i);
    dac.setVoltage(testValue, false);
    delay(100); 

    MeasResult res = getMeasurement(2); 
    float v_dac = (testValue * 3.3) / 4095.0;
    
    if (res.degree >= 0) {
      if (res.degree < 60.0) {
        sarResult = testValue; 
        Serial.printf("%3d | %5d | %8.3f | %8d | %7.2f | KEEP\n", i, testValue, v_dac, res.count, res.degree);
      } else {
        Serial.printf("%3d | %5d | %8.3f | %8d | %7.2f | DROP\n", i, testValue, v_dac, res.count, res.degree);
      }
    } else {
      Serial.printf("%3d | %5d | %8.3f |    ERR   |   ERR   | NO SIGNAL\n", i, testValue, v_dac);
    }
  }
  currentDacValue = sarResult;
  dac.setVoltage(currentDacValue, false);
  float final_v = (currentDacValue * 3.3) / 4095.0;
  Serial.println("--------------------------------------------------------------------");
  Serial.printf(">>> [SAR DONE] FINAL DAC: %d (%.3f V)\n", currentDacValue, final_v);
  Serial.println("********************************************************************\n");
}

void setup() {
  Serial.begin(115200);
  Wire.begin();
  Wire.setClock(100000); 
  Wire.setTimeOut(50); 

  if (!dac.begin(0x61)) Serial.println("MCP4725 not found!");

  pinMode(MODE0, OUTPUT); pinMode(MODE1, OUTPUT);
  pinMode(MODE2, OUTPUT); pinMode(MODE3, OUTPUT);
  pinMode(WRITE, OUTPUT);
  pinMode(COUNT0, INPUT); pinMode(COUNT1, INPUT);
  pinMode(COUNT2, INPUT); pinMode(COUNT3, INPUT);
  pinMode(REQ, INPUT);
  pinMode(ACK, OUTPUT);
  pinMode(SW_FREQ, INPUT_PULLUP);
  pinMode(SW_TYPE, INPUT_PULLUP); 
  
  digitalWrite(ACK, LOW);
  digitalWrite(WRITE, LOW);
  
  sendMode(measureMode); 
  dac.setVoltage(currentDacValue, false);
  
  Serial.println("\n--- [SYSTEM READY] ---");
  Serial.println("- Type 's' to Start Auto SAR");
}

void loop() {
  if (Serial.available() > 0) {
    String input = Serial.readStringUntil('\n');
    input.trim();
    
    if (input.equalsIgnoreCase("s")) {
      runSAR();
    } else if (input.length() > 0) {
      long val = -1;
      if (input.startsWith("b") || input.startsWith("B")) {
        val = strtol(input.substring(1).c_str(), NULL, 2);
      } else {
        val = input.toInt();
      }

      if (val >= 0 && val <= 4095) {
        currentDacValue = (uint16_t)val;
        dac.setVoltage(currentDacValue, false);
        float v = (currentDacValue * 3.3) / 4095.0;
        Serial.printf(">>> DAC Manual Set: %d (%.3f V)\n", currentDacValue, v);
      }
    }
  }

  if (digitalRead(REQ) == HIGH) {
    MeasResult res = getMeasurement(1);
    if (res.degree >= 0) {
      float v_dac = (currentDacValue * 3.3) / 4095.0;
      Serial.printf("%s | M:%d | Count:%-8d | Deg:%6.2f | DAC:%4d | Vdac:%.3fV\n", 
                    (measureMode == 4 ? "PHASE" : "WIDTH"), freqMode, res.count, res.degree, currentDacValue, v_dac);
      delay(300); 
    }
  }

  static bool lastF = HIGH, lastT = HIGH;
  bool cf = digitalRead(SW_FREQ), ct = digitalRead(SW_TYPE);
  if (lastF == HIGH && cf == LOW) {
    delay(50); if(digitalRead(SW_FREQ)==LOW) { freqMode=(freqMode+1)%4; sendMode(freqMode); }
  }
  if (lastT == HIGH && ct == LOW) {
    delay(50); if(digitalRead(SW_TYPE)==LOW) { measureMode=(measureMode==4)?5:4; sendMode(measureMode); }
  }
  lastF = cf; lastT = ct;
}