import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _legalController = TextEditingController();
  bool _loading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'company': _companyController.text.trim(),
      'legalInfo': _legalController.text.trim(),
      'providerStatus': 'pending',
    }, SetOptions(merge: true));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/provider-home');
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 32),
                Text('Perfil Proveedor', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Nombre de empresa'),
                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _legalController,
                  decoration: const InputDecoration(labelText: 'Datos legales'),
                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
