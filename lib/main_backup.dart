import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app/config/supabase_client.dart';
import 'base_conexion/conexion_db.dart';

// Arranque por defecto (útil si ejecutas `flutter run` sin --target)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Telmex',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366), // Azul corporativo Telmex
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003366),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MyHomePage(title: 'Inicio de sesión Telmex'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isTestingConnection = false;
  bool _isLoggingIn = false;

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
    });

    try {
      final isConnected = await testSupabaseConnection();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConnected 
                ? '✅ Conexión a Supabase exitosa!' 
                : '❌ Error de conexión a Supabase',
            ),
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }

  Future<void> _login() async {
    final currentState = _formKey.currentState;
    if (currentState == null) return;
    if (!currentState.validate()) return;

    setState(() {
      _isLoggingIn = true;
    });

    try {
      // Login usando Supabase Auth
      final supabase = Supabase.instance.client;
      final user = await supabase
          .from('t_empleados_ld')
          .select()
          .eq('nombre_usuario', _usernameController.text.trim())
          .eq('contrasena', _passwordController.text)
          .inFilter('rol', ['admin', 'normal'])
          .maybeSingle();

      if (user == null) {
        throw 'Credenciales inválidas';
      }

      if (!mounted) return;
      // Notificación breve y navegación según rol
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sesión iniciada correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final String rol = (user['rol']?.toString().toLowerCase() ?? 'usuario');
      if (rol == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(username: _usernameController.text.trim()),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WelcomePage(username: _usernameController.text.trim()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al iniciar sesión: $e'),
            backgroundColor: const Color.fromRGBO(244, 67, 54, 1),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_done),
            onPressed: _isTestingConnection ? null : _testConnection,
            tooltip: 'Probar conexión',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.lock_outline,
                size: 84,
                color: Color(0xFF003366),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ingreso al Sistema',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Ingresa tu usuario';
                        return null;
                      },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value ?? '';
                        if (text.isEmpty) return 'Ingresa tu contraseña';
                  
                        return null;
                      },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoggingIn ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoggingIn
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Iniciar sesión'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isTestingConnection ? null : _testConnection,
                          child: const Text('Probar Conexión Supabase'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  final String? username;
  const WelcomePage({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_done),
            onPressed: () async {
              // Reusar test de conexión desde la pantalla de bienvenida
              final isConnected = await testSupabaseConnection();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isConnected
                        ? '✅ Conexión a Supabase activa'
                        : '❌ Sin conexión a Supabase',
                  ),
                  backgroundColor: isConnected ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Probar conexión',
          ),
        ],
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
                      'Menú',
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
              leading: const Icon(Icons.inventory_2_outlined, size: 24),
              title: const Text(
                'Inventarios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventariosPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined, size: 24),
              title: const Text(
                'Envíos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EnviosPage()),
                );
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.settings_outlined, size: 24),
              title: const Text(
                'Ajustes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              minVerticalPadding: 16,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ajustes (próximamente)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'BIENVENIDO AL SISTEMA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 280,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyHomePage(title: 'Sistema de Inventarios Telmex'),
                    ),
                  );
                },
                icon: const Icon(Icons.logout, size: 24),
                label: const Text(
                  'Volver al login',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventariosPage extends StatelessWidget {
  const InventariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventarios'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipos de Inventarios',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona el tipo de inventario que deseas consultar:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            // Botón de escaneo QR solo en dispositivos móviles
            if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QRScannerPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                  label: const Text(
                    'Escanear Código QR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Ajustar el número de columnas según el ancho disponible
                  int crossAxisCount = 3;
                  if (constraints.maxWidth < 800) crossAxisCount = 2;
                  if (constraints.maxWidth < 600) crossAxisCount = 1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.1,
                    children: [
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.cable,
                        title: 'Jumpers',
                        subtitle: 'Cables de conexión y jumpers',
                        color: Colors.blue,
                        onTap: () => _navigateToInventoryReport(context, 'Jumpers'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.computer,
                        title: 'Computadoras',
                        subtitle: 'Equipos de cómputo y servidores',
                        color: Colors.green,
                        onTap: () => _navigateToInventoryReport(context, 'Computadoras'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.memory,
                        title: 'Tarjetas',
                        subtitle: 'Tarjetas de red y componentes',
                        color: Colors.orange,
                        onTap: () => _navigateToInventoryReport(context, 'Tarjetas'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.router,
                        title: 'Equipos de Red',
                        subtitle: 'Routers, switches y equipos de red',
                        color: Colors.purple,
                        onTap: () => _navigateToInventoryReport(context, 'Equipos de Red'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.phone,
                        title: 'Telefonía',
                        subtitle: 'Equipos telefónicos y centrales',
                        color: Colors.teal,
                        onTap: () => _navigateToInventoryReport(context, 'Telefonía'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.power,
                        title: 'Energía',
                        subtitle: 'UPS, baterías y equipos de energía',
                        color: Colors.red,
                        onTap: () => _navigateToInventoryReport(context, 'Energía'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.storage,
                        title: 'Almacenamiento',
                        subtitle: 'Discos duros y sistemas de almacenamiento',
                        color: Colors.indigo,
                        onTap: () => _navigateToInventoryReport(context, 'Almacenamiento'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.security,
                        title: 'Seguridad',
                        subtitle: 'Equipos de seguridad y monitoreo',
                        color: Colors.brown,
                        onTap: () => _navigateToInventoryReport(context, 'Seguridad'),
                      ),
                      _buildInventoryCategoryCard(
                        context,
                        icon: Icons.build,
                        title: 'Herramientas',
                        subtitle: 'Herramientas y equipos de mantenimiento',
                        color: Colors.grey,
                        onTap: () => _navigateToInventoryReport(context, 'Herramientas'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToInventoryReport(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryReportPage(category: category),
      ),
    );
  }
}

class InventoryReportPage extends StatelessWidget {
  final String category;
  
  const InventoryReportPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte - $category'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 32,
                  color: _getCategoryColor(category),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventario de $category',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      Text(
                        'Consulta y reportes del inventario actual',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Botón de escaneo QR solo en dispositivos móviles
            if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QRScannerPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: Text(
                    'Escanear QR - $category',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCategoryColor(category),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth < 600) crossAxisCount = 1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.3,
                    children: [
                      _buildReportOptionCard(
                        context,
                        icon: Icons.visibility,
                        title: 'Vista General',
                        subtitle: 'Ver inventario completo',
                        color: Colors.blue,
                        onTap: () => _showInventoryData(context, 'Vista General'),
                      ),
                      _buildReportOptionCard(
                        context,
                        icon: Icons.search,
                        title: 'Buscar Items',
                        subtitle: 'Buscar elementos específicos',
                        color: Colors.green,
                        onTap: () => _showInventoryData(context, 'Buscar Items'),
                      ),
                      _buildReportOptionCard(
                        context,
                        icon: Icons.analytics,
                        title: 'Estadísticas',
                        subtitle: 'Métricas y análisis',
                        color: Colors.orange,
                        onTap: () => _showInventoryData(context, 'Estadísticas'),
                      ),
                      _buildReportOptionCard(
                        context,
                        icon: Icons.file_download,
                        title: 'Exportar',
                        subtitle: 'Descargar reporte',
                        color: Colors.purple,
                        onTap: () => _showInventoryData(context, 'Exportar'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Jumpers':
        return Icons.cable;
      case 'Computadoras':
        return Icons.computer;
      case 'Tarjetas':
        return Icons.memory;
      case 'Equipos de Red':
        return Icons.router;
      case 'Telefonía':
        return Icons.phone;
      case 'Energía':
        return Icons.power;
      case 'Almacenamiento':
        return Icons.storage;
      case 'Seguridad':
        return Icons.security;
      case 'Herramientas':
        return Icons.build;
      default:
        return Icons.inventory_2;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Jumpers':
        return Colors.blue;
      case 'Computadoras':
        return Colors.green;
      case 'Tarjetas':
        return Colors.orange;
      case 'Equipos de Red':
        return Colors.purple;
      case 'Telefonía':
        return Colors.teal;
      case 'Energía':
        return Colors.red;
      case 'Almacenamiento':
        return Colors.indigo;
      case 'Seguridad':
        return Colors.brown;
      case 'Herramientas':
        return Colors.grey;
      default:
        return const Color(0xFF003366);
    }
  }

  void _showInventoryData(BuildContext context, String option) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '$option - $category',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 64,
                  color: _getCategoryColor(category),
                ),
                const SizedBox(height: 16),
                Text(
                  'Categoría: $category',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Opción seleccionada: $option',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta funcionalidad estará disponible próximamente. Aquí se mostrarán los datos específicos del inventario seleccionado.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cerrar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  String? scannedCode;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesita permiso de cámara para escanear códigos QR'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && isScanning) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          scannedCode = code;
          isScanning = false;
        });
        _handleScannedCode(code);
      }
    }
  }

  void _handleScannedCode(String code) {
    // Mostrar el código escaneado y opciones
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Código QR Escaneado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 64,
                  color: Color(0xFF003366),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Código detectado:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Qué deseas hacer con este código?',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  isScanning = true;
                  scannedCode = null;
                });
              },
              child: const Text('Escanear Otro'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _searchProductByQR(code);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
              ),
              child: const Text('Buscar Producto'),
            ),
          ],
        );
      },
    );
  }

  void _searchProductByQR(String qrCode) {
    // Aquí se implementaría la búsqueda en la base de datos
    // Por ahora mostramos un mensaje informativo
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Búsqueda de Producto',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Buscando producto con código:',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    qrCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta funcionalidad estará disponible próximamente. Aquí se mostrarán los detalles del producto encontrado.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Volver a la pantalla anterior
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código QR'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 32,
                    color: Color(0xFF003366),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Apunta la cámara al código QR del producto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF003366),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isScanning ? 'Escaneando...' : 'Código detectado',
                    style: TextStyle(
                      fontSize: 14,
                      color: isScanning ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: const Color(0xFF003366),
        child: const Icon(Icons.close, color: Colors.white),
      ),
    );
  }
}

class EnviosPage extends StatelessWidget {
  const EnviosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envíos'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Módulo de Envíos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestiona y consulta información sobre envíos:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth < 600) crossAxisCount = 1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.2,
                    children: [
                      _buildEnvioOptionCard(
                        context,
                        icon: Icons.local_shipping,
                        title: 'Rastrear Envío',
                        subtitle: 'Consulta el estado de tus envíos',
                        color: Colors.blue,
                        onTap: () => _navigateToTrackShipment(context),
                      ),
                      _buildEnvioOptionCard(
                        context,
                        icon: Icons.assessment,
                        title: 'Reportes de Envíos',
                        subtitle: 'Genera reportes y estadísticas',
                        color: Colors.green,
                        onTap: () => _navigateToShipmentReports(context),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvioOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTrackShipment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrackShipmentPage(),
      ),
    );
  }

  void _navigateToShipmentReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShipmentReportsPage(),
      ),
    );
  }
}

class TrackShipmentPage extends StatefulWidget {
  const TrackShipmentPage({super.key});

  @override
  State<TrackShipmentPage> createState() => _TrackShipmentPageState();
}

class _TrackShipmentPageState extends State<TrackShipmentPage> {
  final TextEditingController _trackingController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _shipmentData;

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _searchShipment() async {
    if (_trackingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un número de seguimiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simular búsqueda (aquí se conectaría con la API real)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSearching = false;
      _shipmentData = {
        'trackingNumber': _trackingController.text.trim(),
        'status': 'En tránsito',
        'origin': 'Centro de Distribución CDMX',
        'destination': 'Oficina Telmex Guadalajara',
        'estimatedDelivery': '2024-01-15',
        'currentLocation': 'Centro de Distribución Querétaro',
        'history': [
          {'date': '2024-01-10', 'time': '08:30', 'status': 'Recolectado', 'location': 'Centro de Distribución CDMX'},
          {'date': '2024-01-11', 'time': '14:20', 'status': 'En tránsito', 'location': 'Centro de Distribución Querétaro'},
          {'date': '2024-01-12', 'time': '09:15', 'status': 'En tránsito', 'location': 'Centro de Distribución Querétaro'},
        ],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastrear Envío'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consulta el Estado de tu Envío',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa el número de seguimiento para consultar el estado:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trackingController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Seguimiento',
                      hintText: 'Ej: TLMX123456789',
                      prefixIcon: Icon(Icons.local_shipping),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchShipment(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchShipment,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? 'Buscando...' : 'Buscar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _shipmentData != null
                  ? _buildShipmentDetails()
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ingresa un número de seguimiento',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'para consultar el estado de tu envío',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información principal del envío
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, color: Color(0xFF003366)),
                      const SizedBox(width: 8),
                      Text(
                        'Envío #${_shipmentData!['trackingNumber']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Estado:', _shipmentData!['status'], Colors.blue),
                  _buildInfoRow('Origen:', _shipmentData!['origin'], Colors.grey[600]!),
                  _buildInfoRow('Destino:', _shipmentData!['destination'], Colors.grey[600]!),
                  _buildInfoRow('Entrega estimada:', _shipmentData!['estimatedDelivery'], Colors.green),
                  _buildInfoRow('Ubicación actual:', _shipmentData!['currentLocation'], Colors.orange),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Historial del envío
          const Text(
            'Historial de Seguimiento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 12),
          ...(_shipmentData!['history'] as List).map((event) => _buildHistoryItem(event)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF003366),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['status'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    event['location'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${event['date']} - ${event['time']}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShipmentReportsPage extends StatelessWidget {
  const ShipmentReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Envíos'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportes y Estadísticas de Envíos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Genera reportes detallados sobre el estado de los envíos:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth < 800) crossAxisCount = 2;
                  if (constraints.maxWidth < 600) crossAxisCount = 1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.2,
                    children: [
                      _buildReportCard(
                        context,
                        icon: Icons.timeline,
                        title: 'Estado de Envíos',
                        subtitle: 'Resumen por estado actual',
                        color: Colors.blue,
                        onTap: () => _showReportDialog(context, 'Estado de Envíos'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.location_on,
                        title: 'Envíos por Ubicación',
                        subtitle: 'Distribución geográfica',
                        color: Colors.green,
                        onTap: () => _showReportDialog(context, 'Envíos por Ubicación'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.schedule,
                        title: 'Tiempos de Entrega',
                        subtitle: 'Análisis de tiempos promedio',
                        color: Colors.orange,
                        onTap: () => _showReportDialog(context, 'Tiempos de Entrega'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.trending_up,
                        title: 'Tendencias',
                        subtitle: 'Análisis de tendencias mensuales',
                        color: Colors.purple,
                        onTap: () => _showReportDialog(context, 'Tendencias'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.warning,
                        title: 'Envíos Retrasados',
                        subtitle: 'Lista de envíos con retrasos',
                        color: Colors.red,
                        onTap: () => _showReportDialog(context, 'Envíos Retrasados'),
                      ),
                      _buildReportCard(
                        context,
                        icon: Icons.file_download,
                        title: 'Exportar Datos',
                        subtitle: 'Descargar reportes en Excel/PDF',
                        color: Colors.teal,
                        onTap: () => _showReportDialog(context, 'Exportar Datos'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, String reportType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reporte: $reportType',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getReportIcon(reportType),
                  size: 64,
                  color: _getReportColor(reportType),
                ),
                const SizedBox(height: 16),
                Text(
                  'Generando reporte de $reportType',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta funcionalidad estará disponible próximamente. Aquí se mostrarán los datos específicos del reporte seleccionado.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildSampleData(reportType),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _generateReport(context, reportType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
              ),
              child: const Text('Generar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSampleData(String reportType) {
    switch (reportType) {
      case 'Estado de Envíos':
        return Column(
          children: [
            _buildDataRow('En tránsito', '45', Colors.blue),
            _buildDataRow('Entregado', '32', Colors.green),
            _buildDataRow('Retrasado', '8', Colors.red),
            _buildDataRow('Pendiente', '15', Colors.orange),
          ],
        );
      case 'Envíos por Ubicación':
        return Column(
          children: [
            _buildDataRow('CDMX', '28', Colors.blue),
            _buildDataRow('Guadalajara', '22', Colors.green),
            _buildDataRow('Monterrey', '18', Colors.orange),
            _buildDataRow('Puebla', '12', Colors.purple),
          ],
        );
      default:
        return const Text('Datos de muestra disponibles próximamente');
    }
  }

  Widget _buildDataRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getReportIcon(String reportType) {
    switch (reportType) {
      case 'Estado de Envíos':
        return Icons.timeline;
      case 'Envíos por Ubicación':
        return Icons.location_on;
      case 'Tiempos de Entrega':
        return Icons.schedule;
      case 'Tendencias':
        return Icons.trending_up;
      case 'Envíos Retrasados':
        return Icons.warning;
      case 'Exportar Datos':
        return Icons.file_download;
      default:
        return Icons.assessment;
    }
  }

  Color _getReportColor(String reportType) {
    switch (reportType) {
      case 'Estado de Envíos':
        return Colors.blue;
      case 'Envíos por Ubicación':
        return Colors.green;
      case 'Tiempos de Entrega':
        return Colors.orange;
      case 'Tendencias':
        return Colors.purple;
      case 'Envíos Retrasados':
        return Colors.red;
      case 'Exportar Datos':
        return Colors.teal;
      default:
        return const Color(0xFF003366);
    }
  }

  void _generateReport(BuildContext context, String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generando reporte de $reportType...'),
        backgroundColor: const Color(0xFF003366),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

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
                  MaterialPageRoute(builder: (_) => const CrearUsuariosPage()),
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
                  MaterialPageRoute(builder: (_) => const ActividadUsuariosPage()),
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
                  MaterialPageRoute(builder: (_) => const ReportesPage()),
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
                  MaterialPageRoute(builder: (_) => const MyHomePage(title: 'Sistema de Inventarios Telmex')),
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

class CrearUsuariosPage extends StatelessWidget {
  const CrearUsuariosPage({super.key});

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

class ActividadUsuariosPage extends StatelessWidget {
  const ActividadUsuariosPage({super.key});

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

class ReportesPage extends StatelessWidget {
  const ReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Módulo de Reportes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Ajustar el número de columnas según el ancho disponible
                  int crossAxisCount = 3;
                  if (constraints.maxWidth < 800) crossAxisCount = 2;
                  if (constraints.maxWidth < 600) crossAxisCount = 1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.2, // Hacer las tarjetas menos altas
                    children: [
                  _buildReportCard(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: 'Reporte de Inventarios',
                    subtitle: 'Estado actual del inventario',
                    color: Colors.blue,
                    onTap: () => _showReportDialog(context, 'Inventarios'),
                  ),
                  _buildReportCard(
                    context,
                    icon: Icons.local_shipping_outlined,
                    title: 'Reporte de Envíos',
                    subtitle: 'Seguimiento de envíos',
                    color: Colors.green,
                    onTap: () => _showReportDialog(context, 'Envíos'),
                  ),
                  _buildReportCard(
                    context,
                    icon: Icons.people_outline,
                    title: 'Reporte de Usuarios',
                    subtitle: 'Actividad de usuarios',
                    color: Colors.orange,
                    onTap: () => _showReportDialog(context, 'Usuarios'),
                  ),
                  _buildReportCard(
                    context,
                    icon: Icons.trending_up_outlined,
                    title: 'Reporte de Estadísticas',
                    subtitle: 'Métricas generales',
                    color: Colors.purple,
                    onTap: () => _showReportDialog(context, 'Estadísticas'),
                  ),
                  _buildReportCard(
                    context,
                    icon: Icons.file_download_outlined,
                    title: 'Exportar Datos',
                    subtitle: 'Exportar a Excel/PDF',
                    color: Colors.red,
                    onTap: () => _showReportDialog(context, 'Exportar'),
                  ),
                  _buildReportCard(
                    context,
                    icon: Icons.schedule_outlined,
                    title: 'Reportes Programados',
                    subtitle: 'Configurar reportes automáticos',
                    color: Colors.teal,
                    onTap: () => _showReportDialog(context, 'Programados'),
                  ),
                ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40, // Iconos más grandes
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18, // Texto más grande
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14, // Subtítulo más grande
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, String reportType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reporte de $reportType',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400, // Ancho fijo para escritorio
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¿Qué tipo de reporte deseas generar?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _generateReport(context, reportType, 'Vista Previa');
                    },
                    icon: const Icon(Icons.visibility, size: 20),
                    label: const Text('Vista Previa', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _generateReport(context, reportType, 'PDF');
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 20),
                    label: const Text('Exportar PDF', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _generateReport(context, reportType, 'Excel');
                    },
                    icon: const Icon(Icons.table_chart, size: 20),
                    label: const Text('Exportar Excel', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _generateReport(BuildContext context, String reportType, String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generando reporte de $reportType en formato $format...'),
        backgroundColor: const Color(0xFF003366),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Aquí iría la lógica real para generar el reporte
    // Por ahora solo mostramos un mensaje
  }
}
