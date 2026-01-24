import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      titleSpacing: 16,
      title: Row(
        children: [
          const Icon(Icons.eco, color: Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          const Text(
            'SaneApp',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.black54),
          onPressed: () {
            // Navegar a perfil
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeText(),
          const SizedBox(height: 24),
          _quickActions(),
          const SizedBox(height: 32),
          _howItWorks(),
          const SizedBox(height: 32),
          _featuredServices(),
        ],
      ),
    );
  }

  Widget _welcomeText() {
    return const Text(
      'Conectando contigo soluciones ambientales responsables',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        _actionCard(
          icon: Icons.add_circle_outline,
          title: 'Solicitar\nServicio',
          onTap: () {
            Navigator.pushNamed(context, '/register'); // Ejemplo: pantalla de registro de solicitud
          },
        ),
        const SizedBox(width: 12),
        _actionCard(
          icon: Icons.search,
          title: 'Explorar\nServicios',
          onTap: () {
            // Aquí podrías navegar a una pantalla de exploración de servicios
            // Navigator.pushNamed(context, '/explore');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Funcionalidad próximamente')),
            );
          },
        ),
        const SizedBox(width: 12),
        _actionCard(
          icon: Icons.assignment_outlined,
          title: 'Mis\nSolicitudes',
          onTap: () {
            // Aquí podrías navegar a una pantalla de historial de solicitudes
            // Navigator.pushNamed(context, '/requests');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Funcionalidad próximamente')),
            );
          },
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: const Color(0xFF2E7D32)),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _howItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          '¿Cómo funciona SaneApp?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '1. Solicita un servicio ambiental\n'
          '2. Conectamos con empresas certificadas\n'
          '3. Recibe soluciones confiables y sostenibles',
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
      ],
    );
  }

  Widget _featuredServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Servicios destacados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _serviceTile(
          icon: Icons.delete_outline,
          title: 'Gestión de residuos',
          subtitle: 'Recolección y disposición responsable',
        ),
        _serviceTile(
          icon: Icons.oil_barrel_outlined,
          title: 'Aceite usado',
          subtitle: 'Recolección y manejo certificado',
        ),
        _serviceTile(
          icon: Icons.cleaning_services_outlined,
          title: 'Limpieza industrial',
          subtitle: 'Servicios especializados',
        ),
      ],
    );
  }

  Widget _serviceTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2E7D32)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Aquí podrías navegar a la pantalla de detalle del servicio
          // Navigator.pushNamed(context, '/service_detail', arguments: title);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Detalle de $title próximamente')),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: const Color(0xFF2E7D32),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() => _currentIndex = index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          label: 'Servicios',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          label: 'Solicitudes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
