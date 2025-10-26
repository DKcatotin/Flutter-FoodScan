import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool darkMode = false;

  ThemeData get theme =>
      darkMode
          ? ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            cardColor: Color(0xFF232326),
            dialogTheme: DialogThemeData(backgroundColor: Color(0xFF232326)),
            primaryColor: Colors.white,
          )
          : ThemeData.light().copyWith(
            scaffoldBackgroundColor: Color(0xFFF9F9FB),
            cardColor: Colors.white,
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
            primaryColor: Colors.black,
          );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: darkMode ? Colors.black : Color(0xFFF9F9FB),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: darkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {},
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.person,
                color: darkMode ? Colors.white : Colors.black,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            Switch(
              value: darkMode,
              onChanged: (v) => setState(() => darkMode = v),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              children: [
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: darkMode ? Colors.grey[900] : Colors.black,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'FoodScan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: darkMode ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: Text(
                      'Escanear producto',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      // Navega al scan_screen
                      Navigator.pushNamed(context, '/scan');
                    },
                  ),
                ),
                SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: Icon(Icons.history),
                    label: Text(
                      'Ver historial',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/history');
                    },
                  ),
                ),
                SizedBox(height: 22),
                Card(
                  margin: EdgeInsets.only(bottom: 18),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aprende sobre nutrición',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Escanea el código de barras de cualquier producto alimenticio para conocer su información nutricional de manera clara y visual.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 16),
                            Icon(Icons.circle, color: Colors.orange, size: 16),
                            Icon(Icons.circle, color: Colors.red, size: 16),
                          ],
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Semáforo nutricional',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Identifica fácilmente qué nutrientes están en niveles saludables, moderados o altos con nuestro sistema de colores intuitivo.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
