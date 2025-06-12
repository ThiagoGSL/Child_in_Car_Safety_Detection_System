import 'dart:async';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';


@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  if (action.buttonKeyPressed == 'CONFIRM_OK') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checkinConfirmed', true);
    await AwesomeNotifications().cancel(1);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  // Solicita permissão de notificação ao iniciar o app
  await Permission.notification.request();

  // Inicializa o plugin AwesomeNotifications e os canais de notificação
  await AwesomeNotifications().initialize(
    null, // @mipmap/ic_launcher - Use o ícone padrão do seu app
    [
      NotificationChannel(
        channelKey: 'checkin_channel',
        channelName: 'Check-In',
        channelDescription: 'Canal de check-in',
        importance: NotificationImportance.High,
        playSound: true,
      ),
      NotificationChannel(
        channelKey: 'alert_channel',
        channelName: 'Alerta de Perigo',
        channelDescription: 'Canal de alerta',
        importance: NotificationImportance.Max,
        playSound: true,
      ),
    ],
    debug: true, // Define como true para ver logs de depuração no console
  );

  // Registra o handler global para ações de notificação
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SensorPage(), // Define SensorPage como a tela inicial do aplicativo
      debugShowCheckedModeBanner: false, // Remove o banner de debug
    );
  }
}

// Enum para gerenciar os diferentes estados do check-in
enum CheckinStatus { idle, pending, confirmed, timeout }

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> with WidgetsBindingObserver {
  // Timers para controlar os contadores de "parado" e "alerta"
  Timer? _parkedTimer, _alertTimer;
  // Segundos restantes para o check-in e para o alerta
  int _checkinSeconds = 0, _alertSeconds = 0;
  // Flag para indicar se o carro está parado
  bool _carStopped = false;
  // Status atual do check-in
  CheckinStatus _status = CheckinStatus.idle;

  @override
  void initState() {
    super.initState();
    // Adiciona o observer para monitorar o ciclo de vida do aplicativo
    WidgetsBinding.instance.addObserver(this);
    // Restaura o status do check-in ao iniciar o app
    _restoreStatus();
  }

  @override
  void dispose() {
    // Remove o observer e cancela os timers ao descartar o widget
    WidgetsBinding.instance.removeObserver(this);
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    super.dispose();
  }

  // Monitora o ciclo de vida do aplicativo para verificar confirmação ao retornar
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForConfirmation(); // Checa se o check-in foi confirmado enquanto o app estava em segundo plano
    }
  }

  // Restaura o status de confirmação salvo nas preferências compartilhadas
  Future<void> _restoreStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      setState(() => _status = CheckinStatus.confirmed);
      await prefs.remove('checkinConfirmed'); // Remove o flag após restaurar
    }
  }

  // Verifica se o check-in foi confirmado via notificação
  Future<void> _checkForConfirmation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('checkinConfirmed') ?? false) {
      await prefs.remove('checkinConfirmed');
      _confirmCheckin(); // Se confirmado, atualiza o UI e cancela timers/notificações
    }
  }

  // Lógica para confirmar o check-in
  void _confirmCheckin() {
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    AwesomeNotifications().cancel(1); // Cancela a notificação de alerta (ID 1)
    setState(() => _status = CheckinStatus.confirmed);
  }

  // Lógica quando o carro para
  void _onCarStopped() {
    _resetAll(); // Reseta todos os estados e timers
    setState(() {
      _carStopped = true;
      _status = CheckinStatus.pending; // Estado pendente de check-in
      _checkinSeconds = 30; // Inicia o contador de 30 segundos
    });
    // Inicia o timer de check-in
    _parkedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_checkinSeconds > 0) {
        setState(() => _checkinSeconds--);
      } else {
        t.cancel();
        _showCheckinNotification(); // Mostra a notificação de check-in
      }
    });
  }

  // Lógica quando o carro está em movimento
  void _onCarMoving() {
    _resetAll(); // Reseta todos os estados e timers
    setState(() {
      _carStopped = false;
      _status = CheckinStatus.idle; // Retorna ao estado ocioso
    });
  }

  // Reseta todos os timers, contadores e cancela todas as notificações
  void _resetAll() {
    _parkedTimer?.cancel();
    _alertTimer?.cancel();
    setState(() {
      _checkinSeconds = 0;
      _alertSeconds = 0;
      _status = CheckinStatus.idle; // Garante que o status também seja resetado
    });
    AwesomeNotifications().cancelAll();
  }

  // Mostra a notificação de check-in
  Future<void> _showCheckinNotification() async {
    if (_status != CheckinStatus.pending) return; // Só mostra se o status for pendente
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0, // ID da notificação de check-in
        channelKey: 'checkin_channel',
        title: '⚠️ Carro parado',
        body: 'Seu carro está parado há 30 segundos. Tudo OK?',
      ),
      actionButtons: [
        NotificationActionButton(
            key: 'CONFIRM_OK', label: 'Tudo OK?', autoDismissible: true), // Botão de ação na notificação
      ],
    );
    _startAlertCountdown(); // Inicia o contador para o alerta de perigo
  }

  // Inicia o contador para a notificação de alerta de perigo
  void _startAlertCountdown() {
    if (_status != CheckinStatus.pending) return; // Só inicia se o status for pendente
    setState(() => _alertSeconds = 30); // Define 30 segundos para o alerta
    _alertTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_alertSeconds > 0) {
        setState(() => _alertSeconds--);
      } else {
        t.cancel();
        setState(() => _status = CheckinStatus.timeout); // Muda o status para timeout
        _showDangerNotification(); // Mostra a notificação de perigo
      }
    });
  }

  // Mostra a notificação de perigo
  Future<void> _showDangerNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1, // ID da notificação de perigo (para poder ser cancelada)
        channelKey: 'alert_channel',
        title: '🚨 Bebê em perigo!',
        body: 'Nenhuma resposta. Alerta enviado.',
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    // Mapeamento de status para textos visíveis na UI
    final labels = {
      CheckinStatus.idle: '—',
      CheckinStatus.pending: 'Aguardando resposta',
      CheckinStatus.confirmed: 'Confirmado: Tudo OK',
      CheckinStatus.timeout: 'Não confirmado: Alerta enviado',
    };
    // Mapeamento de status para cores de fundo na UI
    final colors = {
      CheckinStatus.idle: Colors.grey,
      CheckinStatus.pending: Colors.orange,
      CheckinStatus.confirmed: Colors.green,
      CheckinStatus.timeout: Colors.red,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Notificações')),
      body: Padding(
        padding: const EdgeInsets.all(20), // Padding geral no corpo da tela
        child: Column(
          children: [
            // Indicador de Status do Carro
            Container(
              width: double.infinity, // Ocupa toda a largura disponível
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _carStopped ? Colors.green : Colors.grey, // Cor baseada no status do carro
                borderRadius: BorderRadius.circular(8), // Cantos arredondados
              ),
              child: Text(
                _carStopped ? '🚗 Carro parado' : '🛣️ Carro em movimento',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20), // Espaçamento vertical

            // Botões de Ação
            ElevatedButton(
              onPressed: _onCarStopped,
              child: const Text('Parar carro'),
            ),
            const SizedBox(height: 10), // Espaçamento vertical
            ElevatedButton(
              onPressed: _onCarMoving,
              child: const Text('Movimentar carro'),
            ),
            const SizedBox(height: 20), // Espaçamento vertical

            // Indicadores de Tempo (Cronômetros)
            if (_checkinSeconds > 0)
              Text('⏱️ Check-in em: $_checkinSeconds s'),
            if (_alertSeconds > 0)
              Text(
                '⏱️ Alerta em: $_alertSeconds s',
                style: const TextStyle(color: Colors.red), // Texto vermelho para o alerta
              ),
            const SizedBox(height: 20), // Espaçamento vertical

            // Indicador de Status do Check-in/Alerta
            Container(
              width: double.infinity, // Ocupa toda a largura disponível
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors[_status], // Cor baseada no status do check-in
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                labels[_status]!, // Texto baseado no status do check-in
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}