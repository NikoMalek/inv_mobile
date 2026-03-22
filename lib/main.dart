import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: ApiClient.defaultEmail);
  final _passwordController = TextEditingController(
    text: ApiClient.defaultPassword,
  );
  final _api = ApiClient();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(api: _api),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Inventario')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Acceso rapido con credenciales fijas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.api});

  final ApiClient api;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      InventoryPage(api: widget.api),
      NewProductPage(api: widget.api),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de Inventario'),
        actions: [
          IconButton(
            onPressed: () {
              widget.api.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',
          ),
        ],
      ),
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _tabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Nuevo',
          ),
        ],
      ),
    );
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _loading = true;
  String? _error;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final products = await widget.api.getInventory();
      if (!mounted) return;

      setState(() {
        _products = products;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _editProduct(Product product) async {
    final nombreController = TextEditingController(text: product.nombre);
    final descripcionController = TextEditingController(text: product.description);
    final precioController = TextEditingController(text: product.precio.toString());
    final cantidadController = TextEditingController(text: product.cantidad.toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: 'Descripcion'),
              ),
              TextField(
                controller: precioController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Precio'),
              ),
              TextField(
                controller: cantidadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved != true) {
      nombreController.dispose();
      descripcionController.dispose();
      precioController.dispose();
      cantidadController.dispose();
      return;
    }

    try {
      await widget.api.createOrUpdateProduct(
        nombre: nombreController.text.trim(),
        description: descripcionController.text.trim(),
        codigoBarras: product.codigoBarras,
        precio: double.tryParse(precioController.text) ?? product.precio,
        cantidad: int.tryParse(cantidadController.text) ?? product.cantidad,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto guardado')),
      );
      _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      nombreController.dispose();
      descripcionController.dispose();
      precioController.dispose();
      cantidadController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadProducts,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No hay productos')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.separated(
        itemCount: _products.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            title: Text(product.nombre),
            leading: product.imagen.isNotEmpty
                ? Image.network(
                    product.imagen,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                  )
                : const Icon(Icons.inventory_2_outlined, size: 48),
            subtitle: Text(
              'Codigo: ${product.codigoBarras} | Precio: ${product.precio} | Cantidad: ${product.cantidad}',
            ),
            trailing: IconButton(
              onPressed: () => _editProduct(product),
              icon: const Icon(Icons.edit),
            ),
          );
        },
      ),
    );
  }
}

class NewProductPage extends StatefulWidget {
  const NewProductPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<NewProductPage> createState() => _NewProductPageState();
}

class _NewProductPageState extends State<NewProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _codigoController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _codigoController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.api.createOrUpdateProduct(
        nombre: _nombreController.text.trim(),
        description: _descripcionController.text.trim(),
        codigoBarras: _codigoController.text.trim(),
        precio: double.parse(_precioController.text),
        cantidad: int.parse(_cantidadController.text),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto registrado')),
      );
      _formKey.currentState!.reset();
      _nombreController.clear();
      _descripcionController.clear();
      _codigoController.clear();
      _precioController.clear();
      _cantidadController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nombre requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripcion',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codigoController,
              decoration: const InputDecoration(
                labelText: 'Codigo de barras',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Codigo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _precioController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio',
                border: OutlineInputBorder(),
              ),
              validator: (v) => double.tryParse(v ?? '') == null
                  ? 'Precio invalido'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              validator: (v) => int.tryParse(v ?? '') == null
                  ? 'Cantidad invalida'
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Guardando...' : 'Registrar producto'),
            ),
          ],
        ),
      ),
    );
  }
}

class Product {
  Product({
    required this.nombre,
    required this.description,
    required this.codigoBarras,
    required this.precio,
    required this.cantidad,
    required this.imagen,
  });

  final String nombre;
  final String description;
  final String codigoBarras;
  final double precio;
  final int cantidad;
  final String imagen;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      nombre: (json['nombre'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      codigoBarras: (json['codigoBarras'] ?? json['codigo_barra'] ?? '').toString(),
      precio: _toDouble(json['precio']),
      cantidad: _toInt(json['cantidad']),
      imagen: (json['imagen'] ?? '').toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ApiClient {

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000'
  );

  String? _cookie;
  int? _idEmpresa;

  Future<void> login({required String email, required String password}) async {

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Fallo login backend: ${response.body}');
    }

    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) {
      throw Exception('No llego cookie de sesion');
    }

    _cookie = setCookie.split(';').first;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final user = body['user'];
    if (user is Map<String, dynamic>) {
      final idEmpresa = user['id_empresa'] ?? user['idEmpresa'];
      if (idEmpresa != null) {
        _idEmpresa = int.tryParse(idEmpresa.toString());
      }
    }
  }

  Future<List<Product>> getInventory() async {
    _ensureSession();

    final response = await http.get(
      Uri.parse('$baseUrl/inventario'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': _cookie!,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo cargar inventario: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<void> createOrUpdateProduct({
    required String nombre,
    required String description,
    required String codigoBarras,
    required double precio,
    required int cantidad,
  }) async {
    _ensureSession();

    final payload = {
      'nombre': nombre,
      'description': description,
      'imagen': '',
      'codigoBarras': codigoBarras,
      'id_empresa': _idEmpresa,
      'precio': precio,
      'cantidad': cantidad,
      'ultima_actualizacion': DateTime.now().toIso8601String(),
      'id_reponedor': 0,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/productos'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': _cookie!,
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo guardar producto: ${response.body}');
    }
  }

  void logout() {
    _cookie = null;
    _idEmpresa = null;
  }

  void _ensureSession() {
    if (_cookie == null || _cookie!.isEmpty) {
      throw Exception('Sesion no iniciada');
    }
  }
}
