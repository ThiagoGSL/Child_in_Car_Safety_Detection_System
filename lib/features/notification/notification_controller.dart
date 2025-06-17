import 'dart:convert'; // <-- IMPORTANTE: Necessário para codificar/decodificar JSON
import 'package:app_v0/features/notification/notification_model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- IMPORTANTE: Importe o pacote

class NotificationController extends GetxController {
  var notifications = <AppNotification>[].obs;
  var unreadCount = 0.obs;

  // Chave única para salvar as notificações no dispositivo
  final String _storageKey = 'notifications_history';

  @override
  void onInit() {
    super.onInit();
    // <-- MUDANÇA: Carrega as notificações salvas quando o controller é iniciado.
    _loadNotificationsFromStorage();
  }

  void addNotification(String message, NotificationType type) {
    final newNotification = AppNotification(
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    notifications.insert(0, newNotification);
    unreadCount.value++;
    // <-- MUDANÇA: Salva a lista toda vez que uma nova notificação é adicionada.
    _saveNotificationsToStorage();
  }

  void markNotificationsAsRead() {
    unreadCount.value = 0;
  }

  void clearNotifications() {
    notifications.clear();
    unreadCount.value = 0;
    // <-- MUDANÇA: Salva a lista vazia para limpar o armazenamento.
    _saveNotificationsToStorage();
  }

  // --- NOVOS MÉTODOS DE PERSISTÊNCIA ---

  /// Salva a lista atual de notificações no armazenamento do dispositivo.
  Future<void> _saveNotificationsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Converte a lista de objetos AppNotification para uma lista de Mapas (JSON)
      final List<Map<String, dynamic>> notificationsJson =
          notifications.map((notification) => notification.toJson()).toList();
      // Codifica a lista de mapas em uma única string JSON
      final String jsonString = json.encode(notificationsJson);
      // Salva a string no SharedPreferences
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('❌ Erro ao salvar notificações: $e');
    }
  }

  /// Carrega a lista de notificações do armazenamento do dispositivo.
  Future<void> _loadNotificationsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        // Decodifica a string JSON para uma lista de mapas
        final List<dynamic> notificationsJson = json.decode(jsonString);
        // Converte a lista de mapas de volta para uma lista de objetos AppNotification
        notifications.value = notificationsJson
            .map((jsonItem) => AppNotification.fromJson(jsonItem))
            .toList();
        print('✅ Notificações carregadas do armazenamento: ${notifications.length} itens.');
      }
    } catch (e) {
      print('❌ Erro ao carregar notificações: $e');
    }
  }
}