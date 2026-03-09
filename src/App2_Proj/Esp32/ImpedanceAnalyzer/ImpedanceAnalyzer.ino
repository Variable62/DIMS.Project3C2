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

uint8_t freqMode = 0;     
uint8_t measureMode = 5;  
uint16_t currentDacValue = 2048; 

void sendMode(uint8_t modeValue) {
  digitalWrite(MODE0, (modeValue >> 0) & 1);
  digitalWrite(MODE1, (modeValue >> 1) & 1);
  digitalWrite(MODE2, (modeValue >> 2) & 1);
  digitalWrite(MODE3, (modeValue >> 3) & 1);
  delayMicroseconds(5);
  digitalWrite(WRITE, HIGH);
  delayMicroseconds(10);
  digitalWrite(WRITE, LOW);
}

uint32_t getPhaseFromFPGA() {
    uint32_t fullData = 0; 
    for (int i = 0; i < 5; i++) {
        uint32_t timeout = micros();
        while (digitalRead(REQ) == LOW) {
            if (micros() - timeout > 20000) return 0; 
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

void runDacSAR() {
  Serial.println("\n--- [SAR] Starting Calibration ---");
  
  // 1. ล้างข้อมูลค้าง (Flush) อ่านทิ้งก่อนเพื่อให้แน่ใจว่าเป็นค่าจากโหมดใหม่
  for(int i=0; i<5; i++) {
    getPhaseFromFPGA();
    delay(10);
  }

  uint16_t dacTestValue = 0;
  uint32_t target = 0;

  // เลือก Target ตาม Frequency Mode
  switch (freqMode) {
    case 0: target = 80;     break; // 100kHz
    case 1: target = 800;    break; // 10kHz
    case 2: target = 8000;   break; 
    case 3: target = 80000;  break; 
  }

  // เข้าโหมด 5 (Width) ชั่วคราวเพื่อ Calibrate
  sendMode(5);
  delay(100);

  for (int i = 11; i >= 0; i--) {
    dacTestValue |= (1 << i); 
    dac.setVoltage(dacTestValue, false);
    delay(40); 

    uint32_t currentCount = getPhaseFromFPGA();
    Serial.printf("Step %2d | DAC: %4d | Count: %-8u | Target: %-8u", i, dacTestValue, currentCount, target);

    if (currentCount < target) {
      dacTestValue &= ~(1 << i); 
      Serial.println(" -> [HIGH: Drop Bit]");
    } else {
      Serial.println(" -> [OK: Keep Bit]");
    }
  }

  currentDacValue = dacTestValue;
  dac.setVoltage(currentDacValue, false);
  
  // คืนค่าโหมดที่เลือกไว้ (Phase หรือ Width)
  sendMode(measureMode);

  // คำนวณเป็นแรงดันตามสูตรอาจารย์ (หารด้วย Gain)
  float v_out_dac = (currentDacValue * 3.3) / 4095.0;
  float v_input_est = v_out_dac / 0.866; // สูตร V_in = V_dac / Gain

  Serial.println("----------------------------------------");
  Serial.printf("FINAL CALIBRATION RESULT\n");
  Serial.printf("DAC Value: %d | Threshold: %.3f V | Est. Input: %.3f V\n", currentDacValue, v_out_dac, v_input_est);
  Serial.println("----------------------------------------\n");
}

void setup() {
  Serial.begin(115200);
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
  runDacSAR(); 
}

void loop() {
  // ปุ่มเปลี่ยนความถี่
  static bool lastFreqSw = HIGH;
  bool currentFreqSw = digitalRead(SW_FREQ);
  if (lastFreqSw == HIGH && currentFreqSw == LOW) {
    delay(50); 
    if (digitalRead(SW_FREQ) == LOW) {
      freqMode = (freqMode + 1) % 4; 
      sendMode(freqMode);
      Serial.printf("\n>>> Changed to Freq Mode: %d\n", freqMode);
      delay(200); // ให้เวลาสัญญาณ Analog นิ่ง
      runDacSAR(); 
    }
  }
  lastFreqSw = currentFreqSw;

  // ปุ่มเปลี่ยนประเภทการวัด
  static bool lastTypeSw = HIGH;
  bool currentTypeSw = digitalRead(SW_TYPE);
  if (lastTypeSw == HIGH && currentTypeSw == LOW) {
    delay(50);
    if (digitalRead(SW_TYPE) == LOW) {
      measureMode = (measureMode == 4) ? 5 : 4; 
      sendMode(measureMode); 
      Serial.printf("\n>>> Switched to Type: %s\n", measureMode == 4 ? "PHASE" : "WIDTH");
    }
  }
  lastTypeSw = currentTypeSw;

  // การแสดงผลปกติ (เพิ่มการแสดงค่า DAC ต่อท้ายยาวๆ)
  if (digitalRead(REQ) == HIGH) {
    uint32_t count = getPhaseFromFPGA(); 
    if (count > 0) {
      float T_val = 1.0;
      switch (freqMode) {
        case 0: T_val = 480.0;    break; 
        case 1: T_val = 4800.0;   break; 
        case 2: T_val = 48000.0;  break; 
        case 3: T_val = 480000.0; break; 
      }
      float deg = ((float)count / T_val) * 360.0;
      float v_dac = (currentDacValue * 3.3) / 4095.0;

      Serial.printf("%s | M: %d | Count: %-8d | %6.2f deg | DAC: %4d (%.3f V)\n", 
                    (measureMode == 4 ? "PHASE" : "WIDTH"), 
                    freqMode, count, deg, currentDacValue, v_dac);
      delay(200); 
    }
  }
}