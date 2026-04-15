const admin = require('firebase-admin');

function db() {
  return admin.firestore();
}

// Write a new task document
async function createTask(taskData) {
  const ref = db().collection('tasks').doc();
  const task = {
    ...taskData,
    task_id: ref.id,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };
  await ref.set(task);
  return ref.id;
}

// Update fields on a task
async function updateTask(taskId, updates) {
  await db().collection('tasks').doc(taskId).update({
    ...updates,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// Get a task by ID
async function getTask(taskId) {
  const snap = await db().collection('tasks').doc(taskId).get();
  if (!snap.exists) return null;
  return { task_id: snap.id, ...snap.data() };
}

// Get volunteer by telegram_id
async function getVolunteerByTelegramId(telegramId) {
  const snap = await db()
    .collection('volunteers')
    .where('telegram_id', '==', String(telegramId))
    .limit(1)
    .get();
  if (snap.empty) return null;
  return { volunteer_id: snap.docs[0].id, ...snap.docs[0].data() };
}

// Get available volunteers with any of the required skills
async function getAvailableVolunteers(skillsRequired) {
  const snap = await db()
    .collection('volunteers')
    .where('available', '==', true)
    .get();
  
  if (snap.empty) return [];
  
  const allAvailable = snap.docs.map(d => ({ volunteer_id: d.id, ...d.data() }));
  
  if (!skillsRequired || skillsRequired.length === 0) {
    return allAvailable;
  }
  
  // Filter to skill-matched first
  const skillMatched = allAvailable.filter(v =>
    v.skills && v.skills.some(s => skillsRequired.includes(s))
  );
  
  // If none skill-matched, return all available
  return skillMatched.length > 0 ? skillMatched : allAvailable;
}

// Check for duplicate task (same location + need_type in last 6 hours)
async function findDuplicateTask(locationText, needType) {
  const sixHoursAgo = new Date(Date.now() - 6 * 60 * 60 * 1000);
  const snap = await db()
    .collection('tasks')
    .where('location_text', '==', locationText)
    .where('need_type', '==', needType)
    .where('created_at', '>', sixHoursAgo)
    .where('status', 'not-in', ['completed', 'cancelled'])
    .limit(1)
    .get();
  if (snap.empty) return null;
  return { task_id: snap.docs[0].id, ...snap.docs[0].data() };
}

// Count recent tasks from a sender (rate limiting)
async function countRecentTasksFromSender(telegramUserId) {
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
  const snap = await db()
    .collection('tasks')
    .where('source_ngo_user', '==', String(telegramUserId))
    .where('created_at', '>', oneHourAgo)
    .count()
    .get();
  return snap.data().count;
}

// Write to audit log
async function writeAuditLog(taskId, action, actorId, actorRole, details = {}) {
  await db().collection('audit_log').add({
    task_id: taskId,
    action: action,
    actor_id: String(actorId),
    actor_role: actorRole,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    details: details,
  });
}

// Get or create volunteer session (for registration flow)
async function getVolunteerSession(telegramId) {
  const ref = db().collection('volunteer_sessions').doc(String(telegramId));
  const snap = await ref.get();
  return snap.exists ? snap.data() : null;
}

async function setVolunteerSession(telegramId, data) {
  await db()
    .collection('volunteer_sessions')
    .doc(String(telegramId))
    .set(data, { merge: true });
}

async function deleteVolunteerSession(telegramId) {
  await db().collection('volunteer_sessions').doc(String(telegramId)).delete();
}

module.exports = {
  createTask,
  updateTask,
  getTask,
  getVolunteerByTelegramId,
  getAvailableVolunteers,
  findDuplicateTask,
  countRecentTasksFromSender,
  writeAuditLog,
  getVolunteerSession,
  setVolunteerSession,
  deleteVolunteerSession,
};