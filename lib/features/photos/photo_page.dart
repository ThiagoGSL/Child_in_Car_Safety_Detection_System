import 'dart:io';
import 'package:app_v0/features/bluetooth/ble_controller.dart';
import 'package:app_v0/features/photos/photo_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PhotoPage extends StatelessWidget {
  final PhotoController photoController = Get.find<PhotoController>();
  final BluetoothController bleController = Get.find<BluetoothController>();

  final Color accentColor = const Color(0xFF53BF9D);
  final Color backgroundColor = const Color(0xFF1A1A2E);
  final Color dialogColor = const Color(0xFF16213E);

  PhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Obx(() {
        final photoFile = photoController.lastPhoto.value;

        if (photoFile == null) {
          return _buildEmptyState();
        }

        return _buildPhotoDisplay(photoFile);
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          const Icon(Icons.photo_library_outlined, size: 80, color: Colors.white38),
          const SizedBox(height: 12),
          const Text('Galeria Vazia', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Use o botão abaixo para tirar sua primeira foto.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 50),
          OutlinedButton.icon(
            onPressed: () => bleController.requestPhoto(),
            icon: Icon(Icons.camera_alt_outlined, color: accentColor),
            label: Text(
              'Tirar Foto',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accentColor, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildPhotoDisplay(File photoFile) {
    final fileStat = photoFile.statSync();
    final formattedDate = DateFormat('dd/MM/yyyy \'às\' HH:mm').format(fileStat.modified);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Última Captura',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: accentColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Recebida em: $formattedDate',
                        style: const TextStyle(fontSize: 15, color: Colors.white60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              spreadRadius: 2,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14.5),
                          child: InteractiveViewer(
                            maxScale: 5.0,
                            child: Image.file(
                              File(photoFile.path),
                              key: ValueKey(photoFile.lastModifiedSync()),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildActionButtons(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionColumn(
            onPressed: () => photoController.shareLastPhoto(),
            icon: Icons.share,
            label: 'Compartilhar',
            color: accentColor,
          ),
        ),
        Expanded(
          child: _buildActionColumn(
            onPressed: () => bleController.requestPhoto(),
            icon: Icons.camera_alt_outlined,
            label: 'Tirar Foto', 
            color: accentColor,
          ),
        ),
        Expanded(
          child: _buildActionColumn(
            onPressed: () => _showDeleteDialog(),
            icon: Icons.delete_outline,
            label: 'Excluir',
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildActionColumn({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.normal, 
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: dialogColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Excluir Foto', style: TextStyle(color: Colors.white)),
        content: const Text('Tem certeza que deseja excluir esta foto?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              photoController.deleteLastPhoto();
              Get.back();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}