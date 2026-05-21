import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageNotifier extends ChangeNotifier {
  ImageNotifier() {
    _initializeDocumentsPath();
  }

  String _resultImage = '';
  String get resultImage => _resultImage;
  set resultImage(String value) {
    _resultImage = value;
    notifyListeners();
  }

  String? _documentsPath;

  String? getImagePath(String? storedPath) {
    if (_documentsPath == null || storedPath == null || storedPath.isEmpty) return null;
    
    if (File(storedPath).isAbsolute && File(storedPath).existsSync()) {
      return storedPath;
    }

    final fileName = storedPath.split('/').last;
    if (fileName.isEmpty) return null;
    return '$_documentsPath/$fileName';
  }

  Future<void> _initializeDocumentsPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    _documentsPath = appDir.path;
    notifyListeners();
  }

  Future<void> pickImage({required ImageSource source}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (_documentsPath == null) {
        await _initializeDocumentsPath();
      }
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fullPath = '${appDir.path}/$fileName';
      await File(pickedFile.path).copy(fullPath);
      resultImage = fullPath;
    }
  }

  void clearImage() {
    resultImage = '';
  }
}

final imageProvider = ChangeNotifierProvider<ImageNotifier>(
  (ref) => ImageNotifier(),
);
