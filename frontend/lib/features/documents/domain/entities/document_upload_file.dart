library;

import 'dart:typed_data';

class DocumentUploadFile {
  final String name;
  final Uint8List bytes;
  final int size;
  final String? path;

  const DocumentUploadFile({
    required this.name,
    required this.bytes,
    required this.size,
    this.path,
  });

  String get extension {
    final index = name.lastIndexOf('.');
    if (index < 0 || index == name.length - 1) {
      return '';
    }

    return name.substring(index + 1).toLowerCase();
  }
}
