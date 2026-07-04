// Listado de paÃ­ses (puedes expandirlo segÃºn necesidad)
const List<String> countries = [
  'Colombia',
  'Argentina',
  'Brasil',
  'Chile',
  'Ecuador',
  'MÃ©xico',
  'PerÃº',
  'Venezuela',
  'Estados Unidos',
  'CanadÃ¡',
  'EspaÃ±a',
  'Otro',
];

// 32 departamentos de Colombia
const List<String> colombiaDepartments = [
  'Amazonas', 'Antioquia', 'Arauca', 'AtlÃ¡ntico', 'BolÃ­var', 'BoyacÃ¡', 'Caldas', 'CaquetÃ¡',
  'Casanare', 'Cauca', 'Cesar', 'ChocÃ³', 'CÃ³rdoba', 'Cundinamarca', 'GuainÃ­a', 'Guaviare',
  'Huila', 'La Guajira', 'Magdalena', 'Meta', 'NariÃ±o', 'Norte de Santander', 'Putumayo',
  'QuindÃ­o', 'Risaralda', 'San AndrÃ©s y Providencia', 'Santander', 'Sucre', 'Tolima',
  'Valle del Cauca', 'VaupÃ©s', 'Vichada'
];

// Ejemplo de ciudades/municipios por departamento (debe ser completado segÃºn necesidad real)
const Map<String, List<String>> colombiaCitiesByDepartment = {
  'Antioquia': [
    'MedellÃ­n', 'Bello', 'ItagÃ¼Ã­', 'Envigado', 'ApartadÃ³', 'Turbo', 'Rionegro', 'La Ceja', 'Sabaneta', 'Copacabana', 'Girardota', 'Caucasia', 'Yarumal', 'Santa Fe de Antioquia', 'AmagÃ¡', 'Otros...'
  ],
  'Cundinamarca': [
    'BogotÃ¡', 'Soacha', 'ChÃ­a', 'ZipaquirÃ¡', 'FacatativÃ¡', 'Girardot', 'FusagasugÃ¡', 'Mosquera', 'Madrid', 'Funza', 'CajicÃ¡', 'La Calera', 'Tabio', 'Tenjo', 'Otros...'
  ],
  // ...agrega el resto de departamentos y ciudades principales
};

