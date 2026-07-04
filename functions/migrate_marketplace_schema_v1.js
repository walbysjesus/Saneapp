const admin = require('firebase-admin');

function parseArgs(argv) {
  const args = argv.slice(2);
  const asSet = new Set(args);
  const projectArg = args.find((token) => token.startsWith('--project='));

  const projectId = projectArg
    ? projectArg.split('=')[1]
    : process.env.FIREBASE_PROJECT_ID ||
      process.env.GCLOUD_PROJECT ||
      'saneapp-clean';

  return {
    apply: asSet.has('--apply'),
    dryRun: asSet.has('--dry-run') || !asSet.has('--apply'),
    projectId,
  };
}

function normalizeString(value) {
  return String(value || '').trim();
}

function normalizeKey(value) {
  return normalizeString(value).toLowerCase();
}

function firstNonEmpty(values) {
  for (const value of values) {
    const normalized = normalizeString(value);
    if (normalized) {
      return normalized;
    }
  }
  return '';
}

function toBool(value, fallback) {
  if (typeof value === 'boolean') {
    return value;
  }
  const normalized = normalizeKey(value);
  if (!normalized) {
    return fallback;
  }
  if (['true', '1', 'yes', 'si', 'activo', 'active', 'published', 'publicado'].includes(normalized)) {
    return true;
  }
  if (['false', '0', 'no', 'inactive', 'inactivo'].includes(normalized)) {
    return false;
  }
  return fallback;
}

async function buildCatalogMaps(firestore) {
  const categoriesSnap = await firestore.collection('categories').get();

  const categoryNameToId = new Map();
  const categoryMetaById = new Map();

  for (const categoryDoc of categoriesSnap.docs) {
    const categoryData = categoryDoc.data() || {};
    const categoryId = categoryDoc.id;
    const categoryName = normalizeString(categoryData.name || categoryId);

    categoryNameToId.set(normalizeKey(categoryName), categoryId);

    const subSnap = await firestore
      .collection('categories')
      .doc(categoryId)
      .collection('subcategories')
      .get();

    const subNameToId = new Map();
    const subLabelById = new Map();

    for (const subDoc of subSnap.docs) {
      const subData = subDoc.data() || {};
      const subId = subDoc.id;
      const subName = normalizeString(subData.name || subId);
      subNameToId.set(normalizeKey(subName), subId);
      subLabelById.set(subId, subName);
    }

    categoryMetaById.set(categoryId, {
      categoryId,
      categoryName,
      subNameToId,
      subLabelById,
    });
  }

  return {
    categoryNameToId,
    categoryMetaById,
  };
}

function resolveCategory({
  rawCategoryId,
  rawCategoryName,
  catalog,
}) {
  const idCandidate = normalizeString(rawCategoryId);
  if (idCandidate && catalog.categoryMetaById.has(idCandidate)) {
    const meta = catalog.categoryMetaById.get(idCandidate);
    return { categoryId: meta.categoryId, categoryName: meta.categoryName };
  }

  const nameCandidate = normalizeString(rawCategoryName);
  if (nameCandidate) {
    const resolvedId = catalog.categoryNameToId.get(normalizeKey(nameCandidate));
    if (resolvedId) {
      const meta = catalog.categoryMetaById.get(resolvedId);
      return { categoryId: meta.categoryId, categoryName: meta.categoryName };
    }
  }

  return {
    categoryId: idCandidate,
    categoryName: nameCandidate,
  };
}

function resolveSubcategory({
  categoryId,
  rawSubcategoryId,
  rawSubcategoryName,
  catalog,
}) {
  const categoryMeta = catalog.categoryMetaById.get(categoryId);
  if (!categoryMeta) {
    return {
      subcategoryId: normalizeString(rawSubcategoryId),
      subcategoryName: normalizeString(rawSubcategoryName),
    };
  }

  const idCandidate = normalizeString(rawSubcategoryId);
  if (idCandidate && categoryMeta.subLabelById.has(idCandidate)) {
    return {
      subcategoryId: idCandidate,
      subcategoryName: categoryMeta.subLabelById.get(idCandidate),
    };
  }

  const nameCandidate = normalizeString(rawSubcategoryName);
  if (nameCandidate) {
    const resolvedId = categoryMeta.subNameToId.get(normalizeKey(nameCandidate));
    if (resolvedId) {
      return {
        subcategoryId: resolvedId,
        subcategoryName: categoryMeta.subLabelById.get(resolvedId),
      };
    }
  }

  return {
    subcategoryId: idCandidate,
    subcategoryName: nameCandidate,
  };
}

function buildProviderServicePatch(data, catalog) {
  const rawCategoryId = firstNonEmpty([
    data.categoryId,
    data.serviceCategoryId,
    data.category_id,
  ]);
  const rawCategoryName = firstNonEmpty([
    data.categoryName,
    data.serviceCategoryName,
    data.serviceCategory,
    data.categoria,
  ]);

  const resolvedCategory = resolveCategory({
    rawCategoryId,
    rawCategoryName,
    catalog,
  });

  const rawSubcategoryId = firstNonEmpty([
    data.subcategoryId,
    data.serviceSubcategoryId,
    data.subcategory_id,
  ]);
  const rawSubcategoryName = firstNonEmpty([
    data.subcategoryName,
    data.serviceSubcategoryName,
    data.serviceSubcategory,
    data.subcategoria,
  ]);

  const resolvedSubcategory = resolveSubcategory({
    categoryId: resolvedCategory.categoryId,
    rawSubcategoryId,
    rawSubcategoryName,
    catalog,
  });

  const priceFrom =
    typeof data.priceFrom === 'number'
      ? data.priceFrom
      : typeof data.price === 'number'
      ? data.price
      : null;

  const responseTime = firstNonEmpty([
    data.responseTime,
    typeof data.responseTimeMinutes === 'number'
      ? `${Math.trunc(data.responseTimeMinutes)} min`
      : '',
  ]);

  const shortDescription = firstNonEmpty([
    data.shortDescription,
    data.description,
  ]);

  const technicalDescription = firstNonEmpty([
    data.technicalDescription,
    data.description,
    data.shortDescription,
  ]);

  const isActive = toBool(data.isActive, toBool(data.status, true));

  const patch = {
    categoryId: resolvedCategory.categoryId || null,
    categoryName: resolvedCategory.categoryName || null,
    serviceCategoryId: resolvedCategory.categoryId || null,
    serviceCategoryName: resolvedCategory.categoryName || null,
    serviceCategory: resolvedCategory.categoryName || null,
    subcategoryId: resolvedSubcategory.subcategoryId || null,
    subcategoryName: resolvedSubcategory.subcategoryName || null,
    serviceSubcategoryId: resolvedSubcategory.subcategoryId || null,
    serviceSubcategoryName: resolvedSubcategory.subcategoryName || null,
    serviceSubcategory: resolvedSubcategory.subcategoryName || null,
    isActive,
    status: isActive ? 'active' : 'inactive',
    marketplaceSchemaVersion: 1,
    marketplaceSchemaUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    marketplaceSchemaUpdatedBy: 'migrate_marketplace_schema_v1.js',
  };

  if (priceFrom != null) {
    patch.priceFrom = priceFrom;
    patch.price = priceFrom;
  }
  if (shortDescription) {
    patch.shortDescription = shortDescription;
  }
  if (technicalDescription) {
    patch.technicalDescription = technicalDescription;
  }
  if (responseTime) {
    patch.responseTime = responseTime;
  }

  return patch;
}

function buildSolicitudPatch(data, catalog) {
  const rawCategoryId = firstNonEmpty([
    data.serviceCategoryId,
    data.categoryId,
  ]);
  const rawCategoryName = firstNonEmpty([
    data.serviceCategoryName,
    data.serviceCategory,
    data.serviceInterest,
    data.categoryName,
  ]);

  const resolvedCategory = resolveCategory({
    rawCategoryId,
    rawCategoryName,
    catalog,
  });

  const rawSubcategoryId = firstNonEmpty([
    data.serviceSubcategoryId,
    data.subcategoryId,
  ]);
  const rawSubcategoryName = firstNonEmpty([
    data.serviceSubcategoryName,
    data.serviceSubcategory,
    data.subcategoryName,
  ]);

  const resolvedSubcategory = resolveSubcategory({
    categoryId: resolvedCategory.categoryId,
    rawSubcategoryId,
    rawSubcategoryName,
    catalog,
  });

  const patch = {
    serviceCategoryId: resolvedCategory.categoryId || null,
    serviceCategoryName: resolvedCategory.categoryName || null,
    serviceCategory: resolvedCategory.categoryName || null,
    categoryId: resolvedCategory.categoryId || null,
    categoryName: resolvedCategory.categoryName || null,
    serviceSubcategoryId: resolvedSubcategory.subcategoryId || null,
    serviceSubcategoryName: resolvedSubcategory.subcategoryName || null,
    serviceSubcategory: resolvedSubcategory.subcategoryName || null,
    subcategoryId: resolvedSubcategory.subcategoryId || null,
    subcategoryName: resolvedSubcategory.subcategoryName || null,
    marketplaceSchemaVersion: 1,
    marketplaceSchemaUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    marketplaceSchemaUpdatedBy: 'migrate_marketplace_schema_v1.js',
  };

  if (!normalizeString(data.serviceInterest) && resolvedCategory.categoryName) {
    patch.serviceInterest = resolvedCategory.categoryName;
  }

  return patch;
}

function diffPatch(data, patch) {
  const out = {};
  for (const [key, value] of Object.entries(patch)) {
    if (key === 'marketplaceSchemaUpdatedAt') {
      out[key] = value;
      continue;
    }
    const current = data[key];
    if (JSON.stringify(current) !== JSON.stringify(value)) {
      out[key] = value;
    }
  }
  return out;
}

async function migrateCollection({
  firestore,
  collectionName,
  catalog,
  dryRun,
  patchBuilder,
  summary,
}) {
  const snapshot = await firestore.collection(collectionName).get();
  summary.scannedByCollection[collectionName] = snapshot.size;

  for (const doc of snapshot.docs) {
    summary.scanned += 1;
    const data = doc.data() || {};

    const patch = patchBuilder(data, catalog);
    const changes = diffPatch(data, patch);
    const changeKeys = Object.keys(changes).filter(
      (key) => key !== 'marketplaceSchemaUpdatedAt',
    );

    if (changeKeys.length === 0) {
      continue;
    }

    summary.changed += 1;
    summary.changedByCollection[collectionName] =
      (summary.changedByCollection[collectionName] || 0) + 1;

    if (summary.samples.length < 25) {
      summary.samples.push({
        collection: collectionName,
        id: doc.id,
        fields: changeKeys,
      });
    }

    if (dryRun) {
      continue;
    }

    await doc.ref.set(changes, { merge: true });
    summary.applied += 1;
  }
}

async function main() {
  const options = parseArgs(process.argv);

  if (admin.apps.length === 0) {
    admin.initializeApp({
      projectId: options.projectId,
    });
  }

  const firestore = admin.firestore();
  const catalog = await buildCatalogMaps(firestore);

  const summary = {
    mode: options.dryRun ? 'dry-run' : 'apply',
    projectId: options.projectId,
    scanned: 0,
    changed: 0,
    applied: 0,
    scannedByCollection: {},
    changedByCollection: {},
    samples: [],
  };

  await migrateCollection({
    firestore,
    collectionName: 'provider_services',
    catalog,
    dryRun: options.dryRun,
    patchBuilder: buildProviderServicePatch,
    summary,
  });

  await migrateCollection({
    firestore,
    collectionName: 'solicitudes',
    catalog,
    dryRun: options.dryRun,
    patchBuilder: buildSolicitudPatch,
    summary,
  });

  console.log('=== Marketplace Schema Migration v1 ===');
  console.log(JSON.stringify(summary, null, 2));
}

main().catch((error) => {
  console.error('Marketplace schema migration failed:', error);
  process.exitCode = 1;
});
