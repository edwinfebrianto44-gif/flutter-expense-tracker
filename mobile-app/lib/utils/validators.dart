import 'package:form_builder_validators/form_builder_validators.dart';

class AppValidators {
  static String? Function(String?) email = FormBuilderValidators.compose([
    FormBuilderValidators.required(errorText: 'Email harus diisi'),
    FormBuilderValidators.email(errorText: 'Format email tidak valid'),
  ]);

  static String? Function(String?) password = FormBuilderValidators.compose([
    FormBuilderValidators.required(errorText: 'Password harus diisi'),
    FormBuilderValidators.minLength(6, errorText: 'Password minimal 6 karakter'),
  ]);

  static String? Function(String?) name = FormBuilderValidators.compose([
    FormBuilderValidators.required(errorText: 'Nama harus diisi'),
    FormBuilderValidators.minLength(2, errorText: 'Nama minimal 2 karakter'),
  ]);

  static String? Function(String?) amount = FormBuilderValidators.compose([
    FormBuilderValidators.required(errorText: 'Jumlah harus diisi'),
    FormBuilderValidators.numeric(errorText: 'Jumlah harus berupa angka'),
    FormBuilderValidators.min(1, errorText: 'Jumlah harus lebih dari 0'),
  ]);

  static String? Function(String?) description = FormBuilderValidators.compose([
    FormBuilderValidators.required(errorText: 'Deskripsi harus diisi'),
    FormBuilderValidators.minLength(3, errorText: 'Deskripsi minimal 3 karakter'),
  ]);

  static String? Function(Object?) category = FormBuilderValidators.compose([
    FormBuilderValidators.required(errorText: 'Kategori harus dipilih'),
  ]);

  static String? Function(Object?) date = FormBuilderValidators.compose([
    FormBuilderValidators.required(errorText: 'Tanggal harus dipilih'),
  ]);

  static String? categoryName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama kategori harus diisi';
    }
    if (value.length < 2) {
      return 'Nama kategori minimal 2 karakter';
    }
    return null;
  }
}
