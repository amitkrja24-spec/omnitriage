require('dotenv').config({ path: '../functions/.env' });
const admin = require('firebase-admin');

if (!admin.apps.length) {
  const serviceAccount = require('../functions/serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: process.env.FIREBASE_PROJECT_ID,
  });
}

const db = admin.firestore();

async function seedDemoTasks() {
  console.log('Seeding 3 demo tasks...');

  const now = admin.firestore.Timestamp.now();
  const twoHoursAgo = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 2 * 60 * 60 * 1000));
  const fiveHoursAgo = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 5 * 60 * 60 * 1000));

  // Task 1: COMPLETED — shows history
  await db.collection('tasks').add({
    ngo_id: 'asha_foundation',
    location_text: 'Block B, Okhla Phase 2',
    location_lat: 28.5490, location_lng: 77.2662,
    need_type: 'food_ration',
    urgency: 3,
    skills_required: ['logistics', 'driving'],
    count_needed: 2,
    estimated_people_affected: 45,
    confidence_score: 0.91,
    needs_review: false,
    status: 'completed',
    assigned_volunteers: ['DEMO_1000', 'DEMO_1002'],
    dispatched_to: ['DEMO_1000', 'DEMO_1002', 'DEMO_1003'],
    source_type: 'text',
    source_ngo_user: 'DEMO_FIELD_1',
    raw_input_text: '45 families in Block B have not received rations this week, need logistics support',
    created_at: fiveHoursAgo,
    updated_at: twoHoursAgo,
    dispatched_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 4.5 * 60 * 60 * 1000)),
    completed_at: twoHoursAgo,
    time_to_dispatch_seconds: 8,
    dispatch_timeout: false,
    notes: 'Resolved successfully. 45 families received rations.',
    brief_description: '45 families need weekly food ration delivery urgently.',
  });

  // Task 2: ASSIGNED — shows active dispatch
  await db.collection('tasks').add({
    ngo_id: 'asha_foundation',
    location_text: 'Govindpuri, Sector 3',
    location_lat: 28.5355, location_lng: 77.2619,
    need_type: 'education',
    urgency: 2,
    skills_required: ['teacher', 'tutoring'],
    count_needed: 1,
    estimated_people_affected: 30,
    confidence_score: 0.87,
    needs_review: false,
    status: 'assigned',
    assigned_volunteers: ['DEMO_1003'],
    dispatched_to: ['DEMO_1003', 'DEMO_1004'],
    source_type: 'voice',
    source_ngo_user: 'DEMO_FIELD_2',
    raw_input_text: '[voice note - transcribed]',
    created_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 45 * 60 * 1000)),
    updated_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 30 * 60 * 1000)),
    dispatched_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 40 * 60 * 1000)),
    completed_at: null,
    time_to_dispatch_seconds: 11,
    dispatch_timeout: false,
    notes: '',
    brief_description: '30 students waiting, school teacher absent for 3 days.',
  });

  // Task 3: OPEN HIGH URGENCY — this is the live demo task
  await db.collection('tasks').add({
    ngo_id: 'asha_foundation',
    location_text: 'Ward 12, Sangam Vihar',
    location_lat: 28.5068, location_lng: 77.2591,
    need_type: 'medical',
    urgency: 5,
    skills_required: ['nurse', 'first_aid'],
    count_needed: 2,
    estimated_people_affected: 3,
    confidence_score: 0.93,
    needs_review: false,
    status: 'open',
    assigned_volunteers: [],
    dispatched_to: [],
    source_type: 'image',
    source_ngo_user: 'DEMO_FIELD_3',
    raw_input_text: '[handwritten Hindi photo]',
    created_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3 * 60 * 1000)),
    updated_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3 * 60 * 1000)),
    dispatched_at: null,
    completed_at: null,
    time_to_dispatch_seconds: null,
    dispatch_timeout: false,
    notes: '',
    brief_description: '3 unconscious residents, contaminated water suspected.',
  });

  console.log('✅ 3 demo tasks seeded!');
  process.exit(0);
}

seedDemoTasks().catch(err => {
  console.error('Seed failed:', err);
  process.exit(1);
});