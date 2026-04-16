'use strict';
const admin = require('firebase-admin');
const { FieldValue } = require('firebase-admin/firestore');
const { sendMessage } = require('./helpers/telegramHelper');
const { writeAuditLog } = require('./helpers/firestoreHelper');

async function handleDone(chatId, telegramId, volunteer) {
  const db = admin.firestore();
  const taskId = volunteer.active_task_id;

  if (!taskId) {
    await sendMessage(chatId, 'You have no active task to mark as done.');
    return;
  }

  const taskSnap = await db.collection('tasks').doc(taskId).get();
  if (!taskSnap.exists) {
    await sendMessage(chatId, 'Task not found. Please contact your coordinator.');
    return;
  }

  const task = taskSnap.data();
  const now = FieldValue.serverTimestamp();
  const nowMs = Date.now();

  // Calculate time_to_dispatch_seconds
  let timeToDispatch = null;
  if (task.created_at && task.dispatched_at) {
    const createdMs = task.created_at.toMillis ? task.created_at.toMillis() : 0;
    const dispatchedMs = task.dispatched_at.toMillis ? task.dispatched_at.toMillis() : 0;
    timeToDispatch = Math.round((dispatchedMs - createdMs) / 1000);
  }

  // Update task
  await db.collection('tasks').doc(taskId).update({
    status: 'completed',
    completed_at: now,
    time_to_dispatch_seconds: timeToDispatch,
    updated_at: now,
  });

  // Update volunteer
  await db.collection('volunteers').doc(volunteer.volunteer_id).update({
    available: true,
    active_task_id: null,
    completed_tasks_count: FieldValue.increment(1),
    last_active: now,
  });

  // Write audit log
  await writeAuditLog(taskId, 'task_completed', telegramId, 'volunteer', {
    volunteer_name: volunteer.name,
  });

  // Thank the volunteer
  const newCount = (volunteer.completed_tasks_count || 0) + 1;
  await sendMessage(chatId,
    `✅ Task marked complete. Thank you! 🙏\n\nTotal tasks completed: ${newCount}`
  );

  // Notify the field worker who submitted the report
  if (task.source_ngo_user) {
    await sendMessage(task.source_ngo_user,
      `✅ Update: Volunteers have reached ${task.location_text}.\nTask marked complete.\n\nThank you for reporting! 🙏`
    );
  }

  // Notify coordinator
  const coordinatorId = process.env.NGO_COORDINATOR_TELEGRAM_ID;
  if (coordinatorId) {
    await sendMessage(coordinatorId,
      `✅ Task completed: ${task.location_text} (${task.need_type})\nBy: ${volunteer.name}`
    );
  }
}

module.exports = { handleDone };