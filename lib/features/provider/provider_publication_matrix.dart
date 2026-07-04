import 'package:flutter/material.dart';

enum MarketplaceFieldKind {
  text,
  multiline,
  number,
  choice,
  boolean,
}

class MarketplaceServiceLine {
  final String id;
  final String label;
  final String subtitle;
  final String description;
  final IconData icon;

  const MarketplaceServiceLine({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.description,
    required this.icon,
  });
}

class MarketplacePublicationFieldDefinition {
  final String key;
  final String label;
  final String hint;
  final MarketplaceFieldKind kind;
  final bool isRequired;
  final List<String> options;

  const MarketplacePublicationFieldDefinition({
    required this.key,
    required this.label,
    required this.hint,
    required this.kind,
    this.isRequired = true,
    this.options = const <String>[],
  });
}

class MarketplacePublicationTemplate {
  final String title;
  final String description;
  final List<MarketplacePublicationFieldDefinition> fields;

  const MarketplacePublicationTemplate({
    required this.title,
    required this.description,
    required this.fields,
  });
}

const marketplaceServiceLines = <MarketplaceServiceLine>[
  MarketplaceServiceLine(
    id: 'environmental_services',
    label: 'Servicios ambientales',
    subtitle: 'Operaciones recurrentes y puntuales',
    description:
        'Publica recoleccion, limpieza, manejo integral, saneamiento y soluciones operativas para empresas y generadores.',
    icon: Icons.forest_outlined,
  ),
  MarketplaceServiceLine(
    id: 'equipment_with_operator',
    label: 'Equipos con operador',
    subtitle: 'Vactor, succion, presion y maquinaria',
    description:
        'Oferta equipos especializados con operador, ventanas de operacion y capacidad tecnica visible desde la vitrina.',
    icon: Icons.local_shipping_outlined,
  ),
  MarketplaceServiceLine(
    id: 'emergency_response',
    label: 'Atencion de emergencias',
    subtitle: 'Respuesta prioritaria y contingencias',
    description:
        'Publica servicios para derrames, contingencias ambientales, atencion 24/7 y despliegue rapido en sitio.',
    icon: Icons.crisis_alert_outlined,
  ),
  MarketplaceServiceLine(
    id: 'transport_and_disposal',
    label: 'Transporte y disposicion',
    subtitle: 'Trazabilidad logistica y cumplimiento',
    description:
        'Muestra rutas, manifiestos, disposicion final y capacidades de transporte para residuos o materiales.',
    icon: Icons.alt_route_outlined,
  ),
  MarketplaceServiceLine(
    id: 'technical_supervision',
    label: 'Supervision tecnica',
    subtitle: 'Visitas, inspeccion y control operacional',
    description:
        'Publica acompanamiento tecnico, auditoria en sitio, control de calidad y seguimiento con evidencia.',
    icon: Icons.verified_outlined,
  ),
];

MarketplaceServiceLine? findMarketplaceServiceLine(String? id) {
  for (final line in marketplaceServiceLines) {
    if (line.id == id) {
      return line;
    }
  }
  return null;
}

MarketplacePublicationTemplate resolveMarketplacePublicationTemplate({
  required String? serviceLineId,
  required String? categoryName,
  required String? subcategoryName,
}) {
  final normalizedCategory = (categoryName ?? '').toLowerCase();
  final normalizedSubcategory = (subcategoryName ?? '').toLowerCase();

  if (normalizedSubcategory.contains('residu') ||
      normalizedCategory.contains('residu') ||
      serviceLineId == 'transport_and_disposal') {
    return const MarketplacePublicationTemplate(
      title: 'Ficha para recoleccion, transporte y disposicion',
      description:
          'Este servicio necesita dejar claros tipo de residuo, volumen, frecuencia y soportes documentales para cotizar mejor.',
      fields: [
        MarketplacePublicationFieldDefinition(
          key: 'wasteType',
          label: 'Tipo de residuo o material',
          hint: 'Ejemplo: biosanitario, ordinario, lodos, aceites usados',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'estimatedVolume',
          label: 'Volumen o tonelaje de referencia',
          hint: 'Ejemplo: 12 m3 por mes o 4 toneladas por retiro',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'serviceFrequency',
          label: 'Frecuencia operacional',
          hint: 'Selecciona cada cuanto suele prestarse el servicio',
          kind: MarketplaceFieldKind.choice,
          options: [
            'Servicio puntual',
            'Semanal',
            'Quincenal',
            'Mensual',
            'Contrato recurrente',
          ],
        ),
        MarketplacePublicationFieldDefinition(
          key: 'complianceDocuments',
          label: 'Soportes o certificados incluidos',
          hint: 'Manifiestos, certificados, cadenas de custodia o reportes',
          kind: MarketplaceFieldKind.multiline,
        ),
      ],
    );
  }

  if (normalizedSubcategory.contains('vactor') ||
      normalizedSubcategory.contains('succion') ||
      normalizedSubcategory.contains('presion') ||
      serviceLineId == 'equipment_with_operator') {
    return const MarketplacePublicationTemplate(
      title: 'Ficha para equipos con operador',
      description:
          'El comprador debe entender capacidad de equipo, tipo de intervencion y restricciones operativas antes de contratar.',
      fields: [
        MarketplacePublicationFieldDefinition(
          key: 'equipmentCapacity',
          label: 'Capacidad del equipo',
          hint: 'Ejemplo: 8 m3, 12 m3 o 2500 PSI',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'interventionType',
          label: 'Tipo de intervencion',
          hint: 'Succion, lavado, destape, limpieza de redes, mantenimiento',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'operationWindow',
          label: 'Ventana de operacion habitual',
          hint: 'Dias, horarios y disponibilidad nocturna o fines de semana',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'requiresSiteShutdown',
          label: 'Requiere paro operativo del cliente',
          hint: 'Indica si el servicio puede ejecutarse con la operacion activa',
          kind: MarketplaceFieldKind.boolean,
        ),
      ],
    );
  }

  if (normalizedSubcategory.contains('limpieza') ||
      normalizedCategory.contains('limpieza') ||
      serviceLineId == 'environmental_services') {
    return const MarketplacePublicationTemplate(
      title: 'Ficha para limpieza y saneamiento',
      description:
          'Define area, superficies, riesgos y condiciones de ejecucion para que la oferta sea comparable y precisa.',
      fields: [
        MarketplacePublicationFieldDefinition(
          key: 'approximateArea',
          label: 'Area o alcance de referencia',
          hint: 'Ejemplo: 1.200 m2, 4 trampas, 30 metros lineales',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'surfaceType',
          label: 'Tipo de superficie o zona de trabajo',
          hint: 'Pisos industriales, tanques, redes, cubiertas, zona humeda',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'riskLevel',
          label: 'Nivel de riesgo operativo',
          hint: 'Selecciona el nivel de riesgo dominante',
          kind: MarketplaceFieldKind.choice,
          options: ['Bajo', 'Medio', 'Alto', 'Critico'],
        ),
        MarketplacePublicationFieldDefinition(
          key: 'includedSupplies',
          label: 'Insumos o equipos incluidos',
          hint: 'Detalla si incluyes personal, insumos, EPPS o maquinaria',
          kind: MarketplaceFieldKind.multiline,
        ),
      ],
    );
  }

  if (normalizedSubcategory.contains('emerg') ||
      normalizedCategory.contains('emerg') ||
      serviceLineId == 'emergency_response') {
    return const MarketplacePublicationTemplate(
      title: 'Ficha para respuesta a emergencias',
      description:
          'La promesa comercial depende de tiempo de movilizacion, cobertura real y nivel de contingencia que puedes asumir.',
      fields: [
        MarketplacePublicationFieldDefinition(
          key: 'dispatchTime',
          label: 'Tiempo de movilizacion',
          hint: 'Ejemplo: 90 minutos en ciudad o 4 horas regional',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'contingencyType',
          label: 'Tipo de contingencia cubierta',
          hint: 'Derrames, fuga, incidente en planta, contingencia vial',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'availabilityScheme',
          label: 'Esquema de disponibilidad',
          hint: 'Selecciona tu esquema operativo',
          kind: MarketplaceFieldKind.choice,
          options: ['24/7', 'Horario extendido', 'Horario habil', 'Bajo agenda'],
        ),
        MarketplacePublicationFieldDefinition(
          key: 'responseKitIncluded',
          label: 'Incluye kit de respuesta o contencion',
          hint: 'Activa si el servicio incluye equipos o materiales de primera respuesta',
          kind: MarketplaceFieldKind.boolean,
        ),
      ],
    );
  }

  if (serviceLineId == 'technical_supervision') {
    return const MarketplacePublicationTemplate(
      title: 'Ficha para supervision tecnica',
      description:
          'La propuesta debe dejar claro tipo de visita, entregables tecnicos y profundidad del acompanamiento.',
      fields: [
        MarketplacePublicationFieldDefinition(
          key: 'visitScope',
          label: 'Alcance de la visita o supervision',
          hint: 'Diagnostico previo, acompanamiento, auditoria, cierre',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'technicalDeliverables',
          label: 'Entregables tecnicos',
          hint: 'Acta, informe, fotografias, checklist, concepto, hallazgos',
          kind: MarketplaceFieldKind.multiline,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'onsiteHours',
          label: 'Horas estimadas en sitio',
          hint: 'Ejemplo: 4 horas, jornada completa, 2 visitas de 3 horas',
          kind: MarketplaceFieldKind.text,
        ),
      ],
    );
  }

  return const MarketplacePublicationTemplate(
    title: 'Ficha comercial general',
    description:
        'Si la categoria aun no tiene plantilla especializada, pide datos base suficientes para cotizar y comparar con seriedad.',
    fields: [
      MarketplacePublicationFieldDefinition(
        key: 'scopeReference',
        label: 'Referencia de alcance',
        hint: 'Explica la unidad base del servicio que el cliente debe entender',
        kind: MarketplaceFieldKind.text,
      ),
      MarketplacePublicationFieldDefinition(
        key: 'operationalConditions',
        label: 'Condiciones operativas relevantes',
        hint: 'Paradas, accesos, personal minimo, restricciones o dependencias',
        kind: MarketplaceFieldKind.multiline,
      ),
      MarketplacePublicationFieldDefinition(
        key: 'commercialPack',
        label: 'Que incluye tu tarifa base',
        hint: 'Describe personal, equipos, transporte, insumos o evidencias',
        kind: MarketplaceFieldKind.multiline,
      ),
    ],
  );
}

MarketplacePublicationTemplate mergeMarketplacePublicationTemplates({
  required MarketplacePublicationTemplate base,
  required MarketplacePublicationTemplate extra,
}) {
  final mergedFields = <MarketplacePublicationFieldDefinition>[
    ...base.fields,
  ];
  final existingKeys = mergedFields.map((field) => field.key).toSet();
  for (final field in extra.fields) {
    if (!existingKeys.contains(field.key)) {
      mergedFields.add(field);
    }
  }
  return MarketplacePublicationTemplate(
    title: base.title,
    description: '${base.description} ${extra.description}'.trim(),
    fields: mergedFields,
  );
}

MarketplacePublicationTemplate resolveMarketplacePriceTemplate(
  String? priceType,
) {
  final normalizedPriceType = (priceType ?? '').toLowerCase();

  if (normalizedPriceType.contains('hora')) {
    return const MarketplacePublicationTemplate(
      title: 'Condiciones para tarifa por horas',
      description:
          'Cuando vendes por horas necesitas dejar claras jornada, minimo facturable y recargos operativos.',
      fields: [
        MarketplacePublicationFieldDefinition(
          key: 'minimumBillableHours',
          label: 'Minimo de horas facturables',
          hint: 'Ejemplo: minimo 4 horas por visita',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'includedCrew',
          label: 'Personal o cuadrilla incluida',
          hint: 'Indica cuantas personas o que rol tecnico incluye la hora base',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'overtimePolicy',
          label: 'Politica de recargos',
          hint: 'Nocturno, festivo, horas extra o desplazamientos especiales',
          kind: MarketplaceFieldKind.multiline,
        ),
      ],
    );
  }

  if (normalizedPriceType.contains('viaje') ||
      normalizedPriceType.contains('flete')) {
    return const MarketplacePublicationTemplate(
      title: 'Condiciones para tarifa por viaje',
      description:
          'La tarifa por viaje debe dejar clara capacidad movilizada, radio operativo y tiempos de espera incluidos.',
      fields: [
        MarketplacePublicationFieldDefinition(
          key: 'tripCapacity',
          label: 'Capacidad por viaje',
          hint: 'Ejemplo: 8 m3 o 12 toneladas por viaje',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'operatingRadius',
          label: 'Radio o zona de cobertura incluida',
          hint: 'Define hasta donde cubre la tarifa base',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'waitingTimePolicy',
          label: 'Tiempos de espera incluidos',
          hint: 'Aclara tiempo de cargue, descargue y sobrecostos por espera',
          kind: MarketplaceFieldKind.multiline,
        ),
      ],
    );
  }

  if (normalizedPriceType.contains('tonelada') ||
      normalizedPriceType.contains('metro cubico') ||
      normalizedPriceType.contains('metro lineal')) {
    return const MarketplacePublicationTemplate(
      title: 'Condiciones para tarifa por unidad de medida',
      description:
          'Cuando cobras por tonelada, metro cubico o metro lineal debes precisar unidad minima, redondeos y variables de medicion.',
      fields: [
        MarketplacePublicationFieldDefinition(
          key: 'minimumChargeUnit',
          label: 'Unidad minima de cobro',
          hint: 'Ejemplo: minimo 2 toneladas o minimo 10 metros lineales',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'measurementMethod',
          label: 'Metodo de medicion',
          hint: 'Bascula, aforo, medicion en sitio o acta de corte',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'unitExclusions',
          label: 'Exclusiones o variables fuera de tarifa',
          hint: 'Define que genera sobrecosto o cobro separado',
          kind: MarketplaceFieldKind.multiline,
        ),
      ],
    );
  }

  if (normalizedPriceType.contains('cotizacion personalizada')) {
    return const MarketplacePublicationTemplate(
      title: 'Condiciones para cotizacion personalizada',
      description:
          'Si no publicas un precio directo, al menos debes dejar visible como cotizas y que informacion necesitas para responder.',
      fields: [
        MarketplacePublicationFieldDefinition(
          key: 'quotationResponseWindow',
          label: 'Tiempo objetivo para cotizar',
          hint: 'Ejemplo: 24 horas habiles o mismo dia para emergencias',
          kind: MarketplaceFieldKind.text,
        ),
        MarketplacePublicationFieldDefinition(
          key: 'quotationInputs',
          label: 'Informacion minima para cotizar',
          hint: 'Documentos, fotos, volumen, ubicacion, visita o alcance base',
          kind: MarketplaceFieldKind.multiline,
        ),
      ],
    );
  }

  return const MarketplacePublicationTemplate(
    title: 'Condiciones del precio publicado',
    description:
        'La tarifa base debe dejar claro que incluye y bajo que supuesto comercial aplica.',
    fields: [
      MarketplacePublicationFieldDefinition(
        key: 'priceIncludes',
        label: 'Que incluye la tarifa base',
        hint: 'Personal, equipos, transporte, evidencias o soporte tecnico',
        kind: MarketplaceFieldKind.multiline,
      ),
    ],
  );
}

String marketplaceFieldLabel(
  String key, {
  String? priceType,
  String? serviceLineId,
  String? categoryName,
  String? subcategoryName,
}) {
  final template = mergeMarketplacePublicationTemplates(
    base: resolveMarketplacePublicationTemplate(
      serviceLineId: serviceLineId,
      categoryName: categoryName,
      subcategoryName: subcategoryName,
    ),
    extra: resolveMarketplacePriceTemplate(priceType),
  );
  for (final field in template.fields) {
    if (field.key == key) {
      return field.label;
    }
  }
  return key;
}