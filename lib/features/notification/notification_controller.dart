import 'dart:convert';
import 'package:app_v0/features/notification/notification_model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController extends GetxController {
  var notifications = <AppNotification>[].obs;
  var unreadCount = 0.obs;

  final String _storageKey = 'notifications_history';

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> init() async {
    print("NotificationController: Iniciando carregamento do histórico de notificações...");
    await _loadNotificationsFromStorage();
    print("NotificationController: Inicialização concluída.");
  }

  void addNotification(String message, NotificationType type) {
    final newNotification = AppNotification(
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    notifications.insert(0, newNotification);
    unreadCount.value++;
    // Salva a lista toda vez que uma nova notificação é adicionada.
    _saveNotificationsToStorage();
  }

  void markNotificationsAsRead() {
    unreadCount.value = 0;
  }

  void clearNotifications() {
    notifications.clear();
    unreadCount.value = 0;
    // Salva a lista vazia para limpar o armazenamento.
    _saveNotificationsToStorage();
  }

  // --- MÉTODOS DE PERSISTÊNCIA (sem alterações) ---

  /// Salva a lista atual de notificações no armazenamento do dispositivo.
  Future<void> _saveNotificationsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> notificationsJson =
          notifications.map((notification) => notification.toJson()).toList();
      final String jsonString = json.encode(notificationsJson);
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
        final List<dynamic> notificationsJson = json.decode(jsonString);
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