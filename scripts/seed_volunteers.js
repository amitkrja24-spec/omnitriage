require('dotenv').config({ path: '../functions/.env' });
const admin = require('firebase-admin');
const serviceAccount = require('../functions/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: process.env.FIREBASE_PROJECT_ID,
});

const db = admin.firestore();

// 50 realistic Delhi-area volunteers
// Coordinates clustered around south Delhi
const volunteers = [
  { name: 'Priya Sharma', skills: ['nurse', 'first_aid'], area: 'Okhla Phase 2', lat: 28.5490, lng: 77.2662 },
  { name: 'Dr. Ravi Kumar', skills: ['doctor', 'first_aid'], area: 'Jasola', lat: 28.5520, lng: 77.2920 },
  { name: 'Arjun Verma', skills: ['logistics', 'driving'], area: 'Sarita Vihar', lat: 28.5387, lng: 77.2866 },
  { name: 'Meena Gupta', skills: ['teacher', 'tutoring'], area: 'Govindpuri', lat: 28.5355, lng: 77.2619 },
  { name: 'Sunita Patel', skills: ['cooking', 'social_work'], area: 'Kalkaji', lat: 28.5492, lng: 77.2568 },
  { name: 'Rahul Singh', skills: ['construction', 'sanitation'], area: 'Madanpur Khadar', lat: 28.5130, lng: 77.2780 },
  { name: 'Pooja Nair', skills: ['nurse', 'counseling'], area: 'Sangam Vihar', lat: 28.5068, lng: 77.2591 },
  { name: 'Amit Joshi', skills: ['logistics', 'general'], area: 'Okhla Phase 1', lat: 28.5430, lng: 77.2710 },
  { name: 'Kavita Rao', skills: ['teacher', 'social_work'], area: 'Tughlakabad', lat: 28.4956, lng: 77.2619 },
  { name: 'Deepak Mishra', skills: ['driving', 'rescue'], area: 'Badarpur', lat: 28.4987, lng: 77.2929 },
  { name: 'Shalini Dubey', skills: ['first_aid', 'nurse'], area: 'Sangam Vihar', lat: 28.5040, lng: 77.2550 },
  { name: 'Vinod Tiwari', skills: ['construction', 'logistics'], area: 'Okhla Phase 3', lat: 28.5550, lng: 77.2700 },
  { name: 'Anita Chauhan', skills: ['cooking', 'education'], area: 'Govindpuri', lat: 28.5310, lng: 77.2640 },
  { name: 'Suresh Yadav', skills: ['sanitation', 'general'], area: 'Kalkaji Ext.', lat: 28.5470, lng: 77.2530 },
  { name: 'Rekha Mehta', skills: ['counseling', 'social_work'], area: 'Jasola', lat: 28.5500, lng: 77.2870 },
  { name: 'Nikhil Pandey', skills: ['photography', 'general'], area: 'Sarita Vihar', lat: 28.5350, lng: 77.2900 },
  { name: 'Dr. Anjali Singh', skills: ['doctor', 'nurse'], area: 'Madanpur Khadar', lat: 28.5150, lng: 77.2820 },
  { name: 'Ramesh Sharma', skills: ['driving', 'logistics'], area: 'Okhla Phase 2', lat: 28.5480, lng: 77.2680 },
  { name: 'Geeta Kumari', skills: ['teacher', 'counseling'], area: 'Govindpuri', lat: 28.5370, lng: 77.2600 },
  { name: 'Vikram Reddy', skills: ['rescue', 'first_aid'], area: 'Sangam Vihar', lat: 28.5100, lng: 77.2620 },
  { name: 'Namrata Bose', skills: ['social_work', 'cooking'], area: 'Badarpur', lat: 28.5010, lng: 77.2950 },
  { name: 'Arun Saxena', skills: ['construction', 'driving'], area: 'Tughlakabad', lat: 28.4980, lng: 77.2580 },
  { name: 'Poonam Verma', skills: ['nurse', 'first_aid'], area: 'Kalkaji', lat: 28.5460, lng: 77.2555 },
  { name: 'Sanjay Tomar', skills: ['logistics', 'rescue'], area: 'Jasola Vihar', lat: 28.5540, lng: 77.2940 },
  { name: 'Lata Iyer', skills: ['tutoring', 'teacher'], area: 'Okhla Phase 1', lat: 28.5420, lng: 77.2730 },
  { name: 'Mohit Kapoor', skills: ['general', 'social_work'], area: 'Sarita Vihar', lat: 28.5360, lng: 77.2860 },
  { name: 'Divya Nath', skills: ['counseling', 'nurse'], area: 'Sangam Vihar', lat: 28.5055, lng: 77.2605 },
  { name: 'Prakash Dube', skills: ['sanitation', 'construction'], area: 'Madanpur Khadar', lat: 28.5190, lng: 77.2760 },
  { name: 'Savita Rawat', skills: ['cooking', 'logistics'], area: 'Govindpuri', lat: 28.5335, lng: 77.2660 },
  { name: 'Ajay Bhatt', skills: ['driving', 'rescue'], area: 'Kalkaji', lat: 28.5480, lng: 77.2540 },
  { name: 'Shobha Pillai', skills: ['teacher', 'social_work'], area: 'Badarpur', lat: 28.5000, lng: 77.2970 },
  { name: 'Rajiv Goel', skills: ['first_aid', 'general'], area: 'Okhla Phase 3', lat: 28.5560, lng: 77.2720 },
  { name: 'Uma Sharma', skills: ['nurse', 'counseling'], area: 'Tughlakabad', lat: 28.4960, lng: 77.2640 },
  { name: 'Naresh Khanna', skills: ['logistics', 'driving'], area: 'Jasola', lat: 28.5510, lng: 77.2900 },
  { name: 'Seema Jain', skills: ['education', 'tutoring'], area: 'Govindpuri', lat: 28.5345, lng: 77.2625 },
  { name: 'Dinesh Pal', skills: ['construction', 'rescue'], area: 'Sangam Vihar', lat: 28.5080, lng: 77.2575 },
  { name: 'Asha Tripathi', skills: ['social_work', 'cooking'], area: 'Kalkaji', lat: 28.5455, lng: 77.2570 },
  { name: 'Hemant Batra', skills: ['photography', 'logistics'], area: 'Sarita Vihar', lat: 28.5380, lng: 77.2880 },
  { name: 'Manjula Krishnan', skills: ['nurse', 'first_aid'], area: 'Okhla Phase 2', lat: 28.5500, lng: 77.2650 },
  { name: 'Rohan Saxena', skills: ['general', 'rescue'], area: 'Madanpur Khadar', lat: 28.5160, lng: 77.2800 },
  { name: 'Preeti Chaudhary', skills: ['teacher', 'counseling'], area: 'Govindpuri', lat: 28.5320, lng: 77.2610 },
  { name: 'Santosh Nair', skills: ['sanitation', 'general'], area: 'Badarpur', lat: 28.5020, lng: 77.2940 },
  { name: 'Kalpana Misra', skills: ['social_work', 'nurse'], area: 'Sangam Vihar', lat: 28.5090, lng: 77.2595 },
  { name: 'Vivek Shukla', skills: ['driving', 'logistics'], area: 'Jasola Vihar', lat: 28.5515, lng: 77.2930 },
  { name: 'Radha Aggarwal', skills: ['cooking', 'tutoring'], area: 'Kalkaji Ext.', lat: 28.5465, lng: 77.2515 },
  { name: 'Tarun Mehta', skills: ['construction', 'driving'], area: 'Tughlakabad', lat: 28.4970, lng: 77.2660 },
  { name: 'Sarla Devi', skills: ['first_aid', 'general'], area: 'Okhla Phase 1', lat: 28.5440, lng: 77.2750 },
  { name: 'Gaurav Pandey', skills: ['rescue', 'social_work'], area: 'Govindpuri', lat: 28.5330, lng: 77.2645 },
  { name: 'Ananya Menon', skills: ['nurse', 'doctor'], area: 'Sarita Vihar', lat: 28.5395, lng: 77.2850 },
  { name: 'Bhupinder Gill', skills: ['logistics', 'construction'], area: 'Madanpur Khadar', lat: 28.5175, lng: 77.2770 },
];

async function seed() {
  console.log('Seeding 50 volunteers...');
  const batch = db.batch();

  volunteers.forEach((v, i) => {
    const ref = db.collection('volunteers').doc();
    batch.set(ref, {
      name: v.name,
      telegram_id: `DEMO_${1000 + i}`, // Demo IDs — replace with real IDs for live testing
      phone: `98${String(7000000000 + i * 7).substring(0, 8)}`,
      skills: v.skills,
      location_lat: v.lat + (Math.random() - 0.5) * 0.005, // slight randomization
      location_lng: v.lng + (Math.random() - 0.5) * 0.005,
      area_name: v.area,
      available: Math.random() > 0.3, // 70% available
      active_task_id: null,
      completed_tasks_count: Math.floor(Math.random() * 15),
      joined_at: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000)
      ),
      last_active: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - Math.random() * 3 * 24 * 60 * 60 * 1000)
      ),
    });
  });

  await batch.commit();
  console.log('✅ 50 volunteers seeded successfully!');
  process.exit(0);
}

seed().catch(err => {
  console.error('Seed failed:', err);
  process.exit(1);
});