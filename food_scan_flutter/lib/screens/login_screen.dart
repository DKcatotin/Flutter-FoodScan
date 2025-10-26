import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = '', password = '';
  final _auth = FirebaseAuth.instance;
  String error = '';
final GoogleSignIn googleSignIn = GoogleSignIn();

  void login() async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (!mounted) return; // ✅ Verifica que el widget sigue en pantalla
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return; // ✅ También protege el setState
      setState(() {
        error = 'Credenciales inválidas o error de conexión';
      });
    }
  }

  Future<void> loginWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn(); // usa la instancia global
    if (googleUser == null) return; // usuario canceló

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Crear doc en Firestore si es nuevo
    if (userCredential.additionalUserInfo?.isNewUser == true) {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': googleUser.displayName ?? '',
        'email': googleUser.email,
        'avatar': googleUser.photoUrl ?? '',
      });
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al iniciar sesión con Google: $e')),
    );
  }
}
@override
void initState() {
  super.initState();
  // Verifica si hay sesión activa
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Redirige automáticamente al Home si hay usuario activo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }
}

  void _showResetPasswordDialog() {
  final resetEmailController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) {
      bool isLoading = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Recuperar contraseña'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña. Deberás hacer clic en el enlace para completar el proceso.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (isLoading) const CircularProgressIndicator(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final email = resetEmailController.text.trim();
                  if (email.isEmpty || !RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ingresa un correo válido')),
                    );
                    return;
                  }

                  setState(() => isLoading = true);

                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Se envió el enlace de recuperación a $email'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al recuperar la contraseña'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: Text('Enviar enlace'),
              ),
            ],
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9FB),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 33),
                Image.asset('assets/fod.png', height: 142),
                SizedBox(height: 13),
                Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Correo electrónico',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'tu@email.com',
                    prefixIcon: Icon(Icons.mail_outline),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  onChanged: (value) => email = value,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contraseña',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: '********',
                    prefixIcon: Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  onChanged: (value) => password = value,
                  obscureText: true,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: login,
                    child: Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Separador con texto "o"
                const Row(
                  children: [
                    Expanded(
                      child: Divider(color: Color.fromARGB(97, 12, 12, 12)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "O",
                        style: TextStyle(color: Color.fromARGB(179, 5, 5, 5)),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Color.fromARGB(97, 0, 0, 0)),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 16,
                ), // Usar un espacio grande, así queda más abajo
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.login),
                    label: Text('Iniciar sesión con Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: Size.fromHeight(50),
                    ),
                    onPressed: loginWithGoogle,
                  ),
                ),

                if (error.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(error, style: TextStyle(color: Colors.red)),
                  ),
                SizedBox(height: 8),
                Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Flexible(child: Text("¿No tienes cuenta? ")),
    GestureDetector(
                      onTap:
                          () => Navigator.pushReplacementNamed(
                            context,
                            '/register',
                          ),
                      child: Text(
        "Regístrate",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
  onPressed: () {
    _showResetPasswordDialog();
  },
  child: Text("¿Olvidaste tu contraseña?"),
),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

