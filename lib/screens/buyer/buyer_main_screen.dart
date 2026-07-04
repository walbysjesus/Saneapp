import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/role_guard.dart';
import '../../features/generador/mis_solicitudes_page.dart';
import '../../features/generador/ofertas_recibidas_page.dart';
import '../../features/home/explore_services_page.dart';
import '../../state/app_state.dart';

class BuyerMainScreen extends StatefulWidget {
  const BuyerMainScreen({super.key});

  @override
  State<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends State<BuyerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExploreServicesPage(),
    MisSolicitudesPage(),
    _MarketplaceCommercialHubPage(),
    OfertasRecibidasPage(),
    _BuyerMorePage(),
  ];

  static const List<_BuyerNavItem> _navItems = [
    _BuyerNavItem(
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      label: 'Market-\nplace',
    ),
    _BuyerNavItem(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      label: 'Necesi-\ndades',
    ),
    _BuyerNavItem(
      icon: Icons.hub_outlined,
      selectedIcon: Icons.hub,
      label: 'Flujo\ncomercial',
    ),
    _BuyerNavItem(
      icon: Icons.request_quote_outlined,
      selectedIcon: Icons.request_quote,
      label: 'Ofertas',
    ),
    _BuyerNavItem(
      icon: Icons.more_horiz,
      selectedIcon: Icons.more_horiz,
      label: 'Más',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: UserRole.generador,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _BuyerBottomBar(
          currentIndex: _currentIndex,
          items: _navItems,
          onSelected: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}

class _BuyerBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_BuyerNavItem> items;
  final ValueChanged<int> onSelected;

  const _BuyerBottomBar({
    required this.currentIndex,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE5EBE7))),
          ),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _BuyerBottomBarButton(
                    item: items[index],
                    selected: index == currentIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyerBottomBarButton extends StatelessWidget {
  final _BuyerNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _BuyerBottomBarButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF1E7A4B);
    const unselectedColor = Color(0xFF6E7D74);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF6EF) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                color: selected ? selectedColor : unselectedColor,
                size: 22,
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 28,
                child: Center(
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.1,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? selectedColor : unselectedColor,
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

class _MarketplaceCommercialHubPage extends StatelessWidget {
  const _MarketplaceCommercialHubPage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Flujo comercial'),
        backgroundColor: const Color(0xFF0C4F31),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A3423), Color(0xFF1E7A4B)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Un solo frente para comprar servicios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Desde aquí eliges si el negocio entra por solicitud directa, cotización asistida o subasta. Los tres caminos hacen parte del mismo flujo comercial de SaneApp.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('solicitudes')
                .where('generadorId', isEqualTo: user.uid)
                .get(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? const [];
              final directCount = docs.where((doc) {
                final data = doc.data();
                return (data['requestSource']?.toString() ?? '') ==
                    'service_marketplace';
              }).length;
              final auctionCount = docs.where((doc) {
                final data = doc.data();
                return (data['type']?.toString() ?? '') == 'subasta';
              }).length;
              final supervisedCount = docs.where((doc) {
                final data = doc.data();
                return data['supervisorRequested'] == true;
              }).length;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _FlowMetricCard(
                    label: 'Directas',
                    value: '$directCount',
                    hint: 'Contratación desde vitrina',
                  ),
                  _FlowMetricCard(
                    label: 'Subastas',
                    value: '$auctionCount',
                    hint: 'Competencia por alcance',
                  ),
                  _FlowMetricCard(
                    label: 'Asistidas',
                    value: '$supervisedCount',
                    hint: 'Con visita o supervisor',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _CommercialFlowCard(
            title: 'Solicitud directa',
            subtitle:
                'Úsala cuando ya viste un servicio en la vitrina y quieres avanzar rápido con una necesidad concreta.',
            icon: Icons.assignment_turned_in_outlined,
            accent: const Color(0xFF0C4F31),
            cta: 'Crear solicitud',
            onTap: () => Navigator.pushNamed(
              context,
              '/crear_solicitud',
              arguments: const {
                'requestSource': 'service_marketplace',
                'commercialFlowMode': 'direct_request',
              },
            ),
          ),
          const SizedBox(height: 12),
          _CommercialFlowCard(
            title: 'Cotización asistida',
            subtitle:
                'Ideal cuando necesitas visita previa, validación técnica o acompañamiento de SaneApp antes de recibir precios.',
            icon: Icons.verified_user_outlined,
            accent: const Color(0xFF1E7A4B),
            cta: 'Solicitar cotización asistida',
            onTap: () => Navigator.pushNamed(
              context,
              '/crear_solicitud',
              arguments: const {
                'requestSource': 'service_marketplace',
                'commercialFlowMode': 'assisted_quote',
                'supervisorRequested': true,
              },
            ),
          ),
          const SizedBox(height: 12),
          _CommercialFlowCard(
            title: 'Subasta de proveedores',
            subtitle:
                'Ábrela cuando el alcance sea grande, quieras competir varias propuestas o comparar proveedores bajo fecha límite.',
            icon: Icons.gavel_outlined,
            accent: const Color(0xFF8A6200),
            cta: 'Crear subasta',
            onTap: () => Navigator.pushNamed(
              context,
              '/crear_subasta',
              arguments: const {
                'requestSource': 'service_marketplace',
                'commercialFlowMode': 'auction',
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _FlowMetricCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 158,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E9E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(color: Color(0xFF6E7D74))),
        ],
      ),
    );
  }
}

class _CommercialFlowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String cta;
  final VoidCallback onTap;

  const _CommercialFlowCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1E9E3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF66746C),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(cta),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyerMorePage extends StatelessWidget {
  const _BuyerMorePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Más'),
        backgroundColor: const Color(0xFF0C4F31),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: const [
          _MoreEntry(
            icon: Icons.payments_outlined,
            title: 'Pagos',
            subtitle: 'Consulta pagos y liberaciones del flujo comercial.',
            route: '/pagos_generador',
          ),
          _MoreEntry(
            icon: Icons.verified_user_outlined,
            title: 'Supervisión',
            subtitle: 'Revisa solicitudes con acompañamiento o soporte técnico.',
            route: '/supervision_generador',
          ),
          _MoreEntry(
            icon: Icons.history_outlined,
            title: 'Historial',
            subtitle: 'Consulta negocios previos y trazabilidad del comprador.',
            route: '/historial_generador',
          ),
          _MoreEntry(
            icon: Icons.person_outline,
            title: 'Perfil',
            subtitle: 'Actualiza datos corporativos y configuración de compra.',
            route: '/perfil_generador',
          ),
        ],
      ),
    );
  }
}

class _MoreEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _MoreEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: Colors.white,
        leading: Icon(icon, color: const Color(0xFF1E7A4B)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}

class _BuyerNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _BuyerNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}