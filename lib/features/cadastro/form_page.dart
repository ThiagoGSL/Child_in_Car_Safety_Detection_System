import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FormPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  // O controller é encontrado, pois já foi inicializado no main.dart
  final c = Get.find<FormController>();

  FormPage({super.key});

  /// Widget que exibe o campo com texto + botão editar, ou campo editável
  Widget _buildEditableField({
    required BuildContext context,
    required String label,
    required RxString rxVar,
    required RxBool isEditing,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // Nenhuma alteração neste widget auxiliar
    return Obx(() {
      if (isEditing.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: Colors.blue,
                selectionColor: Colors.blueAccent,
                selectionHandleColor: Colors.blue,
              ),
            ),
            child: TextFormField(
              initialValue: rxVar.value,
              cursorColor: Colors.blue,
              decoration: InputDecoration(
                labelText: label,
                floatingLabelStyle: const TextStyle(color: Colors.blue),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, color: Colors.blue),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      c.toggleEditing(label);
                      c.saveData();
                    }
                  },
                  tooltip: 'Salvar',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              keyboardType: keyboardType,
              validator: validator,
              onChanged: (v) => rxVar.value = v,
              autofocus: true,
            ),
          ),
        );
      } else {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: Colors.black87,
                    ) ??
                    const TextStyle(fontSize: 15, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  TextSpan(
                    text: rxVar.value.isEmpty ? "(vazio)" : rxVar.value,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Editar',
              onPressed: () {
                c.toggleEditing(label);
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // >>> ESTRUTURA ALTERADA <<<
    // O conteúdo foi envolvido por um Scaffold para criar uma página completa.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Usuário'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEditableField(
                context: context,
                label: 'Seu Nome',
                rxVar: c.userName,
                isEditing: c.editingUserName,
                validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              _buildEditableField(
                context: context,
                label: 'Nome da Criança',
                rxVar: c.childName,
                isEditing: c.editingChildName,
                validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              _buildEditableField(
                context: context,
                label: 'E-mail',
                rxVar: c.email,
                isEditing: c.editingEmail,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v != null && v.contains('@')) ? null : 'Email inválido',
              ),
              _buildEditableField(
                context: context,
                label: 'Telefone',
                rxVar: c.phone,
                isEditing: c.editingPhone,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v != null && v.length >= 8) ? null : 'Telefone inválido',
              ),
              _buildEditableField(
                context: context,
                label: 'Nome Contato de Emergência',
                rxVar: c.emergencyName,
                isEditing: c.editingEmergencyName,
                validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              _buildEditableField(
                context: context,
                label: 'Telefone de Emergência',
                rxVar: c.emergencyPhone,
                isEditing: c.editingEmergencyPhone,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v != null && v.length >= 8) ? null : 'Inválido',
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    await c.saveData();
                    Get.snackbar(
                      'Sucesso',
                      'Dados salvos!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.blue.withOpacity(0.8),
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Salvar',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}