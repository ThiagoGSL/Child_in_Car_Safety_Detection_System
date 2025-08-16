import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class FormPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final c = Get.find<FormController>();

  FormPage({super.key});

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _emergencyPhoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<MaskTextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.done,
    IconData? prefixIcon,
  }) {
    const primaryColor = Color(0xFF53A194);
    const textColor = Color(0xFF524F42);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: textColor.withOpacity(0.2)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        cursorColor: primaryColor,
        style: const TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.5)),
          floatingLabelStyle: const TextStyle(color: primaryColor),
          prefixIcon:
              prefixIcon != null ? Icon(prefixIcon, color: primaryColor) : null,
          border: inputBorder,
          enabledBorder: inputBorder,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: inputBorder.copyWith(
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: inputBorder.copyWith(
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF53A194);
    const secondaryColor = Color(0xFFE5E0D2);
    const textColor = Color(0xFF524F42);

    return Scaffold(
      backgroundColor: secondaryColor,
      body: SingleChildScrollView(
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
                validator:
                    (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                prefixIcon: Icons.person_outline,
              ),
              _buildTextField(
                label: 'Nome da Criança',
                initialValue: c.childName.value,
                onChanged: (v) => c.childName.value = v,
                validator:
                    (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                prefixIcon: Icons.child_care_outlined,
              ),
              _buildTextField(
                label: 'E-mail',
                initialValue: c.email.value,
                onChanged: (v) => c.email.value = v,
                keyboardType: TextInputType.emailAddress,
                validator:
                    (v) =>
                        (v != null && GetUtils.isEmail(v))
                            ? null
                            : 'E-mail inválido',
                prefixIcon: Icons.email_outlined,
              ),
              _buildTextField(
                label: 'Telefone',
                initialValue: c.phone.value,
                onChanged: (v) => c.phone.value = v,
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneMask],
                validator:
                    (v) =>
                        (v != null && v.length >= 15)
                            ? null
                            : 'Telefone inválido',
                prefixIcon: Icons.phone_outlined,
              ),
              _buildTextField(
                label: 'Contato de Emergência',
                initialValue: c.emergencyName.value,
                onChanged: (v) => c.emergencyName.value = v,
                validator:
                    (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                prefixIcon: Icons.contact_emergency_outlined,
              ),
              _buildTextField(
                label: 'Telefone de Emergência',
                initialValue: c.emergencyPhone.value,
                onChanged: (v) => c.emergencyPhone.value = v,
                keyboardType: TextInputType.phone,
                inputFormatters: [_emergencyPhoneMask],
                validator:
                    (v) =>
                        (v != null && v.length >= 15)
                            ? null
                            : 'Telefone inválido',
                prefixIcon: Icons.phone_in_talk_outlined,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    await c.saveData();

                    Get.snackbar(
                      'Sucesso!',
                      'Suas informações foram atualizadas.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: primaryColor,
                      colorText: secondaryColor,
                      margin: const EdgeInsets.all(12),
                      borderRadius: 12,
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: secondaryColor,
                      ),
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Salvar Alterações',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
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
