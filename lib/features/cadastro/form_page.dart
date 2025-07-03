import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class FormPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final c = Get.find<FormController>();

  FormPage({super.key});

  // 1. As máscaras de telefone foram definidas aqui para reutilização
  final _phoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final _emergencyPhoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<MaskTextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.done, // 2. Adicionado para navegação
    IconData? prefixIcon,
  }) {
    final themeColor = const Color(0xFF53BF9D);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        cursorColor: themeColor,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          floatingLabelStyle: TextStyle(color: themeColor),
          // 3. Adicionado ícone de prefixo para melhor indicação visual
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white54) : null,
          border: inputBorder,
          enabledBorder: inputBorder,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeColor, width: 2),
          ),
          errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2)),
          focusedErrorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2)),
        ),
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction, // Aplicando a ação do teclado
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Carrega os dados iniciais no controller, se necessário.
    // c.loadData(); // Supondo que você tenha um método para carregar os dados.

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              label: 'Nome',
              initialValue: c.userName.value,
              onChanged: (v) => c.userName.value = v,
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              prefixIcon: Icons.person_outline,
            ),
            _buildTextField(
              label: 'Nome da Criança',
              initialValue: c.childName.value,
              onChanged: (v) => c.childName.value = v,
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              prefixIcon: Icons.child_care_outlined,
            ),
            _buildTextField(
              label: 'E-mail',
              initialValue: c.email.value,
              onChanged: (v) => c.email.value = v,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v != null && v.isEmail) ? null : 'E-mail inválido',
              prefixIcon: Icons.email_outlined,
            ),
            _buildTextField(
              label: 'Telefone',
              initialValue: c.phone.value,
              onChanged: (v) => c.phone.value = v,
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneMask], // Usando a máscara
              validator: (v) => (v != null && v.length >= 15) ? null : 'Telefone inválido',
              prefixIcon: Icons.phone_outlined,
            ),
            _buildTextField(
              label: 'Contato de Emergência',
              initialValue: c.emergencyName.value,
              onChanged: (v) => c.emergencyName.value = v,
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              prefixIcon: Icons.contact_emergency_outlined,
            ),
            _buildTextField(
              label: 'Telefone de Emergência',
              initialValue: c.emergencyPhone.value,
              onChanged: (v) => c.emergencyPhone.value = v,
              keyboardType: TextInputType.phone,
              inputFormatters: [_emergencyPhoneMask], // Usando a máscara
              validator: (v) => (v != null && v.length >= 15) ? null : 'Telefone inválido',
              prefixIcon: Icons.phone_in_talk_outlined,
              textInputAction: TextInputAction.done, // Último campo
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // Valida o formulário inteiro de uma vez
                if (_formKey.currentState?.validate() ?? false) {
                  await c.saveData(); // Chama o método de salvar do controller
                  
                  Get.snackbar(
                    'Sucesso!',
                    'Suas informações foram atualizadas.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: const Color(0xFF16213E),
                    colorText: Colors.white,
                    margin: EdgeInsets.zero,
                    borderRadius: 0,
                    icon: const Icon(Icons.check_circle_outline, color: Color(0xFF53BF9D)),
                    snackStyle: SnackStyle.GROUNDED,
                    duration: const Duration(seconds: 3),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF53BF9D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Salvar Alterações',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  // 4. Melhoria de contraste: Texto branco fica melhor no botão verde
                  color: Colors.white, 
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