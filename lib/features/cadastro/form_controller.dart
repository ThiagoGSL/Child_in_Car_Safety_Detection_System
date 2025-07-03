import 'package:app_v0/features/cadastro/data/app_database.dart';
import 'package:get/get.dart';
import 'package:drift/drift.dart' as d;

class FormController extends GetxController {
  final db = AppDatabase();

  // Campos reativos do formulário.
  var userName       = ''.obs;
  var childName      = ''.obs;
  var email          = ''.obs;
  var phone          = ''.obs;
  var emergencyName  = ''.obs;
  var emergencyPhone = ''.obs;

  var records = <UserData>[].obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> init() async {
    print("FormController: Iniciando carregamento dos dados do banco...");
    await loadData();
    print("FormController: Inicialização concluída.");
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
    update();
  }

  /// Salva ou atualiza o registro e recarrega os dados do banco
  Future<void> saveData() async {

    // Lê os valores atuais das variáveis .obs e os salva no banco.
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

    await loadData(); // Recarrega para garantir consistência

    print('––– Registros no banco (${records.length}) –––');
    for (var u in records) {
      print('• [${u.id}] ${u.userName}, ${u.childName}, ${u.email}, ${u.phone}, ${u.emergencyName}, ${u.emergencyPhone}');
    }
  }
}