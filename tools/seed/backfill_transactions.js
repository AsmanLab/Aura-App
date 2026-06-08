// Backfill new AuraTransaction fields onto existing `aura_transactions` docs.
// Idempotent: only fills MISSING fields. Denormalizes giver name/photo from
// the `users` collection (cached).
//
//   cd tools/seed
//   npm init -y && npm i firebase-admin
//   # serviceAccountKey.json here (git-ignored)
//   node backfill_transactions.js          # dry run
//   node backfill_transactions.js --apply   # write

const admin = require('firebase-admin');
admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json')),
});
const db = admin.firestore();

const APPLY = process.argv.includes('--apply');

const DEFAULTS = { category: '', schemaVersion: 1 };

const userCache = new Map();
async function giver(uid) {
  if (!uid) return null;
  if (userCache.has(uid)) return userCache.get(uid);
  const doc = await db.collection('users').doc(uid).get();
  const u = doc.exists ? doc.data() : null;
  userCache.set(uid, u);
  return u;
}

async function main() {
  const snap = await db.collection('aura_transactions').get();
  let batch = db.batch();
  let pending = 0;
  let changed = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const updates = {};

    for (const [k, v] of Object.entries(DEFAULTS)) {
      if (data[k] === undefined) updates[k] = v;
    }

    // Denormalize giver fields when missing/empty.
    if (!data.fromName || data.fromPhotoURL === undefined) {
      const u = await giver(data.fromUserId);
      if (u) {
        if (!data.fromName && u.displayName) updates.fromName = u.displayName;
        if (data.fromPhotoURL === undefined) {
          updates.fromPhotoURL = u.photoURL ?? null;
        }
      }
    }

    if (Object.keys(updates).length === 0) continue;

    changed++;
    console.log(`${doc.id}:`, updates);

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
