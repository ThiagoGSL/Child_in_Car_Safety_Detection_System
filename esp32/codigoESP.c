#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "esp_camera.h"

BLEServer* pServer = nullptr;
BLECharacteristic* pPhotoCharacteristic = nullptr;
BLECharacteristic* pCommandCharacteristic = nullptr;
bool deviceConnected = false;
bool oldDeviceConnected = false;

volatile bool isSendingPhoto = false;
volatile bool fotoSolicitadaManualmente = false;

// UUIDs
#define SERVICE_UUID              "19b10000-e8f2-537e-4f6c-d104768a1214"
#define PHOTO_CHARACTERISTIC_UUID "6df8c9f3-0d19-4457-aec9-befd07394aa0"
#define COMMAND_CHARACTERISTIC_UUID "a2191136-22a0-494b-a55c-a16250766324"


void send_photo_BLE(camera_fb_t* fb) {
  if (!fb || !fb->buf || fb->len == 0) {
    Serial.println("send_photo_BLE: Frame buffer inválido ou vazio.");
    return;
  }
  if (!deviceConnected) {
    Serial.println("send_photo_BLE: Nenhum dispositivo conectado para enviar a foto.");
    return;
  }

  uint8_t* data = fb->buf;
  size_t len = fb->len;
  const int chunkSize = 240;
  Serial.printf("Enviando foto de %u bytes em chunks de %d bytes...\n", len, chunkSize);

  for (size_t i = 0; i < len; i += chunkSize) {
    if (!deviceConnected) {
      Serial.println("Dispositivo desconectado durante o envio. Abortando.");
      return;
    }
    size_t currentChunkSize = (i + chunkSize < len) ? chunkSize : (len - i);
    pPhotoCharacteristic->setValue(data + i, currentChunkSize);
    pPhotoCharacteristic->notify();
    delay(20);
  }
  Serial.println("Todos os chunks da foto foram enviados.");
}


// ALTERADO com a lógica de "Flush"
void captureAndSendPhoto() {
  if (isSendingPhoto) {
    Serial.println("Aviso: Já há um envio de foto em andamento. Nova solicitação ignorada.");
    return;
  }
  if (!deviceConnected) {
    Serial.println("Aviso: Dispositivo não conectado. Envio de foto abortado.");
    return;
  }
  
  isSendingPhoto = true;

  // Bloco para limpar o buffer antes da captura real
  Serial.println("Limpando buffer da câmera para garantir foto recente...");
  camera_fb_t* fb_flush = esp_camera_fb_get();
  if (fb_flush) {
    esp_camera_fb_return(fb_flush); // Descarta o frame antigo que estava no buffer
    fb_flush = NULL; 
  }

  Serial.println(">>> Capturando novo frame (este será enviado)...");
  // Agora, esta chamada vai esperar por um quadro totalmente novo
  camera_fb_t* fb = esp_camera_fb_get();
  
  if (fb) {
    Serial.printf("Capturada imagem. Tamanho: %d bytes\n", fb->len);
    send_photo_BLE(fb);
    esp_camera_fb_return(fb); 
    Serial.println("Processo finalizado: Foto enviada e buffer liberado.");
  } else {
    Serial.println("Erro: Falha ao capturar imagem da câmera.");
  }
  isSendingPhoto = false; 
}


class CommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) override {
        String value = pCharacteristic->getValue();
        if (value.length() > 0 && value[0] == 1) {
            fotoSolicitadaManualmente = true;
            Serial.println("Flag de solicitação de foto MANUAL levantada!");
        }
    }
};

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServerInstance) override {
    deviceConnected = true;
    Serial.println("Dispositivo conectado");
  }
  void onDisconnect(BLEServer* pServerInstance) override {
    deviceConnected = false;
    Serial.println("Dispositivo desconectado");
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
  config.frame_size = FRAMESIZE_SVGA;
  config.jpeg_quality = 12;
  config.fb_count = 1;
  config.grab_mode = CAMERA_GRAB_LATEST;

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Erro ao inicializar câmera: 0x%x\n", err);
    ESP.restart();
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println("Inicializando ESP32-CAM (Modo Flush)...");
  setupCamera();
  BLEDevice::init("SafeBaby-CAM");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService* pService = pServer->createService(SERVICE_UUID);
  pPhotoCharacteristic = pService->createCharacteristic(
                         PHOTO_CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_NOTIFY);
  pPhotoCharacteristic->addDescriptor(new BLE2902());
  pCommandCharacteristic = pService->createCharacteristic(
                         COMMAND_CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_WRITE);
  pCommandCharacteristic->setCallbacks(new CommandCallbacks());
  pService->start();
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Aguardando conexão BLE...");
}


void loop() {
  static unsigned long lastSendTime = 0;
  const unsigned long sendInterval = 60000; 

  if (deviceConnected) {
    if (fotoSolicitadaManualmente) {
      fotoSolicitadaManualmente = false;
      Serial.println("---------------------------------");
      Serial.println("Processando solicitação de foto MANUAL...");
      Serial.println("---------------------------------");
      captureAndSendPhoto();
      lastSendTime = millis(); 
    }

    unsigned long currentTime = millis();
    if (currentTime - lastSendTime >= sendInterval) {
      Serial.println("---------------------------------");
      Serial.println("Timer periódico ativado (1 min).");
      Serial.println("---------------------------------");
      captureAndSendPhoto(); 
      lastSendTime = currentTime; 
    }
  }

  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    BLEDevice::startAdvertising();
    Serial.println("Reiniciando advertising BLE.");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}
