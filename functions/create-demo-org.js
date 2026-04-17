const admin = require('firebase-admin');
const sa = require('./service-account.json');

admin.initializeApp({ credential: admin.credential.cert(sa) });

const db = admin.firestore();

db.collection('organisations').add({
    name: 'Poise Demo Clinic',
    ownerUid: '2OT7yOMxW7UVBstJC6mD6Mq0I0g1',
    code: 'POISE-DEMO',
    tier: 'pro',
    createdAt: admin.firestore.Timestamp.now(),
}).then(ref => {
    console.log('Created org:', ref.id);
    process.exit(0);
}).catch(err => {
    console.error(err);
    process.exit(1);
});
