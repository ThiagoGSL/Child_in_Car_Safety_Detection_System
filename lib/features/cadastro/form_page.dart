import 'dart:math';

import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FormPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final c = Get.find<FormController>();

  FormPage({super.key});

  Widget _buildEditableField({
    required BuildContext context,
    required String label,
    required RxString rxVar,
    required RxBool isEditing,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final themeColor = const Color(0xFF53BF9D);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
    );
    final focusedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: themeColor, width: 2),
    );

    return Obx(() {
      if (isEditing.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: TextFormField(
            initialValue: rxVar.value,
            cursorColor: themeColor,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white54),
              floatingLabelStyle: TextStyle(color: themeColor),
              suffixIcon: IconButton(
                icon: Icon(Icons.check, color: themeColor),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    c.toggleEditing(label);
                    c.saveData();
                  }
                },
                tooltip: 'Salvar',
              ),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedInputBorder,
              errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2)),
              focusedErrorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2)),
            ),
            keyboardType: keyboardType,
            validator: validator,
            onChanged: (v) => rxVar.value = v,
            autofocus: true,
          ),
        );
      } else {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Text(
              label,
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                rxVar.value.isEmpty ? "(Não definido)" : rxVar.value,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.white54),
              tooltip: 'Editar',
              onPressed: () => c.toggleEditing(label),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEditableField(context: context, label: 'Seu Nome', rxVar: c.userName, isEditing: c.editingUserName, validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null),
            _buildEditableField(context: context, label: 'Nome da Criança', rxVar: c.childName, isEditing: c.editingChildName, validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null),
            _buildEditableField(context: context, label: 'E-mail', rxVar: c.email, isEditing: c.editingEmail, keyboardType: TextInputType.emailAddress, validator: (v) => (v != null && v.contains('@')) ? null : 'Email inválido'),
            _buildEditableField(context: context, label: 'Telefone', rxVar: c.phone, isEditing: c.editingPhone, keyboardType: TextInputType.phone, validator: (v) => (v != null && v.length >= 8) ? null : 'Telefone inválido'),
            _buildEditableField(context: context, label: 'Contato de Emergência', rxVar: c.emergencyName, isEditing: c.editingEmergencyName, validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null),
            _buildEditableField(context: context, label: 'Telefone de Emergência', rxVar: c.emergencyPhone, isEditing: c.editingEmergencyPhone, keyboardType: TextInputType.phone, validator: (v) => (v != null && v.length >= 8) ? null : 'Inválido'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  await c.saveData();
                  
                  // SNACKBAR MODIFICADA
                  Get.snackbar(
                    'Sucesso!', // Título
                    'Suas informações foram atualizadas.', // Mensagem
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: const Color(0xFF16213E), // Cor de fundo escura
                    colorText: Colors.white,
                    margin: EdgeInsets.zero, // Necessário para o estilo "grounded"
                    borderRadius: 0, // Necessário para o estilo "grounded"
                    icon: const Icon(Icons.check_circle_outline, color: Color(0xFF53BF9D)), // Ícone com a cor de destaque
                    snackStyle: SnackStyle.GROUNDED, // Estilo ancorado
                    duration: const Duration(seconds: 3)
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF53BF9D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Salvar Alterações',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF16213E),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}