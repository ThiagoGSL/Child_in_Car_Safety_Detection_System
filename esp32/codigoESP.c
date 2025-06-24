#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "esp_camera.h"

BLEServer* pServer = nullptr;
BLECharacteristic* pPhotoCharacteristic = nullptr;
// BLECharacteristic* pChildCharacteristic = nullptr; // Removido se não usado
// bool child = false; // Removido se não usado
bool deviceConnected = false;
bool oldDeviceConnected = false;

// UUIDs
#define SERVICE_UUID              "19b10000-e8f2-537e-4f6c-d104768a1214"
#define PHOTO_CHARACTERISTIC_UUID "6df8c9f3-0d19-4457-aec9-befd07394aa0"
// #define CHILD_CHARACTERISTIC_UUID "4f0ebb9b-74a5-429e-83dd-ebc3a2b37421" // Removido se não usado

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServerInstance) override { // Renomeado pServer para pServerInstance para evitar sombreamento
    deviceConnected = true;
    Serial.println("Dispositivo conectado");
  }
  void onDisconnect(BLEServer* pServerInstance) override { // Renomeado pServer para pServerInstance
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
  config.pixel_format = PIXFORMAT_JPEG; // Formato JPEG já contém SOI e EOI

  config.frame_size = FRAMESIZE_SVGA;   // 800x600. Pode reduzir para QVGA (320x240) ou VGA (640x480) para imagens menores e envio mais rápido.
  config.jpeg_quality = 12;             // 0-63, onde valores menores significam melhor qualidade e maior tamanho. 10-12 é um bom compromisso.
  config.fb_count = 1;                  // Usar 1 frame buffer é suficiente. Usar 2 pode ajudar com a taxa de quadros se estivesse fazendo streaming de vídeo rápido.
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY; // Pega o frame mais recente

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Erro ao inicializar câmera: 0x%x\n", err);
    ESP.restart(); // Reinicia se a câmera falhar
    return;
  }

  // Configurações adicionais da câmera (opcional)
  sensor_t * s = esp_camera_sensor_get();
  if (s) {
    // s->set_vflip(s, 1); // Inverter verticalmente, se necessário
    // s->set_hmirror(s, 1); // Espelhar horizontalmente, se necessário
  }
}

// Função de envio de foto revisada
void send_photo_BLE(camera_fb_t* fb) {
  if (!fb || !fb->buf || fb->len == 0) {
    Serial.println("send_photo_BLE: Frame buffer inválido ou vazio.");
    return;
  }
  if (!deviceConnected) {
    Serial.println("send_photo_BLE: Nenhum dispositivo conectado para enviar a foto.");
    return;
  }

  uint8_t* data = fb->buf; // fb->buf JÁ É um JPEG completo com SOI e EOI.
  size_t len = fb->len;

  // Imprime os primeiros e últimos bytes para depuração (opcional)
  // Serial.printf("Primeiros bytes do JPEG: 0x%02X 0x%02X\n", data[0], data[1]);
  // if (len > 2) {
  //   Serial.printf("Últimos bytes do JPEG: 0x%02X 0x%02X\n", data[len-2], data[len-1]);
  // }

  // O Flutter app pede MTU 247 (payload 244).
  // Um tamanho de chunk um pouco menor que isso é seguro e eficiente.
  const int chunkSize = 240;
  Serial.printf("Enviando foto de %u bytes em chunks de %d bytes...\n", len, chunkSize);

  for (size_t i = 0; i < len; i += chunkSize) {
    if (!deviceConnected) { // Verifica a conexão antes de cada envio
      Serial.println("Dispositivo desconectado durante o envio. Abortando.");
      return;
    }
    size_t currentChunkSize = (i + chunkSize < len) ? chunkSize : (len - i);
    
    pPhotoCharacteristic->setValue(data + i, currentChunkSize);
    pPhotoCharacteristic->notify();
    
    // Serial.printf("Enviado chunk: offset %u, tamanho %u\n", i, currentChunkSize); // Descomente para log detalhado

    delay(20); // Delay muito menor. Originalmente 500ms. Ajuste conforme necessário.
               // 15-30ms é um bom ponto de partida.
               // Um delay pequeno ajuda a não sobrecarregar o stack BLE e o receptor.
  }
  Serial.println("Todos os chunks da foto foram enviados.");
}

void setup() {
  Serial.begin(115200);
  Serial.println("Inicializando ESP32-CAM...");

  setupCamera();

  BLEDevice::init("ESP32-CAM-Enhanced"); // Nome do dispositivo BLE
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  pPhotoCharacteristic = pService->createCharacteristic(
                         PHOTO_CHARACTERISTIC_UUID,
                         BLECharacteristic::PROPERTY_NOTIFY
                       );
  pPhotoCharacteristic->addDescriptor(new BLE2902()); // Necessário para notificações

  // Se você tiver a característica da criança (pChildCharacteristic), adicione-a aqui.
  // pChildCharacteristic = pService->createCharacteristic(CHILD_CHARACTERISTIC_UUID, ...);
  // pChildCharacteristic->addDescriptor(new BLE2902());

  pService->start();

  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true); // Permite que mais dados sejam enviados na resposta do scan
  pAdvertising->setMinPreferred(0x06);  // Ajuda com a conexão em iOS
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising(); // Inicia o advertising

  Serial.println("Aguardando conexão BLE na Característica da Foto...");
}

void loop() {
  static unsigned long lastSendTime = 0;
  unsigned long currentTime = millis();
  const unsigned long sendInterval = 10000; // Intervalo de envio de fotos: 10 segundos. Ajuste conforme necessário.

  if (deviceConnected) {
    if (currentTime - lastSendTime >= sendInterval) {
      camera_fb_t* fb = esp_camera_fb_get();
      if (fb) {
        Serial.printf("Capturada imagem. Tamanho: %d bytes\n", fb->len);
        send_photo_BLE(fb); // Chama a função de envio revisada
        esp_camera_fb_return(fb); // Libera o buffer do frame
        Serial.println("Foto enviada e buffer liberado.");
      } else {
        Serial.println("Falha ao capturar imagem da câmera.");
      }
      lastSendTime = currentTime;
    }
  }

  // Gerenciamento da conexão e advertising
  if (!deviceConnected && oldDeviceConnected) {
    // O dispositivo foi desconectado
    delay(500); // Espera um pouco antes de reiniciar o advertising
    BLEDevice::startAdvertising(); // Reinicia o advertising para permitir novas conexões
    Serial.println("Reiniciando advertising BLE.");
    oldDeviceConnected = deviceConnected;
  }

  if (deviceConnected && !oldDeviceConnected) {
    // O dispositivo acabou de se conectar
    oldDeviceConnected = deviceConnected;
  }
  
  // Um pequeno delay no loop principal pode ajudar na estabilidade
  // delay(10); // Opcional, se não houver outras tarefas intensivas no loop
}
