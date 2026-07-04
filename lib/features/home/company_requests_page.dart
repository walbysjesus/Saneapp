import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../l10n/app_localizations.dart';

// AsegÃºrate de importar o definir ServiceRequest, UserModel, FirebaseService, Proposal

class CompanyRequestsPage extends StatefulWidget {
  const CompanyRequestsPage({super.key});

  @override
  State<CompanyRequestsPage> createState() => _CompanyRequestsPageState();
}

class _CompanyRequestsPageState extends State<CompanyRequestsPage> {
  final TextEditingController _msgController = TextEditingController();

  final List<String> estados = ['pending', 'accepted', 'rejected', 'completed', 'cancelled'];
  final List<String> ciudades = ['BogotÃ¡', 'MedellÃ­n', 'Cali', 'Barranquilla', 'Otra'];
  final List<String> tiposServicio = ['RecolecciÃ³n', 'Limpieza', 'Transporte', 'ConsultorÃ­a', 'DesinfecciÃ³n', 'Otros'];

  String filtroEstado = 'pending';
  String filtroCiudad = '';
  String filtroTipo = '';
  DateTime? filtroFecha;
  List<Map<String, dynamic>> filtrosGuardados = [];
  String? filtroGuardadoSeleccionadoId;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FirebaseAnalytics.instance.logScreenView(screenName: 'CompanyRequestsPage');
  }


  Widget filtrosWidget() {
    Future<void> guardarFiltro() async {
      await FirebaseAnalytics.instance.logEvent(name: 'guardar_filtro', parameters: {
        'estado': filtroEstado,
        'ciudad': filtroCiudad,
        'tipo': filtroTipo,
        'fecha': filtroFecha?.toIso8601String() ?? '',
      });
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final filtro = {
        'estado': filtroEstado,
        'ciudad': filtroCiudad,
        'tipo': filtroTipo,
        'fecha': filtroFecha?.toIso8601String() ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('saved_filters')
          .doc(user.uid)
          .collection('filters')
          .add(filtro);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filtro guardado en la nube')),
      );
    }

    Future<void> cargarFiltros() async {
      await FirebaseAnalytics.instance.logEvent(name: 'cargar_filtros');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('saved_filters')
          .doc(user.uid)
          .collection('filters')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        filtrosGuardados = snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();
      });
      if (filtrosGuardados.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes filtros guardados.')),
        );
      } else {
        showModalBottomSheet(
          context: context,
          builder: (_) => ListView(
            children: filtrosGuardados.map((f) {
              final desc = '${f['estado'] ?? ''} | ${f['ciudad'] ?? ''} | ${f['tipo'] ?? ''} | ${f['fecha'] ?? ''}';
              return ListTile(
                title: Text(desc),
                onTap: () {
                  setState(() {
                    filtroEstado = f['estado'] ?? 'pending';
                    filtroCiudad = f['ciudad'] ?? '';
                    filtroTipo = f['tipo'] ?? '';
                    filtroFecha = f['fecha'] != null ? DateTime.tryParse(f['fecha']) : null;
                    filtroGuardadoSeleccionadoId = f['id'];
                  });
                  FirebaseAnalytics.instance.logEvent(name: 'aplicar_filtro_guardado', parameters: {
                    'filtro_id': f['id'],
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filtro aplicado')),
                  );
                },
              );
            }).toList(),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: filtroEstado,
                  items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => filtroEstado = v ?? 'pending'),
                  decoration: const InputDecoration(labelText: 'Estado'),
                  icon: const Icon(Icons.filter_alt, semanticLabel: 'Filtrar por estado'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: filtroCiudad.isEmpty ? null : filtroCiudad,
                  items: ciudades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => filtroCiudad = v ?? ''),
                  decoration: const InputDecoration(labelText: 'Ciudad'),
                  icon: const Icon(Icons.location_city, semanticLabel: 'Filtrar por ciudad'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: filtroTipo.isEmpty ? null : filtroTipo,
                  items: tiposServicio.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => filtroTipo = v ?? ''),
                  decoration: const InputDecoration(labelText: 'Tipo de servicio'),
                  icon: const Icon(Icons.category, semanticLabel: 'Filtrar por tipo de servicio'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputDatePickerFormField(
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  fieldLabelText: 'Fecha',
                  onDateSubmitted: (d) => setState(() => filtroFecha = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar filtro'),
                onPressed: guardarFiltro,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Cargar filtro'),
                onPressed: cargarFiltros,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final providerId = user?.uid ?? '';
    if (providerId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No has iniciado sesiÃ³n')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(loc?.appTitle ?? 'Solicitudes'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            tooltip: 'Ver mÃ©tricas',
            onPressed: () {
              Navigator.pushNamed(context, '/metrics');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Ver perfil',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          filtrosWidget(),
          // AquÃ­ va el resto de tu lÃ³gica de StreamBuilder y ListView...
        ],
      ),
    );
  }
}
