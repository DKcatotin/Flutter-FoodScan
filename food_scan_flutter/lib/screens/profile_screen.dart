import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar imagen (agrega en pubspec)

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
final GoogleSignIn googleSignIn = GoogleSignIn();

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';
  String avatarUrl = '';
  bool loading = true;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (!mounted) return;
      setState(() {
        email = user.email ?? '';
      });
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (!mounted) return;
        if (doc.exists && doc.data() != null) {
          setState(() {
            name = doc.data()!['name'] ?? '';
            avatarUrl = doc.data()!['avatar'] ?? '';
            loading = false;
          });
        } else {
          setState(() {
            name = '(no configurado)';
            avatarUrl = '';
            loading = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          name = '(error de conexión)';
          avatarUrl = '';
          loading = false;
        });
      }
    }
  }

  Future<void> editNameDialog() async {
    final controller = TextEditingController(text: name);
    final user = FirebaseAuth.instance.currentUser;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Editar nombre'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'Nuevo nombre'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final newName = controller.text.trim();

                  if (newName.isNotEmpty && user != null) {
                    final navigator = Navigator.of(
                      context,
                    ); // Captura el Navigator antes del await

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'name': newName});

                    if (!mounted) return;

                    setState(() => name = newName);
                    navigator.pop(); // Uso seguro del contexto capturado
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          ),
    );
  }

  Future<void> editPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && user != null) {
      // Aquí deberías subir la imagen a Firebase Storage y obtener la URL, por ahora se simula local
      final String fakeUrl = picked.path;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'avatar': fakeUrl},
      );
      setState(() => avatarUrl = fakeUrl);
    }
  }

 void logout() async {
  await FirebaseAuth.instance.signOut();
  await googleSignIn.signOut(); // Cierra sesión Google
  // Limpia data de UI
  setState(() {
    name = '';
    email = '';
    avatarUrl = '';
  });

  if (!mounted) return;
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: Text('Mi Perfil', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      backgroundColor: Color(0xFFF9F9FB),
      body: loading
    ? const Center(child: CircularProgressIndicator())
    : SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                GestureDetector(
  onTap: editPhoto,
  child: CircleAvatar(
    radius: 45,
    backgroundColor: Colors.black,
    backgroundImage: (avatarUrl.isNotEmpty)
        ? (avatarUrl.startsWith('http')
            ? NetworkImage(avatarUrl)
            : FileImage(File(avatarUrl)) as ImageProvider)
        : null,
    child: avatarUrl.isEmpty
        ? const Icon(Icons.person, size: 54, color: Colors.white)
        : null,
  ),
),
                TextButton(
                  onPressed: editPhoto,
                  child: const Text('Editar foto'),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Nombre'),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: editNameDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.edit, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Correo electrónico'),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  width: double.infinity,
                  child: Text(email, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: logout,
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
