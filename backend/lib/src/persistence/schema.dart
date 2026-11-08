/// Ma'lumotlar bazasi sxemasi. Har bir migratsiya bir marta, tartib bilan
/// qo'llanadi (`schema_migrations`). Mavjud migratsiyani o'zgartirmang —
/// yangisini qo'shing.
///
/// Tamoyil: qidiruv va bog'lanish uchun kerakli ustunlar alohida (indeks,
/// foreign key), qolgan maydonlar `data JSONB` da. Tibbiy maydonlar ilova
/// darajasida AES-256-GCM bilan shifrlangan holda keladi (bazada ochiq
/// matn yo'q).
const migrations = <String>[
  // 1 — boshlang'ich sxema
  '''
CREATE TABLE users (
  id          TEXT PRIMARY KEY,
  phone_hash  TEXT NOT NULL UNIQUE,
  role        TEXT NOT NULL CHECK (role IN ('patient','doctor','admin')),
  data        JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Rozilik tarixi: faqat qo'shiladi (o'chirilmaydi, o'zgartirilmaydi).
CREATE TABLE consents (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id),
  scope       TEXT NOT NULL,
  version     TEXT NOT NULL,
  granted     BOOLEAN NOT NULL,
  at          TIMESTAMPTZ NOT NULL,
  data        JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX consents_user ON consents(user_id, at);

CREATE TABLE medical_profiles (
  id          TEXT PRIMARY KEY REFERENCES users(id),
  data        JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE triage_results (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id),
  at          TIMESTAMPTZ NOT NULL,
  data        JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX triage_user ON triage_results(user_id, at);

-- user_id'ga foreign key yo'q: demo shifokorlar (dev) foydalanuvchisiz.
CREATE TABLE doctors (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL,
  status      TEXT NOT NULL,
  specialty   TEXT NOT NULL,
  data        JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX doctors_user ON doctors(user_id);
CREATE INDEX doctors_search ON doctors(status, specialty);

CREATE TABLE appointments (
  id          TEXT PRIMARY KEY,
  patient_id  TEXT NOT NULL REFERENCES users(id),
  doctor_id   TEXT NOT NULL REFERENCES doctors(id),
  starts_at   TIMESTAMPTZ NOT NULL,
  status      TEXT NOT NULL,
  data        JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX appointments_patient ON appointments(patient_id, starts_at);
CREATE INDEX appointments_doctor ON appointments(doctor_id, starts_at);

CREATE TABLE payment_orders (
  id              TEXT PRIMARY KEY,
  appointment_id  TEXT NOT NULL REFERENCES appointments(id),
  user_id         TEXT NOT NULL REFERENCES users(id),
  status          TEXT NOT NULL,
  data            JSONB NOT NULL,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX payment_orders_appointment ON payment_orders(appointment_id);

-- Click: click_trans_id -> merchant_prepare_id
CREATE TABLE click_prepared (
  id          TEXT PRIMARY KEY,
  data        JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Payme tranzaksiyalari (id = Payme tranzaksiya ID'si).
CREATE TABLE payme_transactions (
  id          TEXT PRIMARY KEY,
  order_id    TEXT NOT NULL REFERENCES payment_orders(id),
  data        JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX payme_order ON payme_transactions(order_id);

CREATE TABLE chat_messages (
  id              TEXT PRIMARY KEY,
  appointment_id  TEXT NOT NULL REFERENCES appointments(id),
  seq             INTEGER NOT NULL,
  data            JSONB NOT NULL,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (appointment_id, seq)
);

-- id = FCM FID
CREATE TABLE devices (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id),
  data        JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX devices_user ON devices(user_id);

-- Audit jurnali: faqat qo'shiladi. Ilova roliga UPDATE/DELETE berilmasin.
CREATE TABLE audit_log (
  id           BIGSERIAL PRIMARY KEY,
  actor_id     TEXT NOT NULL,
  action       TEXT NOT NULL,
  resource     TEXT NOT NULL,
  resource_id  TEXT,
  outcome      TEXT NOT NULL,
  at           TIMESTAMPTZ NOT NULL
);
CREATE INDEX audit_actor ON audit_log(actor_id, at);
''',
  // 2 — chat fayllari (shifrlangan, xotiraga yuklanmaydi)
  '''
CREATE TABLE attachments (
  id              TEXT PRIMARY KEY,
  appointment_id  TEXT NOT NULL REFERENCES appointments(id),
  uploader_id     TEXT NOT NULL REFERENCES users(id),
  name            TEXT NOT NULL,
  mime            TEXT NOT NULL,
  size            INTEGER NOT NULL,
  content         TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX attachments_appointment ON attachments(appointment_id);
''',
];

/// Ishga tushirish tartibi (foreign key'lar uchun): ota jadvallar oldin.
const tableOrder = [
  'users',
  'consents',
  'medical_profiles',
  'triage_results',
  'doctors',
  'appointments',
  'payment_orders',
  'click_prepared',
  'payme_transactions',
  'chat_messages',
  'devices',
];
