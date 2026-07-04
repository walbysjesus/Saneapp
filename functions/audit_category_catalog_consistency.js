const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

function parseArgs(argv) {
  const args = argv.slice(2);
  const projectArg = args.find((token) => token.startsWith('--project='));
  const limitArg = args.find((token) => token.startsWith('--sample-limit='));
  const outArg = args.find((token) => token.startsWith('--out='));
  const collectionArg = args.find((token) => token.startsWith('--report-collection='));
  const reportIdArg = args.find((token) => token.startsWith('--report-id='));

  const projectId = projectArg
    ? projectArg.split('=')[1]
    : process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || 'saneapp-clean';

  const sampleLimit = Number.parseInt(limitArg ? limitArg.split('=')[1] : '30', 10);

  return {
    projectId,
    sampleLimit: Number.isFinite(sampleLimit) && sampleLimit > 0 ? sampleLimit : 30,
    outputPath: outArg ? outArg.split('=')[1] : '',
    failOnUnresolved: args.includes('--fail-on-unresolved'),
    writeFirestoreReport: args.includes('--write-firestore-report'),
    reportCollection: collectionArg ? collectionArg.split('=')[1] : 'operational_audits',
    reportId: reportIdArg ? reportIdArg.split('=')[1] : '',
  };
}

function createReportId() {
  const now = new Date();
  const y = now.getUTCFullYear();
  const m = String(now.getUTCMonth() + 1).padStart(2, '0');
  const d = String(now.getUTCDate()).padStart(2, '0');
  const h = String(now.getUTCHours()).padStart(2, '0');
  const min = String(now.getUTCMinutes()).padStart(2, '0');
  const s = String(now.getUTCSeconds()).padStart(2, '0');
  return `run_${y}${m}${d}_${h}${min}${s}`;
}

function normalizeString(value) {
  return String(value || '').trim().toLowerCase();
}

function uniqueStrings(values) {
  const out = [];
  for (const value of values || []) {
    const str = String(value || '').trim();
    if (!str || out.includes(str)) {
      continue;
    }
    out.push(str);
  }
  return out;
}

async function buildCatalogMaps(firestore) {
  const categoriesSnap = await firestore.collection('categories').get();

  const categoryIds = new Set();
  const categoryNameToId = new Map();
  const subcategoryIdsGlobal = new Set();
  const subcategoryNameToIdsGlobal = new Map();
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
    const subNameToIds = new Map();

    for (const subDoc of subSnap.docs) {
      const subData = subDoc.data() || {};
      const subId = subDoc.id;
      const subName = normalizeString(subData.name || subId);

      subIdSet.add(subId);
      subcategoryIdsGlobal.add(subId);

      if (!subNameToIds.has(subName)) {
        subNameToIds.set(subName, []);
      }
      subNameToIds.get(subName).push(subId);

      if (!subcategoryNameToIdsGlobal.has(subName)) {
        subcategoryNameToIdsGlobal.set(subName, []);
      }
      subcategoryNameToIdsGlobal.get(subName).push(subId);
    }

    subcategoriesByCategoryId.set(categoryId, {
      subIdSet,
      subNameToIds,
    });
  }

  return {
    categoryIds,
    categoryNameToId,
    subcategoryIdsGlobal,
    subcategoryNameToIdsGlobal,
    subcategoriesByCategoryId,
  };
}

function getScopedSubcatalog(categoryIds, catalog) {
  const subIdsScoped = new Set();
  const subNameToIdsScoped = new Map();

  for (const categoryId of categoryIds) {
    const subMeta = catalog.subcategoriesByCategoryId.get(categoryId);
    if (!subMeta) {
      continue;
    }

    for (const subId of subMeta.subIdSet) {
      subIdsScoped.add(subId);
    }

    for (const [name, ids] of subMeta.subNameToIds.entries()) {
      if (!subNameToIdsScoped.has(name)) {
        subNameToIdsScoped.set(name, []);
      }
      for (const id of ids) {
        if (!subNameToIdsScoped.get(name).includes(id)) {
          subNameToIdsScoped.get(name).push(id);
        }
      }
    }
  }

  return { subIdsScoped, subNameToIdsScoped };
}

function inspectDocumentCatalog(data, catalog) {
  const selectedCategories = uniqueStrings(data.selectedCategories);
  const selectedSubcategories = uniqueStrings(data.selectedSubcategories);

  const categories = {
    validIds: [],
    legacyNames: [],
    unknownValues: [],
  };

  for (const raw of selectedCategories) {
    if (catalog.categoryIds.has(raw)) {
      categories.validIds.push(raw);
      continue;
    }

    const resolved = catalog.categoryNameToId.get(normalizeString(raw));
    if (resolved) {
      categories.legacyNames.push({ raw, resolvedId: resolved });
    } else {
      categories.unknownValues.push(raw);
    }
  }

  const effectiveCategoryIds = uniqueStrings([
    ...categories.validIds,
    ...categories.legacyNames.map((item) => item.resolvedId),
  ]);

  const scopedSubcatalog = getScopedSubcatalog(effectiveCategoryIds, catalog);

  const subcategories = {
    validIds: [],
    legacyNames: [],
    ambiguousLegacyNames: [],
    outOfScopeIds: [],
    unknownValues: [],
  };

  for (const raw of selectedSubcategories) {
    if (scopedSubcatalog.subIdsScoped.has(raw)) {
      subcategories.validIds.push(raw);
      continue;
    }

    const scopedMatches = scopedSubcatalog.subNameToIdsScoped.get(normalizeString(raw)) || [];
    if (scopedMatches.length === 1) {
      subcategories.legacyNames.push({ raw, resolvedId: scopedMatches[0] });
      continue;
    }
    if (scopedMatches.length > 1) {
      subcategories.ambiguousLegacyNames.push({ raw, candidates: scopedMatches });
      continue;
    }

    if (catalog.subcategoryIdsGlobal.has(raw)) {
      subcategories.outOfScopeIds.push(raw);
      continue;
    }

    const globalMatches = catalog.subcategoryNameToIdsGlobal.get(normalizeString(raw)) || [];
    if (globalMatches.length > 1) {
      subcategories.ambiguousLegacyNames.push({ raw, candidates: globalMatches });
    } else {
      subcategories.unknownValues.push(raw);
    }
  }

  const hasLegacy = categories.legacyNames.length > 0 || subcategories.legacyNames.length > 0;
  const hasUnresolved =
    categories.unknownValues.length > 0 ||
    subcategories.ambiguousLegacyNames.length > 0 ||
    subcategories.outOfScopeIds.length > 0 ||
    subcategories.unknownValues.length > 0;

  return {
    selectedCategories,
    selectedSubcategories,
    effectiveCategoryIds,
    categories,
    subcategories,
    status: {
      hasLegacy,
      hasUnresolved,
      isClean: !hasLegacy && !hasUnresolved,
    },
  };
}

function pushSample(summary, item, limit) {
  if (summary.samples.length < limit) {
    summary.samples.push(item);
  }
}

async function auditCollection({ firestore, collectionName, catalog, summary, sampleLimit }) {
  const snapshot = await firestore.collection(collectionName).get();

  summary.collections[collectionName] = {
    scanned: snapshot.size,
    inspected: 0,
    clean: 0,
    legacy: 0,
    unresolved: 0,
  };

  summary.totals.scanned += snapshot.size;

  for (const doc of snapshot.docs) {
    const data = doc.data() || {};
    const hasCatalogFields =
      Array.isArray(data.selectedCategories) || Array.isArray(data.selectedSubcategories);

    if (!hasCatalogFields) {
      continue;
    }

    summary.collections[collectionName].inspected += 1;
    summary.totals.inspected += 1;

    const result = inspectDocumentCatalog(data, catalog);

    if (result.status.isClean) {
      summary.collections[collectionName].clean += 1;
      summary.totals.clean += 1;
      continue;
    }

    if (result.status.hasLegacy) {
      summary.collections[collectionName].legacy += 1;
      summary.totals.legacy += 1;
      pushSample(
        summary,
        {
          type: 'legacy',
          collection: collectionName,
          id: doc.id,
          categoriesLegacy: result.categories.legacyNames,
          subcategoriesLegacy: result.subcategories.legacyNames,
        },
        sampleLimit,
      );
    }

    if (result.status.hasUnresolved) {
      summary.collections[collectionName].unresolved += 1;
      summary.totals.unresolved += 1;
      pushSample(
        summary,
        {
          type: 'unresolved',
          collection: collectionName,
          id: doc.id,
          unknownCategories: result.categories.unknownValues,
          ambiguousSubcategories: result.subcategories.ambiguousLegacyNames,
          outOfScopeSubcategories: result.subcategories.outOfScopeIds,
          unknownSubcategories: result.subcategories.unknownValues,
        },
        sampleLimit,
      );
    }
  }
}

function persistJsonReport(outputPath, summary) {
  if (!outputPath) {
    return null;
  }

  const targetPath = path.isAbsolute(outputPath)
    ? outputPath
    : path.resolve(process.cwd(), outputPath);
  fs.mkdirSync(path.dirname(targetPath), { recursive: true });
  fs.writeFileSync(targetPath, `${JSON.stringify(summary, null, 2)}\n`, 'utf8');
  return targetPath;
}

async function persistFirestoreReport({ firestore, summary, reportCollection, reportId }) {
  const safeCollection = String(reportCollection || '').trim() || 'operational_audits';
  const resolvedReportId = String(reportId || '').trim() || createReportId();

  const reportRef = firestore
    .collection(safeCollection)
    .doc('category_catalog')
    .collection('runs')
    .doc(resolvedReportId);

  await reportRef.set({
    ...summary,
    reportId: resolvedReportId,
    reportPath: reportRef.path,
    writtenAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return reportRef.path;
}

async function runCategoryConsistencyAudit(options) {
  const opts = {
    projectId:
      options.projectId || process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || 'saneapp-clean',
    sampleLimit: Number.isFinite(options.sampleLimit) && options.sampleLimit > 0 ? options.sampleLimit : 30,
    failOnUnresolved: options.failOnUnresolved === true,
    outputPath: options.outputPath || '',
    writeFirestoreReport: options.writeFirestoreReport === true,
    reportCollection: options.reportCollection || 'operational_audits',
    reportId: options.reportId || '',
  };

  if (admin.apps.length === 0) {
    admin.initializeApp({
      projectId: opts.projectId,
    });
  }

  const firestore = admin.firestore();
  const catalog = await buildCatalogMaps(firestore);

  const summary = {
    mode: 'audit-read-only',
    projectId: opts.projectId,
    generatedAt: new Date().toISOString(),
    catalog: {
      categories: catalog.categoryIds.size,
      subcategories: catalog.subcategoryIdsGlobal.size,
    },
    totals: {
      scanned: 0,
      inspected: 0,
      clean: 0,
      legacy: 0,
      unresolved: 0,
    },
    collections: {},
    samples: [],
  };

  await auditCollection({
    firestore,
    collectionName: 'providers',
    catalog,
    summary,
    sampleLimit: opts.sampleLimit,
  });

  await auditCollection({
    firestore,
    collectionName: 'users',
    catalog,
    summary,
    sampleLimit: opts.sampleLimit,
  });

  if (opts.writeFirestoreReport) {
    summary.firestoreReportPath = await persistFirestoreReport({
      firestore,
      summary,
      reportCollection: opts.reportCollection,
      reportId: opts.reportId,
    });
  }

  if (opts.outputPath) {
    summary.outputPath = persistJsonReport(opts.outputPath, summary);
  }

  if (opts.failOnUnresolved && summary.totals.unresolved > 0) {
    const error = new Error(
      `category_catalog_unresolved:${summary.totals.unresolved}`,
    );
    error.code = 2;
    error.summary = summary;
    throw error;
  }

  return summary;
}

async function main() {
  const options = parseArgs(process.argv);
  const summary = await runCategoryConsistencyAudit(options);

  console.log('=== Category Catalog Consistency Audit ===');
  console.log(JSON.stringify(summary, null, 2));
}

if (require.main === module) {
  main().catch((error) => {
    if (error.summary) {
      console.log('=== Category Catalog Consistency Audit ===');
      console.log(JSON.stringify(error.summary, null, 2));
    }
    console.error('Category consistency audit failed:', error);
    process.exitCode = Number.isInteger(error.code) ? error.code : 1;
  });
}

module.exports = {
  runCategoryConsistencyAudit,
};
