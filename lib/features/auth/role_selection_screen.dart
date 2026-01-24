import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final data = {'role': role};
    if (role == 'provider') data['providerStatus'] = 'pending';
    await userDoc.set(data, SetOptions(merge: true));
    if (!context.mounted) return;
    if (role == 'client') {
      Navigator.pushReplacementNamed(context, '/client-profile');
    } else {
      Navigator.pushReplacementNamed(context, '/provider-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text('¿Cómo quieres usar SaneApp?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 32),
              _RoleCard(
                title: 'Solicitar servicios ambientales',
                description: 'Soy cliente y quiero solicitar servicios.',
                icon: Icons.person,
                onTap: () => _selectRole(context, 'client'),
              ),
              const SizedBox(height: 24),
              _RoleCard(
                title: 'Ofrecer servicios ambientales',
                description: 'Soy proveedor y quiero ofrecer servicios.',
                icon: Icons.business_center,
                onTap: () => _selectRole(context, 'provider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(description, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
