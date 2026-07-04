const admin = require('firebase-admin');

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

async function buildCatalogMapsForValidation(firestore) {
  try {
    const categoriesSnap = await firestore.collection('categories').get();

    const categoryIds = new Set();
    const categoryNameToId = new Map();
    const subcategoryIdsGlobal = new Set();
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
        subcategoryIdsGlobal.add(subId);

        if (!subNameToId.has(subName)) {
          subNameToId.set(subName, subId);
        }
      }

      subcategoriesByCategoryId.set(categoryId, {
        subIdSet,
        subNameToId,
      });
    }

    return {
      categoryIds,
      categoryNameToId,
      subcategoryIdsGlobal,
      subcategoriesByCategoryId,
    };
  } catch (error) {
    throw new Error(`Failed to build catalog maps: ${error.message}`);
  }
}

async function validateCategoriesCatalogConsistency(
  firestore,
  documentPath,
  selectedCategories,
  selectedSubcategories,
) {
  const errors = [];

  const selectedCats = uniqueStrings(selectedCategories || []);
  const selectedSubs = uniqueStrings(selectedSubcategories || []);

  if (selectedCats.length === 0 && selectedSubs.length === 0) {
    return { valid: true, errors: [] };
  }

  const catalog = await buildCatalogMapsForValidation(firestore);

  for (const catValue of selectedCats) {
    const isValidId = catalog.categoryIds.has(catValue);
    const resolvedId = catalog.categoryNameToId.get(normalizeString(catValue));

    if (!isValidId && !resolvedId) {
      errors.push({
        type: 'invalid_category',
        value: catValue,
        message: `Category "${catValue}" is not found in catalog at path ${documentPath}`,
        severity: 'error',
      });
    }
  }

  const effectiveCategoryIds = selectedCats
    .filter((catValue) => {
      const isValidId = catalog.categoryIds.has(catValue);
      return isValidId;
    })
    .concat(
      selectedCats
        .filter(
          (catValue) =>
            !catalog.categoryIds.has(catValue) &&
            catalog.categoryNameToId.has(normalizeString(catValue)),
        )
        .map((catValue) => catalog.categoryNameToId.get(normalizeString(catValue))),
    );

  if (selectedSubs.length > 0 && effectiveCategoryIds.length === 0) {
    errors.push({
      type: 'subcategories_without_categories',
      count: selectedSubs.length,
      message: `Document has ${selectedSubs.length} subcategories selected but no valid categories at path ${documentPath}`,
      severity: 'error',
    });
  }

  const validSubIdsByScope = new Set();
  for (const categoryId of effectiveCategoryIds) {
    const subMeta = catalog.subcategoriesByCategoryId.get(categoryId);
    if (subMeta) {
      for (const subId of subMeta.subIdSet) {
        validSubIdsByScope.add(subId);
      }
    }
  }

  for (const subValue of selectedSubs) {
    const isValidId = catalog.subcategoryIdsGlobal.has(subValue);
    const isInScope = validSubIdsByScope.has(subValue);

    if (!isValidId) {
      errors.push({
        type: 'invalid_subcategory',
        value: subValue,
        message: `Subcategory "${subValue}" is not found in catalog at path ${documentPath}`,
        severity: 'error',
      });
    } else if (!isInScope && effectiveCategoryIds.length > 0) {
      errors.push({
        type: 'subcategory_out_of_scope',
        value: subValue,
        message: `Subcategory "${subValue}" exists in catalog but is out of scope for selected categories at path ${documentPath}`,
        severity: 'warning',
      });
    }
  }

  const valid = errors.filter((e) => e.severity === 'error').length === 0;
  return { valid, errors };
}

module.exports = {
  validateCategoriesCatalogConsistency,
};
