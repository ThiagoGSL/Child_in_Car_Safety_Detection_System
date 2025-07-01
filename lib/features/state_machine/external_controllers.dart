import 'package:get/get.dart';

/**
 * Simula os controllers que fornecem os inputs externos para a máquina de estados.
 * No aplicativo real, estes controllers conteriam a lógica de hardware (Bluetooth),
 * sensores (GPS, acelerómetro) ou outras fontes de dados.
 */

/// Simula a deteção do movimento do veículo.
class CarroController extends GetxController {
  /// `true` se o veículo estiver em movimento.
  final andando = false.obs;
}

/// Simula os inputs relacionados com a deteção de presença e a interação do utilizador.
class DeteccaoController extends GetxController {
  /// `true` se a câmara ou outro sensor detetar uma presença contínua.
  final faceDetectada = false.obs;

  /// `true` se o sensor de peso ou outro mecanismo confirmar a presença de um bebé.
  final temBebe = false.obs;

  /// `true` quando um temporizador de segurança (ex: sem movimento) expira.
  /// Este valor é definido por um `Timer` na `MaquinaDeEstadosController`.
  final tempoSeguroExpirado = false.obs;

  /// `true` se o utilizador não interagir com uma notificação dentro de um tempo limite.
  /// Este valor é definido por um `Timer` na `MaquinaDeEstadosController`.
  final semResposta = false.obs;
}
