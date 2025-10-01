import 'package:flutter/material.dart';
import 'reports_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatelessWidget {
  final String? username;
  const AdminDashboard({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF003366)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (username != null && username!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            username!,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined, size: 24),
              title: const Text(
                'Crear usuarios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateUsersPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined, size: 24),
              title: const Text(
                'Actividad de usuarios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserActivityPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment_outlined, size: 24),
              title: const Text(
                'Reportes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.logout, size: 24),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Dashboard de Administrador',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003366),
          ),
        ),
      ),
    );
  }
}

class CreateUsersPage extends StatelessWidget {
  const CreateUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear usuarios')),
      body: const Center(
        child: Text('Pantalla para crear usuarios (pendiente)'),
      ),
    );
  }
}

class UserActivityPage extends StatelessWidget {
  const UserActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actividad de usuarios')),
      body: const Center(
        child: Text('Métricas/actividad de usuarios (pendiente)'),
      ),
    );
  }
}
