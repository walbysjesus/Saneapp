const admin = require('firebase-admin');

function parseArgs(argv) {
  const args = new Set(argv.slice(2));
  const projectArg = argv
    .slice(2)
    .find((token) => token.startsWith('--project='));

  const projectId = projectArg
    ? projectArg.split('=')[1]
    : process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || 'saneapp-clean';

  return {
    apply: args.has('--apply'),
    dryRun: args.has('--dry-run') || !args.has('--apply'),
    projectId,
  };
}

function normalizeString(value) {
  return String(value || '').trim().toLowerCase();
}

function uniqueStrings(values) {
  const out = [];
  for (const value of values) {
    const str = String(value || '').trim();
    if (!str) {
      continue;
    }
    if (!out.includes(str)) {
      out.push(str);
    }
  }
  return out;
}

async function buildCatalogMaps(firestore) {
  const categoriesSnap = await firestore.collection('categories').get();

  const categoryIds = new Set();
  const categoryNameToId = new Map();
  const subcategoriesByCategoryId = new Map();

  for (const doc of categoriesSnap.docs) {
    const data = doc.data() || {};
    const categoryId = doc.id;
    const categoryName = normalizeString(data.name || categoryId);

    categoryIds.add(categoryId);
    categoryNameToId.set(categoryName, categoryId);

    const subSnap = await firestore
      .collection('categories')
      .doc(categoryId)
      .collection('subcategories')
      .get();

    const subIdSet = new Set();
    const subNameToId = new Map();

    for (const subDoc of subSnap.docs) {
      const subData = subDoc.data() || {};
      const subId = subDoc.id;
      const subName = normalizeString(subData.name || subId);

      subIdSet.add(subId);
      subNameToId.set(subName, subId);
    }

    subcategoriesByCategoryId.set(categoryId, {
      subIdSet,
      subNameToId,
    });
  }

  return {
    categoryIds,
    categoryNameToId,
    subcategoriesByCategoryId,
  };
}

function normalizeCategories(values, catalog) {
  const normalized = [];
  const unresolved = [];

  for (const raw of values) {
    const candidate = String(raw || '').trim();
    if (!candidate) {
      continue;
    }

    if (catalog.categoryIds.has(candidate)) {
      if (!normalized.includes(candidate)) {
        normalized.push(candidate);
      }
      continue;
    }

    const resolved = catalog.categoryNameToId.get(normalizeString(candidate));
    if (resolved) {
      if (!normalized.includes(resolved)) {
        normalized.push(resolved);
      }
    } else {
      unresolved.push(candidate);
    }
  }

  return { normalized, unresolved };
}

function normalizeSubcategories(values, normalizedCategoryIds, catalog) {
  const normalized = [];
  const unresolved = [];

  const allSubIds = new Set();
  const subNameToIds = new Map();

  for (const categoryId of normalizedCategoryIds) {
    const subMeta = catalog.subcategoriesByCategoryId.get(categoryId);
    if (!subMeta) {
      continue;
    }

    for (const id of subMeta.subIdSet) {
      allSubIds.add(id);
    }

    for (const [name, id] of subMeta.subNameToId.entries()) {
      if (!subNameToIds.has(name)) {
        subNameToIds.set(name, []);
      }
      const bucket = subNameToIds.get(name);
      if (!bucket.includes(id)) {
        bucket.push(id);
      }
    }
  }

  for (const raw of values) {
    const candidate = String(raw || '').trim();
    if (!candidate) {
      continue;
    }

    if (allSubIds.has(candidate)) {
      if (!normalized.includes(candidate)) {
        normalized.push(candidate);
      }
      continue;
    }

    const matches = subNameToIds.get(normalizeString(candidate)) || [];
    if (matches.length === 1) {
      if (!normalized.includes(matches[0])) {
        normalized.push(matches[0]);
      }
    } else {
      unresolved.push(candidate);
    }
  }

  return { normalized, unresolved };
}

function shouldInspectDocument(data) {
  if (!data || typeof data !== 'object') {
    return false;
  }

  return Array.isArray(data.selectedCategories) || Array.isArray(data.selectedSubcategories);
}

async function migrateCollection({
  firestore,
  collectionName,
  catalog,
  dryRun,
  summary,
}) {
  const snapshot = await firestore.collection(collectionName).get();
  summary.scanned += snapshot.size;

  for (const doc of snapshot.docs) {
    const data = doc.data() || {};
    if (!shouldInspectDocument(data)) {
      continue;
    }

    const originalCategories = uniqueStrings(data.selectedCategories || []);
    const originalSubcategories = uniqueStrings(data.selectedSubcategories || []);

    const categoryResult = normalizeCategories(originalCategories, catalog);
    const subcategoryResult = normalizeSubcategories(
      originalSubcategories,
      categoryResult.normalized,
      catalog,
    );

    const categoryChanged =
      JSON.stringify(originalCategories) !== JSON.stringify(categoryResult.normalized);
    const subcategoryChanged =
      JSON.stringify(originalSubcategories) !== JSON.stringify(subcategoryResult.normalized);

    if (!categoryChanged && !subcategoryChanged) {
      continue;
    }

    summary.changed += 1;
    summary.byCollection[collectionName] = (summary.byCollection[collectionName] || 0) + 1;

    if (categoryResult.unresolved.length > 0 || subcategoryResult.unresolved.length > 0) {
      summary.unresolved += 1;
      summary.unresolvedDocs.push({
        collection: collectionName,
        id: doc.id,
        unresolvedCategories: categoryResult.unresolved,
        unresolvedSubcategories: subcategoryResult.unresolved,
      });
    }

    if (dryRun) {
      continue;
    }

    await doc.ref.set(
      {
        selectedCategories: categoryResult.normalized,
        selectedSubcategories: subcategoryResult.normalized,
        categoryMigration: {
          version: 1,
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
          migratedBy: 'migrate_categories_legacy.js',
          unresolvedCategories: categoryResult.unresolved,
          unresolvedSubcategories: subcategoryResult.unresolved,
        },
      },
      { merge: true },
    );

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
    scanned: 0,
    changed: 0,
    applied: 0,
    unresolved: 0,
    byCollection: {},
    unresolvedDocs: [],
  };

  await migrateCollection({
    firestore,
    collectionName: 'providers',
    catalog,
    dryRun: options.dryRun,
    summary,
  });

  await migrateCollection({
    firestore,
    collectionName: 'users',
    catalog,
    dryRun: options.dryRun,
    summary,
  });

  console.log('=== Category Legacy Migration Summary ===');
  console.log(JSON.stringify(summary, null, 2));
}

main().catch((error) => {
  console.error('Category legacy migration failed:', error);
  process.exitCode = 1;
});
