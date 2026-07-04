// Este archivo re-exporta la versión de Firestore para compatibilidad
import 'categories_page_firestore.dart' show CategoriesPageGallery;
export 'categories_page_firestore.dart' show CategoriesPageGallery;

// Alias para que CategoriesPage refiera a la versión de Firestore
typedef CategoriesPage = CategoriesPageGallery;
