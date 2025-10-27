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
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Otros campos
  String? _country;
  DateTime? _birthDate;
  bool _acceptTerms = false;

  // UI state
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _loading = false;

  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 100, now.month, now.day);
    final last = DateTime(now.year - 10, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Aceptar')),
        ],
      ),
    );
  }

  Future<void> _register() async {
    final formOK = _formKey.currentState?.validate() ?? false;
    if (!formOK) return;
    if (_country == null || _country!.isEmpty) {
      _showError('Selecciona tu país.');
      return;
    }
    if (_birthDate == null) {
      _showError('Selecciona tu fecha de nacimiento.');
      return;
    }
    if (!_acceptTerms) {
      _showError('Debes aceptar los términos y la política de privacidad.');
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final uid = cred.user!.uid;

      // Guarda perfil extendido
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'country': _country,
        'birth_date': Timestamp.fromDate(_birthDate!),
        'created_at': FieldValue.serverTimestamp(),
        'email_verified': false,
        'avatar': '',
        'role': 'user',
      }, SetOptions(merge: true));

      // Verificación de correo
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
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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
                const SizedBox(height: 20),

                Text('Nombre', style: tt.labelLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameCtrl,
                  validator: (v) => _required(v, label: 'Nombre'),
                  decoration: const InputDecoration(
                    hintText: 'Tu nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Apellido', style: tt.labelLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _lastNameCtrl,
                  validator: (v) => _required(v, label: 'Apellido'),
                  decoration: const InputDecoration(
                    hintText: 'Tu apellido',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Correo electrónico', style: tt.labelLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                  decoration: const InputDecoration(
                    hintText: 'tu@email.com',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Contraseña', style: tt.labelLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _hidePassword,
                  validator: _passwordValidator,
                  decoration: InputDecoration(
                    hintText: '********',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Confirmar contraseña', style: tt.labelLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _hideConfirm,
                  validator: _confirmValidator,
                  decoration: InputDecoration(
                    hintText: '********',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_hideConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Teléfono', style: tt.labelLarge),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: (v) => _required(v, label: 'Teléfono'),
                  decoration: const InputDecoration(
                    hintText: '+593 9xxxxxxx',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                Text('País', style: tt.labelLarge),
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
                const SizedBox(height: 14),

                Text('Fecha de nacimiento', style: tt.labelLarge),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.cake_outlined),
                      hintText: 'Selecciona una fecha',
                    ),
                    child: Text(
                      _birthDate == null
                          ? 'Selecciona una fecha'
                          : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Acepto los Términos de uso y la Política de privacidad.',
                        style: tt.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya tienes cuenta?', style: tt.bodyMedium),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/login'),
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
