const admin = require('firebase-admin');

async function main() {
  if (admin.apps.length === 0) {
    admin.initializeApp({
      projectId: 'saneapp-clean',
    });
  }

  const firestore = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 1000 * 60 * 60 * 24 * 30),
  );

  const coupons = [
    {
      id: 'welcome_generator_15',
      title: 'Bienvenida para nuevos compradores',
      description:
        'Beneficio comercial para generadores que publiquen su primera necesidad ambiental dentro del marketplace.',
      code: 'SANE15',
      discountLabel: '15% en primera gestión',
      audienceLabel: 'Compradores nuevos',
      priority: 100,
      isActive: true,
      expiresAt,
      createdAt: now,
      updatedAt: now,
    },
    {
      id: 'provider_boost_q2',
      title: 'Impulso comercial para vendedores',
      description:
        'Visibilidad preferencial para proveedores que completen perfil y publiquen una nueva oferta activa.',
      code: 'PROBOOST',
      discountLabel: 'Destacado comercial',
      audienceLabel: 'Vendedores',
      priority: 80,
      isActive: true,
      expiresAt,
      createdAt: now,
      updatedAt: now,
    },
    {
      id: 'official_companies_bonus',
      title: 'Bono para empresas oficiales',
      description:
        'Campaña para operadores validados con cierres recurrentes y métricas comerciales destacadas.',
      code: 'OFICIAL10',
      discountLabel: 'Bono oficial',
      audienceLabel: 'Empresas oficiales',
      priority: 60,
      isActive: true,
      expiresAt,
      createdAt: now,
      updatedAt: now,
    },
  ];

  const ratings = [
    {
      id: 'seed_rating_generator_to_provider',
      serviceId: 'seed-service-001',
      fromUserId: 'seed-generator-user',
      toUserId: 'seed-provider-user',
      role: 'client_to_provider',
      stars: 5,
      comment:
        'La operación fue puntual, ordenada y con evidencia completa de cierre.',
      createdAt: now,
    },
    {
      id: 'seed_rating_provider_to_generator',
      serviceId: 'seed-service-001',
      fromUserId: 'seed-provider-user',
      toUserId: 'seed-generator-user',
      role: 'provider_to_client',
      stars: 4,
      comment:
        'El alcance llegó claro y la coordinación comercial permitió cerrar sin reprocesos.',
      createdAt: now,
    },
  ];

  const batch = firestore.batch();

  for (const coupon of coupons) {
    const { id, ...data } = coupon;
    batch.set(firestore.collection('marketplace_coupons').doc(id), data, {
      merge: true,
    });
  }

  for (const rating of ratings) {
    const { id, ...data } = rating;
    batch.set(firestore.collection('ratings').doc(id), data, { merge: true });
  }

  await batch.commit();
  console.log(
    `Seed completado: ${coupons.length} cupones y ${ratings.length} opiniones.`,
  );
}

main().catch((error) => {
  console.error('No fue posible sembrar Firestore:', error);
  process.exitCode = 1;
});