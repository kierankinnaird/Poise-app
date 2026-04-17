// Run with: node seed-demo.js <orgId>
// Seeds 6 demo clients: 1 perfect, 1 all faults, 4 random. 5+ screens each.

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db = admin.firestore();

const ORG_ID = process.argv[2];
if (!ORG_ID) {
    console.error('Usage: node seed-demo.js <orgId>');
    process.exit(1);
}

const ALL_FAULT_TYPES = [
    'kneeCave', 'depth', 'forwardLean', 'heelRise',
    'hipDrop', 'excessiveSway', 'limitedRotation', 'excessiveKneeBend',
];
const SEVERITIES = ['mild', 'moderate', 'severe'];
const SIDES = [null, 'left', 'right'];

const CLIENTS = [
    { uid: 'seed-client-001', name: 'Jamie Walsh',   mode: 'perfect' },
    { uid: 'seed-client-002', name: 'Sam Okafor',    mode: 'all_faults' },
    { uid: 'seed-client-003', name: 'Ellie Marsh',   mode: 'random' },
    { uid: 'seed-client-004', name: 'Marcus Reid',   mode: 'random' },
    { uid: 'seed-client-005', name: 'Priya Nair',    mode: 'random' },
    { uid: 'seed-client-006', name: 'Connor Hughes', mode: 'random' },
];

function randomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomItem(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
}

function generateFaults(mode) {
    if (mode === 'perfect') return [];

    if (mode === 'all_faults') {
        return ALL_FAULT_TYPES.map(type => ({
            type,
            severity: randomItem(SEVERITIES),
            side: randomItem(SIDES),
            name: type,
        }));
    }

    // Random: 1-4 faults
    const count = randomInt(1, 4);
    const picked = [...ALL_FAULT_TYPES].sort(() => 0.5 - Math.random()).slice(0, count);
    return picked.map(type => ({
        type,
        severity: randomItem(SEVERITIES),
        side: randomItem(SIDES),
        name: type,
    }));
}

function calcScore(faults) {
    const penalty = { mild: 3, moderate: 7, severe: 14 };
    const total = faults.reduce((acc, f) => acc + (penalty[f.severity] || 5), 0);
    return Math.max(20, Math.min(100, 100 - total));
}

function generateScreens(count, mode) {
    const now = Date.now();
    return Array.from({ length: count }, (_, i) => {
        const faults = generateFaults(mode);
        return {
            sport: 'Football',
            goal: 'Injury prevention',
            movementType: 'fullScreen',
            score: calcScore(faults),
            faults,
            repCount: 0,
            completedAt: admin.firestore.Timestamp.fromMillis(
                now - (count - 1 - i) * 14 * 24 * 60 * 60 * 1000
            ),
        };
    });
}

async function seed() {
    console.log(`Seeding ${CLIENTS.length} clients into org ${ORG_ID}...`);

    for (const client of CLIENTS) {
        const screenCount = randomInt(5, 7);
        const screens = generateScreens(screenCount, client.mode);
        const latest = screens[screens.length - 1];

        await db.collection('users').doc(client.uid).set({
            uid: client.uid,
            name: client.name,
            email: `${client.uid}@seed.test`,
            sport: 'Football',
            goal: 'Injury prevention',
            isPro: true,
            orgId: ORG_ID,
            prehabLocked: true,
            createdAt: admin.firestore.Timestamp.now(),
        });

        for (const screen of screens) {
            await db.collection('users').doc(client.uid).collection('screens').add(screen);
        }

        await db.collection('organisations').doc(ORG_ID)
            .collection('members').doc(client.uid).set({
                uid: client.uid,
                displayName: client.name,
                joinedAt: admin.firestore.Timestamp.now(),
            });

        console.log(`  ${client.name} (${client.mode}): ${screens.length} screens, latest score ${latest.score}`);
    }

    console.log('Done.');
    process.exit(0);
}

seed().catch(err => { console.error(err); process.exit(1); });
