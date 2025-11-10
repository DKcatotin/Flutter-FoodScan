import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': user.displayName ?? '',
        'email': user.email,
        'avatar': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      return;
    }

    try {
      await _ensureUserDoc(user);

      if (!mounted) return;
      setState(() {
        email = user.email ?? '';
      });

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          name = (data['name'] ?? '').toString().isEmpty
              ? '(no configurado)'
              : data['name'];
          avatarUrl = (data['avatar'] ?? '').toString();
          loading = false;
        });
      } else {
        setState(() {
          name = '(no configurado)';
          avatarUrl = '';
          loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        name = '(error de conexión)';
        avatarUrl = '';
        loading = false;
      });
    }
  }

  Future<void> editNameDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para editar tu nombre.')),
      );
      return;
    }

    final controller = TextEditingController(text: name == '(no configurado)' ? '' : name);
    final focusNode = FocusNode();
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        // Pide foco y coloca cursor al final al pintar el diálogo
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!focusNode.hasFocus) {
            focusNode.requestFocus();
            controller.selection = TextSelection.collapsed(offset: controller.text.length);
          }
        });

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Future<void> _save() async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                setStateDialog(() => errorText = 'El nombre no puede estar vacío');
                return;
              }
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set(
                  {
                    'name': newName,
                    'updatedAt': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true), // ✅ crea o actualiza
                );

                if (!mounted) return;
                setState(() => name = newName);
                Navigator.of(dialogCtx).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nombre actualizado.')),
                );
              } on FirebaseException catch (e) {
                setStateDialog(() => errorText = e.message ?? e.code);
              } catch (_) {
                setStateDialog(() => errorText = 'Ocurrió un error al actualizar.');
              }
            }

            return AlertDialog(
              title: const Text('Editar nombre'),
              content: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.name,
                maxLines: 1,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: 'Nuevo nombre',
                  helperText: null,    // evita strings vacías -> SPAN logs
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: _save,
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    focusNode.dispose();
  }

  Future<void> editPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para editar tu foto.')),
      );
      return;
    }

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      // TODO: Subir a Firebase Storage y obtener URL real
      final String fakeUrl = picked.path;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'avatar': fakeUrl, 'updatedAt': FieldValue.serverTimestamp()},
               SetOptions(merge: true)); // ✅ no falla si no existe

      if (!mounted) return;
      setState(() => avatarUrl = fakeUrl);
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: editPhoto,
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: cs.primary,
                        backgroundImage: (avatarUrl.isNotEmpty)
                            ? (avatarUrl.startsWith('http')
                                ? NetworkImage(avatarUrl)
                                : FileImage(File(avatarUrl)) as ImageProvider)
                            : null,
                        child: avatarUrl.isEmpty
                            ? Icon(Icons.person, size: 54, color: cs.onPrimary)
                            : null,
                      ),
                    ),
                    TextButton(
                      onPressed: editPhoto,
                      child: const Text('Editar foto'),
                    ),
                    const SizedBox(height: 18),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nombre', style: textTheme.bodyMedium),
                    ),
                    const SizedBox(height: 4),

                    GestureDetector(
                      onTap: editNameDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant,
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
                                style: textTheme.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.edit, size: 18, color: cs.outline),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Correo electrónico', style: textTheme.bodyMedium),
                    ),
                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.outlineVariant,
                          width: 1,
                        ),
                      ),
                      width: double.infinity,
                      child: Text(email, style: textTheme.bodyLarge),
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
    );
  }
}
