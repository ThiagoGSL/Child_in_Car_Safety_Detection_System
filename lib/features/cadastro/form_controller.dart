import 'package:app_v0/features/cadastro/data/app_database.dart';
import 'package:get/get.dart';
import 'package:drift/drift.dart' as d;

class FormController extends GetxController {
  final db = AppDatabase();

  // Campos reativos do formulário
  var userName       = ''.obs;
  var childName      = ''.obs;
  var email          = ''.obs;
  var phone          = ''.obs;
  var emergencyName  = ''.obs;
  var emergencyPhone = ''.obs;

  // Controle de edição individual por campo
  var editingUserName       = false.obs;
  var editingChildName      = false.obs;
  var editingEmail          = false.obs;
  var editingPhone          = false.obs;
  var editingEmergencyName  = false.obs;
  var editingEmergencyPhone = false.obs;

  // Lista reativa de todos os registros no banco
  var records = <UserData>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// Carrega o primeiro registro e atualiza campos reativos
  Future<void> loadData() async {
    final list = await db.select(db.userDatas).get();
    records.assignAll(list);

    if (list.isNotEmpty) {
      final u = list.first;
      userName.value       = u.userName;
      childName.value      = u.childName;
      email.value          = u.email;
      phone.value          = u.phone;
      emergencyName.value  = u.emergencyName;
      emergencyPhone.value = u.emergencyPhone;
    }

    // Resetar edição ao carregar
    editingUserName.value       = false;
    editingChildName.value      = false;
    editingEmail.value          = false;
    editingPhone.value          = false;
    editingEmergencyName.value  = false;
    editingEmergencyPhone.value = false;

    update();
  }

  /// Salva ou atualiza o registro e recarrega os dados do banco
  Future<void> saveData() async {
    final companion = UserDatasCompanion(
      userName:       d.Value(userName.value),
      childName:      d.Value(childName.value),
      email:          d.Value(email.value),
      phone:          d.Value(phone.value),
      emergencyName:  d.Value(emergencyName.value),
      emergencyPhone: d.Value(emergencyPhone.value),
    );

    final existing = await db.select(db.userDatas).get();

    if (existing.isEmpty) {
      await db.into(db.userDatas).insert(companion);
    } else {
      final id = existing.first.id;
      await db.update(db.userDatas).replace(
        companion.copyWith(id: d.Value(id)),
      );
    }

    // Recarrega dados após salvar
    await loadData();

    print('––– Registros no banco (${records.length}) –––');
    for (var u in records) {
      print('• [${u.id}] ${u.userName}, ${u.childName}, ${u.email}, '
            '${u.phone}, ${u.emergencyName}, ${u.emergencyPhone}');
    }
  }

  /// Alterna o estado de edição do campo indicado
  void toggleEditing(String fieldName) {
    switch (fieldName) {
      case 'Seu Nome':
        editingUserName.value = !editingUserName.value;
        break;
      case 'Nome da Criança':
        editingChildName.value = !editingChildName.value;
        break;
      case 'E-mail':
        editingEmail.value = !editingEmail.value;
        break;
      case 'Telefone':
        editingPhone.value = !editingPhone.value;
        break;
      case 'Nome Contato de Emergência':
        editingEmergencyName.value = !editingEmergencyName.value;
        break;
      case 'Telefone de Emergência':
        editingEmergencyPhone.value = !editingEmergencyPhone.value;
        break;
    }
  }

  /// Para finalizar edição, pode-se criar métodos que desativem edição de um campo específico
  void disableEditing(String fieldName) {
    switch (fieldName) {
      case 'Seu Nome':
        editingUserName.value = false;
        break;
      case 'Nome da Criança':
        editingChildName.value = false;
        break;
      case 'E-mail':
        editingEmail.value = false;
        break;
      case 'Telefone':
        editingPhone.value = false;
        break;
      case 'Nome Contato de Emergência':
        editingEmergencyName.value = false;
        break;
      case 'Telefone de Emergência':
        editingEmergencyPhone.value = false;
        break;
    }
  }
}
