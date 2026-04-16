'use strict';
require('dotenv').config();
const admin = require('firebase-admin');
const { FieldValue } = require('firebase-admin/firestore');
const { haversineDistance, formatDistance } = require('./helpers/haversine');
const { sendMessage } = require('./helpers/telegramHelper');
const { writeAuditLog, getAvailableVolunteers } = require('./helpers/firestoreHelper');

function buildDispatchMessage(task, volunteer, distance) {
  const urgencyLabel = task.urgency >= 4 ? '🚨 URGENT TASK' : '📋 TASK AVAILABLE';
  const urgencyFooter = task.urgency >= 4
    ? '⏱ This request expires in 10 minutes.'
    : 'No rush — available for 24 hours.';

  return `${urgencyLabel} — Urgency ${task.urgency}/5
📍 ${task.location_text}
🏷 ${task.need_type.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
👥 ${task.estimated_people_affected ? task.estimated_people_affected + ' residents' : 'Residents'} — ${task.brief_description}
🔧 Skills needed: ${task.skills_required.join(', ')}
📏 Distance: ${distance}
👤 ${task.count_needed} volunteer${task.count_needed > 1 ? 's' : ''} needed

Reply *YES* to accept
Reply *NO* to decline

${urgencyFooter}`;
}

async function dispatchVolunteers(taskId, task) {
  const db = admin.firestore();

  // Step 1: Get available volunteers with matching skills
  let candidates = await getAvailableVolunteers(task.skills_required);

  if (candidates.length === 0) {
    // No volunteers at all — notify coordinator
    const coordinatorId = process.env.NGO_COORDINATOR_TELEGRAM_ID;
    if (coordinatorId) {
      await sendMessage(coordinatorId,
        `⚠️ No volunteers available for task:\n📍 ${task.location_text}\n🏷 ${task.need_type}\n\nManual assignment needed. Check dashboard.`
      );
    }
    await writeAuditLog(taskId, 'dispatch_failed_no_volunteers', 'system', 'system', {});
    return;
  }

  // Step 2: Sort by distance if task has coordinates
  if (task.location_lat && task.location_lng) {
    candidates.sort((a, b) => {
      const distA = (a.location_lat && a.location_lng)
        ? haversineDistance(task.location_lat, task.location_lng, a.location_lat, a.location_lng)
        : 999;
      const distB = (b.location_lat && b.location_lng)
        ? haversineDistance(task.location_lat, task.location_lng, b.location_lat, b.location_lng)
        : 999;
      return distA - distB;
    });
  } else {
    // Sort by completed tasks (most experienced first)
    candidates.sort((a, b) => (b.completed_tasks_count || 0) - (a.completed_tasks_count || 0));
  }

  // Step 3: Select top candidates (count_needed + 2 backup, max 5)
  const numToNotify = Math.min(task.count_needed + 2, 5);
  const selected = candidates.slice(0, numToNotify);

  // Step 4: Send dispatch messages
  const dispatchedIds = [];
  for (const vol of selected) {
    const distance = (task.location_lat && task.location_lng && vol.location_lat && vol.location_lng)
      ? formatDistance(task.location_lat, task.location_lng, vol.location_lat, vol.location_lng)
      : vol.area_name ? `~${vol.area_name}` : '~nearby';

    await sendMessage(vol.telegram_id, buildDispatchMessage(task, vol, distance));
    dispatchedIds.push(vol.telegram_id);
    await writeAuditLog(taskId, 'volunteer_dispatched', vol.telegram_id, 'system', {
      volunteer_name: vol.name,
    });
  }

  // Step 5: Update task
  const now = FieldValue.serverTimestamp();
  await db.collection('tasks').doc(taskId).update({
    status: 'dispatching',
    dispatched_to: dispatchedIds,
    dispatched_at: now,
    updated_at: now,
  });

  console.log(`Dispatched task ${taskId} to ${dispatchedIds.length} volunteers`);
}

// Dispatch next candidate after a NO reply
async function dispatchNextCandidate(taskId, declinedTelegramId) {
  const db = admin.firestore();
  const taskSnap = await db.collection('tasks').doc(taskId).get();
  if (!taskSnap.exists) return;

  const task = taskSnap.data();
  if (task.status === 'assigned' || task.status === 'completed' || task.status === 'cancelled') return;

  // Get all available skill-matched volunteers NOT already notified
  let candidates = await getAvailableVolunteers(task.skills_required);
  const alreadyNotified = task.dispatched_to || [];
  candidates = candidates.filter(v => !alreadyNotified.includes(v.telegram_id));

  if (candidates.length === 0) {
    // No more candidates — notify coordinator
    const coordinatorId = process.env.NGO_COORDINATOR_TELEGRAM_ID;
    if (coordinatorId) {
      await sendMessage(coordinatorId,
        `⚠️ No nearby volunteers found for ${task.location_text} (${task.need_type}).\nManual assignment needed.`
      );
    }
    return;
  }

  // Sort and pick next
  if (task.location_lat && task.location_lng) {
    candidates.sort((a, b) => {
      const distA = (a.location_lat && a.location_lng)
        ? haversineDistance(task.location_lat, task.location_lng, a.location_lat, a.location_lng) : 999;
      const distB = (b.location_lat && b.location_lng)
        ? haversineDistance(task.location_lat, task.location_lng, b.location_lat, b.location_lng) : 999;
      return distA - distB;
    });
  }

  const next = candidates[0];
  const distance = (task.location_lat && next.location_lat)
    ? formatDistance(task.location_lat, task.location_lng, next.location_lat, next.location_lng)
    : '~nearby';

  await sendMessage(next.telegram_id, buildDispatchMessage(task, next, distance));
  await db.collection('tasks').doc(taskId).update({
    dispatched_to: FieldValue.arrayUnion(next.telegram_id),
    updated_at: FieldValue.serverTimestamp(),
  });
  await writeAuditLog(taskId, 'volunteer_dispatched', next.telegram_id, 'system', {
    reason: 'previous_declined',
  });
}

// Check for dispatch timeouts (call periodically)
async function checkDispatchTimeouts() {
  const db = admin.firestore();
  const thirtyMinAgo = new Date(Date.now() - 30 * 60 * 1000);

  const snap = await db.collection('tasks')
    .where('status', '==', 'dispatching')
    .where('dispatched_at', '<', thirtyMinAgo)
    .get();

  let count = 0;
  for (const doc of snap.docs) {
    const task = doc.data();
    const coordinatorId = process.env.NGO_COORDINATOR_TELEGRAM_ID;
    if (coordinatorId) {
      await sendMessage(coordinatorId,
        `⏰ No volunteer accepted for "${task.location_text}" (${task.need_type}) in 30 minutes.\nManual assignment needed. Check dashboard.`
      );
    }
    await db.collection('tasks').doc(doc.id).update({
      dispatch_timeout: true,
      updated_at: FieldValue.serverTimestamp(),
    });
    count++;
  }

  return { timeoutsFound: count };
}

module.exports = { dispatchVolunteers, dispatchNextCandidate, checkDispatchTimeouts };
