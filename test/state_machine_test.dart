import 'package:app_v0/features/statemachine/state_machine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // O 'group' serve para agrupar testes relacionados
  group('Testes da MaquinaDeEstados', () {

    // Declara a variável que será usada nos testes
    late MaquinaDeEstados maquinaDeEstados;

    // 'setUp' é executado antes de cada teste no grupo
    setUp(() {
      // Garante que uma nova instância seja criada para cada teste
      maquinaDeEstados = MaquinaDeEstados();
    });

    test('Estado inicial deve ser "idle"', () {
      // Verifica se o estado inicial é EstadoApp.idle
      expect(maquinaDeEstados.estadoAtual, EstadoApp.idle);
    });

    test('Evento "bluetoothconectado" deve transitar de "idle" para "conectado"', () {
      // 1. Processa o evento
      maquinaDeEstados.processarEvento(EventoApp.bluetoothconectado);

      // 2. Verifica se o estado mudou para o esperado
      expect(maquinaDeEstados.estadoAtual, EstadoApp.conectado);
    });

    test('Evento "facedetectada" deve transitar de "conectado" para "monitorando"', () {
      // Define um estado inicial para o teste
      maquinaDeEstados.definirEstadoParaTeste(EstadoApp.conectado);

      // Processa o evento
      maquinaDeEstados.processarEvento(EventoApp.facedetectada);

      // Verifica a transição
      expect(maquinaDeEstados.estadoAtual, EstadoApp.monitorando);
    });

    test('Sequência de eventos: "monitorando" -> "notificacaoinicial" -> "alerta"', () {
      // Estado inicial da sequência
      maquinaDeEstados.definirEstadoParaTeste(EstadoApp.monitorando);
      expect(maquinaDeEstados.estadoAtual, EstadoApp.monitorando);

      // Evento 1: Tempo seguro expira
      maquinaDeEstados.processarEvento(EventoApp.temposeguroexpirado);
      expect(maquinaDeEstados.estadoAtual, EstadoApp.notificacaoinicial);

      // Evento 2: Usuário não responde
      maquinaDeEstados.processarEvento(EventoApp.semresposta);
      expect(maquinaDeEstados.estadoAtual, EstadoApp.alerta);
    });

    test('Não deve mudar de estado com um evento inválido', () {
      // No estado 'idle', o evento 'carroparado' não deve fazer nada
      maquinaDeEstados.processarEvento(EventoApp.carroparado);

      // O estado deve permanecer 'idle'
      expect(maquinaDeEstados.estadoAtual, EstadoApp.idle);
    });

  });
}