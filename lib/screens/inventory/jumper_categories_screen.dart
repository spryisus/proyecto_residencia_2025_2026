import 'package:flutter/material.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../../core/di/injection_container.dart';
import '../../app/config/supabase_client.dart' show supabaseClient;
import 'package:shared_preferences/shared_preferences.dart';
import 'category_inventory_screen.dart' show CategoryInventoryScreen;

class JumperCategory {
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;
  final String searchPattern; // Patrón para buscar en nombre/descripción

  const JumperCategory({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
    required this.searchPattern,
  });
}

// Definir las categorías de jumpers (accesible desde otras pantallas)
class JumperCategories {
  static const List<JumperCategory> all = [
    JumperCategory(
      name: 'FC-FC',
      displayName: 'FC-FC',
      icon: Icons.cable,
      color: Colors.blue,
      searchPattern: 'FC-FC|FC/FC|FC FC',
    ),
    JumperCategory(
      name: 'LC-FC',
      displayName: 'LC-FC',
      icon: Icons.cable,
      color: Colors.green,
      searchPattern: 'LC-FC|LC/FC|LC FC',
    ),
    JumperCategory(
      name: 'LC-LC',
      displayName: 'LC-LC',
      icon: Icons.cable,
      color: Colors.orange,
      searchPattern: 'LC-LC|LC/LC|LC LC',
    ),
    JumperCategory(
      name: 'SC-FC',
      displayName: 'SC-FC',
      icon: Icons.cable,
      color: Colors.purple,
      searchPattern: 'SC-FC|SC/FC|SC FC',
    ),
    JumperCategory(
      name: 'SC-LC',
      displayName: 'SC-LC',
      icon: Icons.cable,
      color: Colors.red,
      searchPattern: 'SC-LC|SC/LC|SC LC',
    ),
    JumperCategory(
      name: 'SC-SC',
      displayName: 'SC-SC',
      icon: Icons.cable,
      color: Colors.teal,
      searchPattern: 'SC-SC|SC/SC|SC SC',
    ),
  ];
}

class JumperCategoriesScreen extends StatefulWidget {
  final Categoria categoria;
  final String categoriaNombre;
  final String? sessionId;

  const JumperCategoriesScreen({
    super.key,
    required this.categoria,
    required this.categoriaNombre,
    this.sessionId,
  });

  @override
  State<JumperCategoriesScreen> createState() => _JumperCategoriesScreenState();
}

class _JumperCategoriesScreenState extends State<JumperCategoriesScreen> {
  final InventarioRepository _inventarioRepository = serviceLocator.get<InventarioRepository>();
  Map<String, int> _categoryCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryCounts();
  }

  Future<void> _loadCategoryCounts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Obtener todos los productos de jumpers
      final inventario = await _inventarioRepository.getInventarioByCategoria(widget.categoria.idCategoria);
      
      // Contar productos por categoría de conector
      final counts = <String, int>{};
      
      for (final category in JumperCategories.all) {
        // Contar productos que coinciden con el patrón
        final count = inventario.where((item) {
          final nombre = item.producto.nombre.toUpperCase();
          final descripcion = (item.producto.descripcion ?? '').toUpperCase();
          final texto = '$nombre $descripcion';
          return _matchesPattern(texto, category.searchPattern);
        }).length;
        
        counts[category.name] = count;
      }

      if (mounted) {
        setState(() {
          _categoryCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error al cargar conteos de categorías: $e');
    }
  }

  bool _matchesPattern(String text, String pattern) {
    if (pattern.isEmpty) return false;
    final patterns = pattern.split('|');
    return patterns.any((p) => text.contains(p.trim()));
  }

  Future<bool> _checkIsAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idEmpleado = prefs.getString('id_empleado');
      
      if (idEmpleado == null) {
        return false;
      }
      
      final roles = await supabaseClient
          .from('t_empleado_rol')
          .select('t_roles!inner(nombre)')
          .eq('id_empleado', idEmpleado);
      
      final isAdmin = roles.any((rol) => 
          rol['t_roles']['nombre']?.toString().toLowerCase() == 'admin');
      
      return isAdmin;
    } catch (e) {
      debugPrint('Error al verificar rol de admin: $e');
      return false;
    }
  }

  Future<void> _navigateToCategory(JumperCategory category) async {
    try {
      // Verificar si el usuario es admin
      final isAdmin = await _checkIsAdmin();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryInventoryScreen(
            categoria: widget.categoria,
            categoriaNombre: widget.categoriaNombre,
            sessionId: widget.sessionId,
            isAdmin: isAdmin,
            jumperCategoryFilter: category,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar categoría: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categorías de ${widget.categoriaNombre}'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, outerConstraints) {
                final isMobile = outerConstraints.maxWidth < 600;
                final padding = isMobile ? 12.0 : 20.0;
                
                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecciona el tipo de conector',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elige la categoría de jumper que deseas ver',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Responsive: Ajustar columnas según el tamaño de pantalla
                            int crossAxisCount = 2;
                            double childAspectRatio = 1.4;
                            
                            if (constraints.maxWidth < 600) {
                              // Móvil: 1 columna
                              crossAxisCount = 1;
                              childAspectRatio = 2.0;
                            } else if (constraints.maxWidth < 900) {
                              // Tablet: 2 columnas
                              crossAxisCount = 2;
                              childAspectRatio = 1.4;
                            } else {
                              // Desktop: 3 o más columnas
                              crossAxisCount = constraints.maxWidth < 1200 ? 3 : 4;
                              childAspectRatio = 1.3;
                            }
                        
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: JumperCategories.all.length,
                          itemBuilder: (context, index) {
                            final category = JumperCategories.all[index];
                            final count = _categoryCounts[category.name] ?? 0;
                            
                            // Solo mostrar categorías que tengan productos
                            if (count == 0) {
                              return const SizedBox.shrink();
                            }
                            
                            return _buildCategoryCard(category, count);
                          },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCategoryCard(JumperCategory category, int count) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCategory(category),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                category.color.withValues(alpha: 0.2),
                category.color.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  size: 40,
                  color: category.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                category.displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: count > 0 
                    ? Colors.green[100]
                    : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count ${count == 1 ? 'prod.' : 'prod.'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: count > 0 
                      ? Colors.green[700]
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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

