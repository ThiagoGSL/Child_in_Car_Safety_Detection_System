import 'package:app_v0/features/cadastro/form_controller.dart';
import 'package:app_v0/features/onboarding/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class OnboardingFormPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final FormController c = Get.find<FormController>();
  final OnboardingController onboardingController = Get.find<OnboardingController>();

  OnboardingFormPage({super.key, required this.formKey});

  final _phoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final _emergencyPhoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<MaskTextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.next,
    IconData? prefixIcon,
  }) {
    const themeColor = Color(0xFF53BF9D);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        initialValue: initialValue,
        cursorColor: themeColor,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          floatingLabelStyle: const TextStyle(color: themeColor),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white54) : null,
          border: inputBorder,
          enabledBorder: inputBorder,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: themeColor, width: 2),
          ),
          errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2)),
          focusedErrorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2)),
        ),
        keyboardType: keyboardType,
        validator: validator,
        onChanged: (v) {
          onChanged(v);
          // MODIFICAÇÃO: A chamada c.saveData() foi removida daqui.
          // A validação continua para habilitar/desabilitar o botão Concluir em tempo real.
          onboardingController.checkFormValidity();
        },
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados Importantes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Com esses dados, o SafeBaby saberá como te chamar e quem contatar em uma emergência.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Seu Nome',
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
                validator: (v) => (v != null && GetUtils.isEmail(v)) ? null : 'E-mail inválido',
                prefixIcon: Icons.email_outlined,
              ),
              _buildTextField(
                label: 'Telefone',
                initialValue: c.phone.value,
                onChanged: (v) => c.phone.value = v,
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneMask],
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
                inputFormatters: [_emergencyPhoneMask],
                validator: (v) => (v != null && v.length >= 15) ? null : 'Telefone inválido',
                prefixIcon: Icons.phone_in_talk_outlined,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
