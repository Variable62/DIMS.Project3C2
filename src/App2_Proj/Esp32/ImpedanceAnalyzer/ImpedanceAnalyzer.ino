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

struct MeasResult {
    uint32_t count;
    float degree;
};

uint8_t freqMode = 0;     
uint8_t measureMode = 4;   
uint16_t currentDacValue = 3385; 

// --- Calibration Settings ---
// หลังจากวัดค่าบันได 16 ขั้นแล้ว ให้เอาค่ามาแก้ตรงนี้ครับ
float calFactor = 1.0656; // ตัวอย่าง: สั่ง 3385 แต่ออกจริงน้อยไป ต้องคูณเพิ่ม

// --- Functions ---

// ฟังก์ชันส่งค่าเข้า DAC แบบมีการ Calibrate
void setDacVoltage(uint16_t rawValue, bool writeEEPROM = false) {
    uint32_t calValue = (uint32_t)(rawValue * calFactor);
    if (calValue > 4095) calValue = 4095;
    dac.setVoltage((uint16_t)calValue, writeEEPROM);
}

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

// ฟังก์ชันสร้างสัญญาณบันได 16 ขั้น ตามที่อาจารย์สั่ง
void runDacCalibration() {
  Serial.println("\n--- [DAC CALIBRATION MODE: MANUAL STEP] ---");
  Serial.println("Type anything and press Enter to go to the next step...");
  
  for (int step = 0; step < 16; step++) {
    uint16_t dacVal = step << 8; 
    dac.setVoltage(dacVal, false);
    
    Serial.printf("\n[Step %d/15] DAC Value: %4d | Binary: %04b", step, dacVal, step);
    Serial.print(" -> Waiting for your measurement...");

    // หยุดรอจนกว่าจะมีคนพิมพ์อะไรส่งมาใน Serial
    while (Serial.available() == 0) {
        // รอเฉยๆ
    }
    Serial.readString(); // อ่านทิ้งเพื่อเคลียร์บัฟเฟอร์สำหรับรอบหน้า
  }
  
  Serial.println("\n--- CALIBRATION DONE ---");
  // คืนค่าเดิม
  if (measureMode == 4) dac.setVoltage(0, false);
  else setDacVoltage(currentDacValue);
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
        if (val > 0) { sumCount += val; countValid++; }
        delay(5);
    }
    if (countValid > 0) {
        res.count = (uint32_t)(sumCount / countValid);
        float T_val = (freqMode == 0) ? 480.0 : (freqMode == 1) ? 4800.0 : (freqMode == 2) ? 48000.0 : 480000.0;
        res.degree = ((float)res.count / T_val) * 360.0;
    }
    return res;
}

void setup() {
  Serial.begin(115200);
  Wire.begin();
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
  if(measureMode == 4) dac.setVoltage(0, false);
  else setDacVoltage(currentDacValue);
  
  Serial.println("\n--- [SYSTEM READY] ---");
  Serial.println("Commands: 'c' for Calibrate, 's' for SAR");
}

void loop() {
  // รับคำสั่งจาก Serial
  if (Serial.available() > 0) {
    char cmd = Serial.read();
    if (cmd == 'c') runDacCalibration();
  }

  // ส่วนสลับความถี่
  static bool lastF = HIGH;
  bool cf = digitalRead(SW_FREQ);
  if (lastF == HIGH && cf == LOW) {
    delay(50); 
    if(digitalRead(SW_FREQ) == LOW) { 
      freqMode = (freqMode + 1) % 4; 
      sendMode(freqMode); 
      Serial.printf(">> Freq Switched: %d\n", freqMode);
    }
  }
  lastF = cf;

  // ส่วนสลับโหมดวัด
  static bool lastT = HIGH;
  bool ct = digitalRead(SW_TYPE);
  if (lastT == HIGH && ct == LOW) {
    delay(50); 
    if(digitalRead(SW_TYPE) == LOW) { 
      measureMode = (measureMode == 4) ? 5 : 4; 
      sendMode(measureMode); 
      
      if (measureMode == 4) dac.setVoltage(0, false); 
      else setDacVoltage(currentDacValue);   
      
      uint32_t waitTime = millis();
      while(digitalRead(REQ) == HIGH && (millis() - waitTime < 200)) getCountFromFPGA(); 
      
      Serial.printf("\n>> MODE: %s\n", (measureMode == 4 ? "PHASE" : "WIDTH"));
    }
  }
  lastT = ct;

  // อ่านค่าและแสดงผล
  if (digitalRead(REQ) == HIGH) {
    MeasResult res = getMeasurement(1);
    if (res.degree >= 0) {
      float v_actual = (measureMode == 4) ? 0 : (currentDacValue * 3.3 * calFactor) / 4095.0;
      Serial.printf("%s | M:%d | Count:%-8d | Deg:%6.2f | DAC:%4d | Vdac_est:%.3fV\n", 
                    (measureMode == 4 ? "PHASE" : "WIDTH"), freqMode, res.count, res.degree, 
                    (measureMode == 4 ? 0 : currentDacValue), v_actual);
      delay(300); 
    }
  }
}