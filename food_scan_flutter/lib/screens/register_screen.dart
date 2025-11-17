import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _country;

  // UI state
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _loading = false;

  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ===== Validadores =====
  String? _required(String? v, {String label = 'Este campo'}) {
    if (v == null || v.trim().isEmpty) return '$label es obligatorio';
    return null;
  }

  String? _emailValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Correo es obligatorio';
    final ok = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(value);
    if (!ok) return 'Correo inválido';
    return null;
  }

  String? _passwordValidator(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Contraseña es obligatoria';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _confirmValidator(String? v) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
    if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    final formOK = _formKey.currentState?.validate() ?? false;
    if (!formOK) return;

    setState(() => _loading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'display_name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'country': _country,
        'created_at': FieldValue.serverTimestamp(),
        'email_verified': false,
        'avatar': '',
        'role': 'user',
      }, SetOptions(merge: true));

      // Verificación de correo (opcional pero profesional)
      try {
        await cred.user!.sendEmailVerification();
      } catch (_) {}

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('¡Registro exitoso!'),
          content: const Text(
            'Tu cuenta ha sido creada. Te enviamos un correo de verificación. '
            'Revisa tu bandeja y luego inicia sesión.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Ocurrió un error. Intenta nuevamente.';
      switch (e.code) {
        case 'invalid-email':
          msg = 'El correo electrónico es inválido.';
          break;
        case 'email-already-in-use':
          msg = 'Ya existe una cuenta con ese correo.';
          break;
        case 'weak-password':
          msg = 'La contraseña es débil (mínimo 6 caracteres).';
          break;
      }
      _showError(msg);
    } catch (e) {
      _showError('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        centerTitle: true,
        // 👉 Flecha para volver al login
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(Icons.person_add_alt_1, size: 48),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Crea tu cuenta para empezar a escanear productos y revisar su información nutricional.',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Nombre
                Text('Nombre', style: tt.labelLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameCtrl,
                  validator: (v) => _required(v, label: 'Nombre'),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Tu nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),

                // Correo
                Text('Correo electrónico', style: tt.labelLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'tu@email.com',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 14),

                // Contraseña
                Text('Contraseña', style: tt.labelLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _hidePassword,
                  validator: _passwordValidator,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: '********',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirmar Contraseña
                Text('Confirmar contraseña', style: tt.labelLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _hideConfirm,
                  validator: _confirmValidator,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: '********',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hideConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _hideConfirm = !_hideConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // País (opcional pero útil)
                Text('País (opcional)', style: tt.labelLarge),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _country,
                  items: const [
                    DropdownMenuItem(value: 'Ecuador', child: Text('Ecuador')),
                    DropdownMenuItem(value: 'México', child: Text('México')),
                    DropdownMenuItem(value: 'Colombia', child: Text('Colombia')),
                    DropdownMenuItem(value: 'Perú', child: Text('Perú')),
                    DropdownMenuItem(value: 'España', child: Text('España')),
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],
                  onChanged: (v) => setState(() => _country = v),
                  decoration: const InputDecoration(
                    hintText: 'Selecciona tu país',
                    prefixIcon: Icon(Icons.public),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Crear cuenta
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Crear cuenta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Link para ir al login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya tienes cuenta?', style: tt.bodyMedium),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
