const admin = require('firebase-admin');

const OPEN_ASSIGNMENT_STATUSES = ['asignado', 'verificado', 'en_acompanamiento'];
const MAX_OPEN_ASSIGNMENTS_PER_SUPERVISOR = 5;
const NEARBY_CITY_MAP = {
  bogota: ['soacha', 'chia', 'cajica', 'mosquera', 'funza', 'madrid'],
  medellin: ['bello', 'itagui', 'envigado', 'sabaneta', 'copacabana', 'la estrella'],
  cali: ['yumbo', 'jamundi', 'palmira', 'candelaria'],
  barranquilla: ['soledad', 'malambo', 'puerto colombia'],
  cartagena: ['turbaco', 'arjona', 'turbana'],
  bucaramanga: ['floridablanca', 'giron', 'piedecuesta'],
  cucuta: ['villa del rosario', 'los patios'],
  pereira: ['dosquebradas', 'la virginia', 'armenia', 'manizales'],
  manizales: ['villamaria', 'pereira', 'chinchina'],
  armenia: ['calarca', 'pereira'],
};

const PAYMENT_ALLOWED_METHODS = new Set(['mercadoPago', 'payu']);
const PAYMENT_CURRENCY = 'COP';
const PAYMENT_WEBHOOK_SECRET = process.env.PAYMENT_WEBHOOK_SECRET || '';
const MP_ACCESS_TOKEN = process.env.MP_ACCESS_TOKEN || '';
const MP_SUCCESS_URL = process.env.MP_SUCCESS_URL || 'https://saneapp.co/payments/success';
const MP_PENDING_URL = process.env.MP_PENDING_URL || 'https://saneapp.co/payments/pending';
const MP_FAILURE_URL = process.env.MP_FAILURE_URL || 'https://saneapp.co/payments/failure';
const MP_WEBHOOK_URL = process.env.MP_WEBHOOK_URL || '';

const PAYU_MERCHANT_ID = process.env.PAYU_MERCHANT_ID || '';
const PAYU_ACCOUNT_ID = process.env.PAYU_ACCOUNT_ID || '';
const PAYU_API_KEY = process.env.PAYU_API_KEY || '';
const PAYU_TEST = String(process.env.PAYU_TEST || '1');
const PAYU_RESPONSE_URL = process.env.PAYU_RESPONSE_URL || 'https://saneapp.co/payments/success';
const PAYU_CONFIRMATION_URL = process.env.PAYU_CONFIRMATION_URL || '';
const COMMERCIAL_SLA_RESPONSE_HOURS = 24;

let firestoreInstance = null;

function getDb() {
  if (!firestoreInstance) {
    firestoreInstance = admin.firestore();
  }
  return firestoreInstance;
}

function resolveTimestampToDate(ts) {
  if (!ts) {
    return null;
  }
  if (typeof ts.toDate === 'function') {
    return ts.toDate();
  }
  if (typeof ts === 'number') {
    return new Date(ts);
  }
  if (ts instanceof Date) {
    return ts;
  }
  return null;
}

function shouldTrackCommercialSla(data) {
  const serviceType = String(data.serviceType || '').toLowerCase();
  return serviceType === 'comercial' || serviceType === 'comercializacion';
}

function shouldDispatch(data) {
  const status = String(data.supervisorStatus || '').toLowerCase();
  return status === 'no_asignado' || status === 'awaiting_dispatch';
}

function resolveDispatchCities(city) {
  return [city, ...(NEARBY_CITY_MAP[city] || [])];
}

function normalizeCity(value) {
  if (!value || typeof value !== 'string') {
    return null;
  }
  const normalized = value.trim().toLowerCase();
  return Object.keys(NEARBY_CITY_MAP).includes(normalized) ? normalized : null;
}

function buildSupervisorOrderCode(solicitudId, city) {
  return `SUP-${solicitudId.substring(0, 8).toUpperCase()}-${city.substring(0, 3).toUpperCase()}-${Date.now()}`;
}

function buildQueueReason(args) {
  const { sameCityCount, nearbyCount } = args || {};
  if (sameCityCount === 0 && nearbyCount === 0) {
    return 'No hay supervisores activos disponibles en la ciudad o ciudades cercanas para realizar la autoasignación.';
  }
  return `Se encontraron supervisores activos (${sameCityCount} en ciudad, ${nearbyCount} en ciudades cercanas), pero todos están saturados. Se requiere asignación manual.`;
}

async function buildCandidatesWithLoad(candidates, opts) {
  const db = getDb();
  const cityPriority = (opts && opts.cityPriority) || 0;

  return Promise.all(
    candidates.map(async (supervisor) => {
      const openAssignments = await db
        .collection('solicitudes')
        .where('supervisorId', '==', supervisor.id)
        .where('supervisorStatus', 'in', OPEN_ASSIGNMENT_STATUSES)
        .count()
        .get();

      return {
        id: supervisor.id,
        name: supervisor.name || 'Unnamed',
        city: supervisor.city,
        openAssignments: openAssignments.data().count || 0,
        cityPriority,
      };
    }),
  );
}

function sortCandidates(candidates) {
  return [...candidates].sort((left, right) => {
    if (left.cityPriority != right.cityPriority) {
      return left.cityPriority - right.cityPriority;
    }
    if (left.openAssignments != right.openAssignments) {
      return left.openAssignments - right.openAssignments;
    }
    return left.name.localeCompare(right.name, 'es');
  });
}

function verifyWebhookSignature(req) {
  if (!PAYMENT_WEBHOOK_SECRET) {
    return false;
  }
  const crypto = require('crypto');
  const signature = req.headers['x-signature'];
  if (!signature) {
    return false;
  }

  const payload = JSON.stringify(req.body || {});
  const hash = crypto
    .createHmac('sha256', PAYMENT_WEBHOOK_SECRET)
    .update(payload)
    .digest('hex');

  return hash === signature;
}

function normalizeGatewayStatus(value) {
  const norm = String(value || '').toLowerCase().trim();
  const statusMap = {
    approved: 'approved',
    success: 'approved',
    completed: 'approved',
    pending: 'pending',
    failed: 'failed',
    rejected: 'failed',
    declined: 'failed',
  };
  return statusMap[norm] || null;
}

function mapGatewayToPaymentStatus(gwStatus) {
  if (gwStatus === 'approved') {
    return 'liberado';
  }
  if (gwStatus === 'pending') {
    return 'pendiente';
  }
  if (gwStatus === 'failed') {
    return 'fallido';
  }
  return 'desconocido';
}

module.exports = {
  OPEN_ASSIGNMENT_STATUSES,
  MAX_OPEN_ASSIGNMENTS_PER_SUPERVISOR,
  NEARBY_CITY_MAP,
  PAYMENT_ALLOWED_METHODS,
  PAYMENT_CURRENCY,
  PAYMENT_WEBHOOK_SECRET,
  MP_ACCESS_TOKEN,
  MP_SUCCESS_URL,
  MP_PENDING_URL,
  MP_FAILURE_URL,
  MP_WEBHOOK_URL,
  PAYU_MERCHANT_ID,
  PAYU_ACCOUNT_ID,
  PAYU_API_KEY,
  PAYU_TEST,
  PAYU_RESPONSE_URL,
  PAYU_CONFIRMATION_URL,
  COMMERCIAL_SLA_RESPONSE_HOURS,
  getDb,
  resolveTimestampToDate,
  shouldTrackCommercialSla,
  shouldDispatch,
  resolveDispatchCities,
  normalizeCity,
  buildSupervisorOrderCode,
  buildQueueReason,
  buildCandidatesWithLoad,
  sortCandidates,
  verifyWebhookSignature,
  normalizeGatewayStatus,
  mapGatewayToPaymentStatus,
};
