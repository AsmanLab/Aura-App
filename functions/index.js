// Cloud Functions for Aura — push a notification when someone awards aura.
// Trigger: a new doc in `aura_transactions`. See commands/09_push_notifications.md.
//
//   cd functions && npm install
//   firebase deploy --only functions
//
// Requires the Blaze (pay-as-you-go) plan for v2 functions.

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

exports.onAuraAwarded = onDocumentCreated(
  'aura_transactions/{id}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const t = snap.data();
    if (!t || !t.toUserId) return;
    if (t.fromUserId === t.toUserId) return; // never notify the sender

    const db = getFirestore();
    const userRef = db.collection('users').doc(t.toUserId);
    const user = (await userRef.get()).data() || {};

    // Respect a per-category preference if the user set one.
    if (user.notifPrefs && user.notifPrefs.aura === false) return;

    const tokens = Array.isArray(user.fcmTokens) ? user.fcmTokens : [];
    if (tokens.length === 0) return;

    const sign = t.points >= 0 ? '+' : '';
    const body =
      `${t.fromName || 'Someone'} gave you aura` +
      (t.comment ? `: ${t.comment}` : '');

    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: `${sign}${t.points} Aura`, body },
      data: { route: '/aura/profile', txnId: event.params.id },
      apns: { payload: { aps: { sound: 'default' } } },
      android: { notification: { channelId: 'aura' } },
    });

    // Prune tokens FCM reports as dead so we don't keep sending to them.
    const invalid = [];
    res.responses.forEach((r, i) => {
      const code = r.error && r.error.code;
      if (
        !r.success &&
        (code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-argument')
      ) {
        invalid.push(tokens[i]);
      }
    });
    if (invalid.length > 0) {
      await userRef.update({ fcmTokens: FieldValue.arrayRemove(...invalid) });
    }
  }
);
