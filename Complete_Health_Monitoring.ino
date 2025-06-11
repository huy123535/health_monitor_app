#include <MAX3010x.h>
#include <Wire.h>
#include "filters2.h"
#include "Protocentral_MAX30205.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// BLE Service and Characteristic UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// BLE variables
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

// Sensor declarations
MAX30101 sensor;
MAX30205 tempSensor;
const auto kSamplingRate = sensor.SAMPLING_RATE_400SPS;
const float kSamplingFrequency = 400.0;

// Temperature reading interval
const unsigned long TEMP_READING_INTERVAL = 1000; // Read temperature every second
unsigned long last_temp_reading = 0;
float current_temperature = 0.0;

// BLE Callback class
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Device connected");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Device disconnected");
    }
};

void setup() {
  Serial.begin(115200);
  Wire.begin(1,0);
  
  // Initialize BLE
  BLEDevice::init("HealthMonitor");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create BLE Characteristic
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );

  // Add descriptor
  pCharacteristic->addDescriptor(new BLE2902());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("BLE device started, waiting for connections...");

  // Initialize MAX30101 sensor
  if(sensor.begin() && sensor.setSamplingRate(kSamplingRate)) {
    // ... existing sensor setup code ...
  }
}

void loop() {
  // Read temperature periodically
  if (millis() - last_temp_reading >= TEMP_READING_INTERVAL) {
    float temp = tempSensor.oneShotTemperature();
    current_temperature = averager_temp.process(temp);
    last_temp_reading = millis();
  }

  // Read sensor data
  auto sample = sensor.readSample(1000);
  float current_value_red = sample.red;
  float current_value_ir = sample.ir;
  
  // ... existing sensor processing code ...

  if(finger_detected) {
    // ... existing processing code ...
    
    if(crossed && current_diff < kEdgeThreshold) {
      if(last_heartbeat != 0 && crossed_time - last_heartbeat > 300) {
        // Calculate heart rate and SpO2
        int bpm = 60000/(crossed_time - last_heartbeat);
        float rred = (stat_red.maximum()-stat_red.minimum())/stat_red.average();
        float rir = (stat_ir.maximum()-stat_ir.minimum())/stat_ir.average();
        float r = rred/rir;
        float spo2 = kSpO2_A * r * r + kSpO2_B * r + kSpO2_C;
        
        if(bpm > 50 && bpm < 250) {
          // Create JSON string with sensor data
          String sensorData = "{\"heartRate\": " + String(bpm) + ", \"spo2\": " + String(spo2) + ", \"temperature\": " + String(current_temperature) + "}";
          
          // Send data via BLE if connected
          if (deviceConnected) {
            pCharacteristic->setValue(sensorData.c_str());
            pCharacteristic->notify();
          }

          // Print to Serial for debugging
          Serial.print("Time (ms): ");
          Serial.println(millis()); 
          Serial.print("Heart Rate (current, bpm): ");
          Serial.println(bpm);  
          Serial.print("SpO2 (current, %): ");
          Serial.println(spo2);
          Serial.print("Temperature (°C): ");
          Serial.println(current_temperature);
        }

        // Reset statistics
        stat_red.reset();
        stat_ir.reset();
      }

      crossed = false;
      last_heartbeat = crossed_time;
    }
  }
  
  delay(20);
} 