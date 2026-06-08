// Backfill new UserModel fields onto existing `users` docs.
// Idempotent: only fills MISSING fields; never overwrites existing role/aura.
//
//   cd tools/seed
//   npm init -y && npm i firebase-admin
//   # download a service-account key -> serviceAccountKey.json (git-ignored)
//   node backfill_users.js          # dry run (prints planned changes)
//   node backfill_users.js --apply  # write changes
//
// Promote specific people to a role by email (edit PROMOTIONS).

const admin = require('firebase-admin');
admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json')),
});
const db = admin.firestore();

const APPLY = process.argv.includes('--apply');

// email -> role. Roles: 'intern' | 'fullTime' | 'mentor' | 'admin'
const PROMOTIONS = {
  // 'aida@aprd.dev': 'mentor',
  // 'damir@aprd.dev': 'admin',
};

// Defaults for fields added after these docs were created.
const DEFAULTS = {
  role: 'intern',
  position: '',
  currentWeekAura: 0,
  totalAura: 0,
  schemaVersion: 1,
  metadata: {},
};

async function main() {
  const snap = await db.collection('users').get();
  let batch = db.batch();
  let pending = 0;
  let changed = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const updates = {};

    // Fill only missing fields.
    for (const [k, v] of Object.entries(DEFAULTS)) {
      if (data[k] === undefined) updates[k] = v;
    }

    // Promotion overrides role explicitly (always applied if listed).
    const role = PROMOTIONS[data.email];
    if (role && data.role !== role) updates.role = role;

    if (Object.keys(updates).length === 0) continue;

    changed++;
    console.log(`${doc.id} (${data.email || '—'}):`, updates);

    if (APPLY) {
      batch.set(doc.ref, updates, { merge: true });
      if (++pending >= 450) {
        await batch.commit();
        batch = db.batch();
        pending = 0;
      }
    }
  }

  if (APPLY && pending > 0) await batch.commit();
  console.log(
    `\n${changed} doc(s) ${APPLY ? 'updated' : 'would change'} of ${snap.size}.` +
      (APPLY ? '' : '  Re-run with --apply to write.')
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
