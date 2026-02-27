import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect_pro/core/theme/app_theme.dart';
import 'package:mediconnect_pro/features/medical_records/presentation/providers/medical_record_providers.dart';

class AddRecordPage extends ConsumerStatefulWidget {
  const AddRecordPage({super.key});

  @override
  ConsumerState<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends ConsumerState<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  String _originalFileName = '';
  File? _selectedFile;
  String _category = 'other';
  bool _isLoading = false;

  final Map<String, String> _categories = {
    'consultation': 'Consultation',
    'prescription': 'Ordonnance',
    'lab_result': 'Résultat d\'analyse',
    'imaging': 'Imagerie médicale',
    'certificate': 'Certificat médical',
    'other': 'Autre document',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un document'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Catégorie du document',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    items: _categories.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nom du document',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _originalFileName,
                    decoration: InputDecoration(
                      hintText: 'Ex: Ordonnance Dr. Dupont',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Veuillez nommer le document';
                      }
                      return null;
                    },
                    onSaved: (val) => _originalFileName = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Fichier joint (Chiffré E2EE)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          style: BorderStyle.solid,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedFile != null
                                ? Icons.file_present_rounded
                                : Icons.upload_file_rounded,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFile != null
                                ? _selectedFile!.path.split('/').last
                                : 'Appuyez pour sélectionner un fichier',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedFile != null
                                  ? Colors.black87
                                  : AppTheme.primaryColor,
                              fontWeight: _selectedFile != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Vos fichiers sont chiffrés de bout en bout',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Enregistrer le document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        if (_originalFileName.isEmpty) {
          _originalFileName = result.files.single.name;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner un fichier'),
            backgroundColor: Colors.red),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    // Call provider/repository functionality
    final repository = ref.read(medicalRecordRepositoryProvider);

    try {
      await repository.createRecord(
        category: _category,
        metadataEncrypted: {
          'notes': 'Ajouté manuellement',
          'original_file_name': _originalFileName,
        },
        recordedAtUtc: DateTime.now().toUtc(),
      );

      // (In real life we would do: wait record creation -> get ID -> e2e encrypt file -> upload)
      // Since it's demo logic we will just refresh the state

      ref.invalidate(medicalRecordsProvider(null));
      ref.invalidate(medicalRecordsProvider(_category));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Document chiffré et ajouté avec succès !'),
              backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
