#include <Arduino.h>

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

#define SW 13

uint8_t currentMode = 0; 

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

        delayMicroseconds(5);
        uint8_t nibble = (digitalRead(D3) << 3) | (digitalRead(D2) << 2) | 
                         (digitalRead(D1) << 1) | (digitalRead(D0) << 0);
        
        fullData |= ((uint32_t)nibble << (i * 4)); 

        digitalWrite(ACK, HIGH);
        while (digitalRead(REQ) == HIGH); 
        digitalWrite(ACK, LOW);
        delayMicroseconds(2); // wait FPGA Clear state
    }
    return fullData;
}
void setup() {
  Serial.begin(115200);
  
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
  pinMode(SW, INPUT_PULLUP);
  
  digitalWrite(ACK, LOW);
  digitalWrite(WRITE, LOW);

  Serial.println("System Ready");
  sendMode(currentMode);
}

void loop() {

  static bool lastSwState = HIGH;
  bool currentSwState = digitalRead(SW);

  if (lastSwState == HIGH && currentSwState == LOW) {
    delay(50); 
    if (digitalRead(SW) == LOW) {
      currentMode = (currentMode + 1) % 4; 
      sendMode(currentMode); 
      Serial.print(">> Mode Changed to: ");
      Serial.println(currentMode);
    }
  }
  lastSwState = currentSwState;

  if (digitalRead(REQ) == HIGH) {
    uint32_t count = getPhaseFromFPGA(); 

    if (count > 0 && count <= 1048575) {
      float T_val = 1.0;
      switch (currentMode) {
        case 0: T_val = 480.0;    break; // 100 kHz
        case 1: T_val = 4800.0;   break; // 10 kHz
        case 2: T_val = 48000.0;  break; // 1 kHz
        case 3: T_val = 480000.0; break; // 100 Hz
      }

      float phaseDeg = ((float)count / T_val) * 360.0;

      Serial.print("Mode : "); Serial.print(currentMode);
      Serial.print(" | Count: "); Serial.print(count);
      Serial.print(" | Phase: "); Serial.print(phaseDeg, 2);
      Serial.println(" deg");
      delay(500);
    }
  }
}