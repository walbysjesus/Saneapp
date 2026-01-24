import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  bool _loading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'country': _countryController.text.trim(),
      'city': _cityController.text.trim(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/client-home');
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
                Text('Perfil Cliente', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'País'),
                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'Ciudad'),
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
