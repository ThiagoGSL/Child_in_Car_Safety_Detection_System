#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "esp_camera.h"

BLEServer* pServer = nullptr;
BLECharacteristic* pPhotoCharacteristic = nullptr;
BLECharacteristic* pChildCharacteristic = nullptr;
bool child = false;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// UUIDs
#define SERVICE_UUID               "19b10000-e8f2-537e-4f6c-d104768a1214"
#define PHOTO_CHARACTERISTIC_UUID  "6df8c9f3-0d19-4457-aec9-befd07394aa0"
#define CHILD_CHARACTERISTIC_UUID  "4f0ebb9b-74a5-429e-83dd-ebc3a2b37421"

class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
  }
  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
  }
};

void setupCamera() {
  camera_config_t config;
  // Configuração dos pinos (ajuste conforme seu board)
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer   = LEDC_TIMER_0;
  config.pin_d0       = 5;
  config.pin_d1       = 18;
  config.pin_d2       = 19;
  config.pin_d3       = 21;
  config.pin_d4       = 36;
  config.pin_d5       = 39;
  config.pin_d6       = 34;
  config.pin_d7       = 35;
  config.pin_xclk     = 0;
  config.pin_pclk     = 22;
  config.pin_vsync    = 25;
  config.pin_href     = 23;
  config.pin_sscb_sda = 26;
  config.pin_sscb_scl = 27;
  config.pin_pwdn     = 32;
  config.pin_reset    = -1;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  config.frame_size = FRAMESIZE_VGA;
  config.jpeg_quality = 12;
  config.fb_count = 1;

  esp_camera_init(&config);
}

void send_photo(camera_fb_t* fb) {
  const int chunkSize = 150;
  uint8_t* data = fb->buf;
  int len = fb->len;

  // Início JPEG (0xFF D8)
  uint8_t startMarker[2] = {0xFF, 0xD8};
  pPhotoCharacteristic->setValue(startMarker, 2);
  pPhotoCharacteristic->notify();
  delay(10);

  // Fragmentação
  for (int i = 0; i < len; i += chunkSize) {
    int sendSize = min(chunkSize, len - i);
    pPhotoCharacteristic->setValue(data + i, sendSize);
    pPhotoCharacteristic->notify();
    delay(20);
  }

  // Fim JPEG (0xFF D9)
  uint8_t endMarker[2] = {0xFF, 0xD9};
  pPhotoCharacteristic->setValue(endMarker, 2);
  pPhotoCharacteristic->notify();
  delay(10);
}

void send_child(bool child) {
  pChildCharacteristic->setValue(String(child).c_str());
  pChildCharacteristic->notify();
  delay(500);
}

void setup() {
  Serial.begin(115200);
  setupCamera();

  // Inicializar BLE
  BLEDevice::init("ESP32-CAM");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);
  pPhotoCharacteristic = pService->createCharacteristic(
    PHOTO_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pChildCharacteristic = pService->createCharacteristic(
    CHILD_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pPhotoCharacteristic->addDescriptor(new BLE2902());
  pChildCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();
  Serial.println("Aguardando conexão BLE...");
}

void loop() {
  if (deviceConnected) {
    delay(3000);
    camera_fb_t* fb = esp_camera_fb_get();
    if (fb) {
      send_photo(fb);
      send_child(child);
      esp_camera_fb_return(fb);
    } else {
      Serial.println("Falha ao capturar imagem");
    }
  }

  if (!deviceConnected && oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    pServer->startAdvertising();
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}
