#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_MCP4725.h>

#define MODE0 16
#define MODE1 17
#define MODE2 18
#define MODE3 19
#define WRITE 4

#define D0 32
#define D1 33
#define D2 25
#define D3 26
#define REQ 27
#define ACK 23

#define SW_FREQ 13  
#define SW_TYPE 14 

#define DAC_VALUE 2048 // defult 

Adafruit_MCP4725 dac;

uint8_t freqMode = 0;     
uint8_t measureMode = 5;  

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
            if (micros() - timeout > 10000) return 0; 
        }
        
        // --- จุดที่ต้องเพิ่ม ---
        delayMicroseconds(10); // รอให้ Data ในสาย D0-D3 นิ่งจริงๆ
        
        uint8_t nibble = (digitalRead(D3) << 3) | (digitalRead(D2) << 2) | 
                         (digitalRead(D1) << 1) | (digitalRead(D0) << 0);
        fullData |= ((uint32_t)nibble << (i * 4)); 
        
        digitalWrite(ACK, HIGH);
        while (digitalRead(REQ) == HIGH); 
        digitalWrite(ACK, LOW);
        
        delayMicroseconds(5); // รอให้ FPGA เคลียร์ State
    }
    return fullData;
}

void setup() {
  Serial.begin(115200);
  
  if (dac.begin(0x61)) {
    dac.setVoltage(DAC_VALUE, false);
  }

  pinMode(MODE0, OUTPUT); 
  pinMode(MODE1, OUTPUT);
  pinMode(MODE2, OUTPUT); 
  pinMode(MODE3, OUTPUT);
  pinMode(WRITE, OUTPUT);
  pinMode(D0, INPUT); 
  pinMode(D1, INPUT);
  pinMode(D2, INPUT); 
  pinMode(D3, INPUT);
  pinMode(REQ, INPUT);
  pinMode(ACK, OUTPUT);
  pinMode(SW_FREQ, INPUT_PULLUP);
  pinMode(SW_TYPE, INPUT_PULLUP); 
  
  digitalWrite(ACK, LOW);
  digitalWrite(WRITE, LOW);
  
  sendMode(measureMode); 
}

void loop() {
  if(count) {

  }
  else


  static bool lastFreqSw = HIGH;
  bool currentFreqSw = digitalRead(SW_FREQ);
  if (lastFreqSw == HIGH && currentFreqSw == LOW) {
    delay(50); 
    if (digitalRead(SW_FREQ) == LOW) {
      freqMode = (freqMode + 1) % 4; 
      sendMode(freqMode);
      Serial.print("Freq Mode: "); Serial.println(freqMode);
    }
  }
  lastFreqSw = currentFreqSw;

  static bool lastTypeSw = HIGH;
  bool currentTypeSw = digitalRead(SW_TYPE);
  if (lastTypeSw == HIGH && currentTypeSw == LOW) {
    delay(50);
    if (digitalRead(SW_TYPE) == LOW) {
      measureMode = (measureMode == 4) ? 5 : 4; 
      sendMode(measureMode); 
      Serial.println(measureMode == 4 ? "Type: PHASE" : "Type: PULSE");
    }
  }
  lastTypeSw = currentTypeSw;

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

      float result = ((float)count / T_val) * 360.0;
      if (measureMode == 4) {

        Serial.printf("Type: %d (PHASE) | M: %d | Count Phase: %-8d | Phase: %.2f deg\n", 
                      measureMode, freqMode, count, result);
      } 
      else if (measureMode == 5) {

        Serial.printf("Type: %d (WIDTH) | M: %d | Count Width: %-8d\n", 
                      measureMode, freqMode, count, result);
      }

      delay(200); 
    }
  }
}