//Código para tirar foto e enviar via ble, para ver arquivos, baixar nRF Connect
//Envia booleano se tem crianca ou nao, falta apenas a parte de analisar a foto com ML

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "esp_camera.h"

BLEServer* pServer = NULL;
BLECharacteristic* pPhotoCharacteristic = NULL;
BLECharacteristic* pChildCharacteristic = NULL;
bool child = false;
bool deviceConnected = false;
bool oldDeviceConnected = false;
uint32_t value = 0;

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/
#define SERVICE_UUID        "19b10000-e8f2-537e-4f6c-d104768a1214"
#define PHOTO_CHARACTERISTIC_UUID "6df8c9f3-0d19-4457-aec9-befd07394aa0"
#define CHILD_CHARACTERISTIC_UUID "4f0ebb9b-74a5-429e-83dd-ebc3a2b37421"

class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
  };

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
  }
};

void setupCamera() {
  camera_config_t config;
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

void send_photo(camera_fb_t * fb){
  Serial.println("Sending...");
  int chunkSize = 150;
  int len = fb->len;
  uint8_t* data = fb->buf;

  for (int i = 0; i < len; i += chunkSize) {
    int sendSize = (i + chunkSize < len) ? chunkSize : len - i;
    pPhotoCharacteristic->setValue(data + i, sendSize);
    pPhotoCharacteristic->notify();
    Serial.println(i);
    delay(20); // evita congestionamento BLE
  }
  Serial.println("Enviado photo");
  delay(5000); // aguarda antes de capturar novamente
}


void send_child(bool child){
  Serial.println("Sending...bool");
  pChildCharacteristic->setValue(String(child).c_str());
  pChildCharacteristic->notify();
  Serial.println("Enviado bool");
  delay(5000);
}


void setup() {
  Serial.begin(115200);
  setupCamera();

  // Create the BLE Device
  BLEDevice::init("ESP32");

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // cam BLE
  pPhotoCharacteristic = pService->createCharacteristic(
                      PHOTO_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  // Bool of child
  pChildCharacteristic = pService->createCharacteristic(
                      CHILD_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  // https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.descriptor.gatt.client_characteristic_configuration.xml
  // Create a BLE Descriptor
  pPhotoCharacteristic->addDescriptor(new BLE2902());
  pChildCharacteristic->addDescriptor(new BLE2902());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  Serial.println("Waiting a client connection to notify...");
}


void loop() {
  if (deviceConnected) {
    delay(3000);

    //capturing image
    camera_fb_t * fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Falha ao capturar imagem");
      return;
    }
    esp_camera_fb_return(fb);
    Serial.println("Imagem capturada com sucesso");

    //processar imagem e descobrir se tem crianca aqui


    //sending via ble
    //send_photo(fb);
    send_child(child);
  }

  // disconnecting
  if (!deviceConnected && oldDeviceConnected) {
    Serial.println("Device disconnected.");
    delay(500); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("Start advertising");
    oldDeviceConnected = deviceConnected;
  }
  // connecting
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    Serial.println("Device Connected");
  }
}                  
