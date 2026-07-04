import 'package:flutter/material.dart';
import '../../features/home/explore_services_page.dart';
import 'provider_home_screen.dart';
import '../../features/provider/provider_my_services_page.dart';
import '../../features/provider/servicios_en_curso_page.dart';
import '../../features/provider/perfil_proveedor_page.dart';
import '../../core/widgets/role_guard.dart';
import '../../state/app_state.dart';

class ProviderMainScreen extends StatefulWidget {
  const ProviderMainScreen({super.key});

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ProviderHomeScreen(),
    ProviderMyServicesPage(),
    ExploreServicesPage(),
    ServiciosEnCursoPage(),
    PerfilProveedorPage(),
  ];

  static const List<_ProviderNavItem> _navItems = [
    _ProviderNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Inicio',
    ),
    _ProviderNavItem(
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      label: 'Mis\nservicios',
    ),
    _ProviderNavItem(
      icon: Icons.travel_explore_outlined,
      selectedIcon: Icons.travel_explore,
      label: 'Market-\nplace',
    ),
    _ProviderNavItem(
      icon: Icons.work_history_outlined,
      selectedIcon: Icons.work_history,
      label: 'Operación',
    ),
    _ProviderNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: UserRole.proveedor,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _ProviderBottomBar(
          currentIndex: _currentIndex,
          items: _navItems,
          onSelected: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}

class _ProviderBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_ProviderNavItem> items;
  final ValueChanged<int> onSelected;

  const _ProviderBottomBar({
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
            border: Border(
              top: BorderSide(color: Color(0xFFE5EBE7)),
            ),
          ),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _ProviderBottomBarButton(
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

class _ProviderBottomBarButton extends StatelessWidget {
  final _ProviderNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderBottomBarButton({
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

class _ProviderNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _ProviderNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
