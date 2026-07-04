import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pantalla de gestiÃ³n de roles para administraciÃ³n
class AdminManageRolesPage extends StatefulWidget {
  const AdminManageRolesPage({super.key});

  @override
  State<AdminManageRolesPage> createState() => _AdminManageRolesPageState();
}

class _AdminManageRolesPageState extends State<AdminManageRolesPage> {
  final _auth = FirebaseAuth.instance;

  Future<bool> _isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['role'] == 'admin';
  }

  Stream<QuerySnapshot> _allUsers() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Future<void> _updateRole(String userId, String newRole) async {
    final allowedRoles = ['generador', 'proveedor', 'supervisor', 'admin'];
    if (!allowedRoles.contains(newRole)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rol no permitido.')));
      return;
    }
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final adminDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    if (adminDoc.data()?['role'] != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Solo un administrador puede cambiar roles.')));
      return;
    }
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final oldRole = userDoc.data()?['role'] ?? '';
    if (oldRole == 'admin' && newRole != 'admin') {
      // No permitir degradar admins desde la UI
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se puede degradar un admin desde la UI.')));
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': newRole});
    // Auditoría de cambio de rol
    await FirebaseFirestore.instance.collection('role_changes').add({
      'userId': userId,
      'oldRole': oldRole,
      'newRole': newRole,
      'changedBy': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rol actualizado a $newRole')));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.data!) {
          return const Scaffold(body: Center(child: Text('Acceso restringido')));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('GestiÃ³n de roles')),
          body: StreamBuilder<QuerySnapshot>(
            stream: _allUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('No hay usuarios'));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final user = docs[index].data() as Map<String, dynamic>;
                  final userId = docs[index].id;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(user['name'] ?? 'Sin nombre'),
                      subtitle: Text('Email: ${user['email'] ?? 'N/A'}\nRol actual: ${user['role'] ?? 'N/A'}'),
                      trailing: DropdownButton<String>(
                        value: user['role'],
                        items: const [
                          DropdownMenuItem(value: 'generador', child: Text('Generador')),
                          DropdownMenuItem(value: 'proveedor', child: Text('Proveedor')),
                          DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (newRole) {
                          if (newRole != null) {
                            _updateRole(userId, newRole);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

