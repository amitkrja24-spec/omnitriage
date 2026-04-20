'use strict';
require('dotenv').config();
const admin = require('firebase-admin');
const { FieldValue } = require('firebase-admin/firestore');
const { extractFromText, extractFromImage, extractFromAudio } = require('./geminiService');
const { sendMessage, downloadFileAsBase64 } = require('./helpers/telegramHelper');
const {
  createTask,
  updateTask,
  findDuplicateTask,
  countRecentTasksFromSender,
  writeAuditLog,
  getVolunteerByTelegramId,
  getVolunteerSession,
  setVolunteerSession,
  deleteVolunteerSession,
} = require('./helpers/firestoreHelper');

// ── BOT COPY — all message strings ────────────────────────────────

const MSG_START = `🙏 Namaste! I'm OmniTriage.

Tell me what's happening in your area. You can:
📷 Send a *photo* of your paper register or survey form
🎤 Send a *voice note* in Hindi, Hinglish, or English
✏️ Just *type* what you're seeing

I'll handle the rest — no forms, no apps.

Type /help for more info.`;

const MSG_HELP_FIELD = `*OmniTriage Field Bot*

How to report:
- 📷 *Photo*: Take a clear photo of your paper form or survey
- 🎤 *Voice note*: Record in Hindi, Hinglish, or English
- ✏️ *Text*: Type what you see in any language

Commands:
/status — Check your last report
/cancel — Cancel your last report
/help — Show this message`;

const MSG_PROCESSING = `⏳ Got it. Reading your report...
(This takes about 3–5 seconds)`;

const MSG_FILE_TOO_LARGE = `😔 That file is too large (over 5MB).

Try:
- Taking a photo at lower resolution
- Sending a voice note instead
- Typing a short description

Example: "3 log beemar hain Ward 4 mein, nurse chahiye"`;

const MSG_ERROR = `😔 Sorry, I couldn't read that clearly.

Try:
- Taking the photo in better light
- Sending a voice note instead
- Typing a short description

Example: "3 log beemar hain Ward 4 mein, nurse chahiye"`;

const MSG_RATE_LIMIT = `You've sent 10 reports in the last hour. Please wait before sending more.

Type /status to check your last report.`;

function buildSuccessMessage(extracted, taskId) {
  const urgencyLabel = ['', '1/5 — Routine', '2/5 — Low', '3/5 — Moderate', '4/5 — High', '5/5 — Critical'];
  return `✅ Report logged successfully.

📍 Location: ${extracted.location || 'Not specified'}
🏷 Need: ${extracted.need_type.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
🚨 Urgency: ${urgencyLabel[extracted.urgency] || extracted.urgency + '/5'}
👥 Volunteers needed: ${extracted.count_needed}

Dispatching nearest available volunteers now.

Reply /status to track this report.`;
}

function buildLowConfidenceMessage(extracted) {
  return `⚠️ I wasn't fully sure about some details.

What I understood:
📍 Location: ${extracted.location || 'unclear'}
🏷 Need: ${extracted.need_type || 'unclear'}
🚨 Urgency: ${extracted.urgency || '?'}/5

A coordinator has been notified to review this.
Your report is safe and will be acted on.

Reply /help if you need to resend.`;
}

// ── VOLUNTEER REGISTRATION FLOW ───────────────────────────────────

const SKILL_LIST = [
  'nurse', 'doctor', 'first_aid', 'logistics', 'driving',
  'teacher', 'tutoring', 'construction', 'sanitation',
  'social_work', 'cooking', 'counseling', 'rescue', 'photography', 'general'
];

function buildSkillsMenu() {
  let menu = 'Select your skills (reply with numbers separated by commas):\n\n';
  SKILL_LIST.forEach((skill, i) => {
    // Replace underscores with spaces so Telegram doesn't crash
    menu += `${i + 1}. ${skill.replace(/_/g, ' ')}\n`; 
  });
  menu += '\nExample: "1,3" for nurse, first aid';
  return menu;
}
async function handleRegistration(chatId, telegramId, messageText) {
  const session = await getVolunteerSession(telegramId);
  
  if (!session) {
    // Start registration
    await setVolunteerSession(telegramId, { step: 1 });
    await sendMessage(chatId, '👋 Welcome, volunteer!\n\nTo receive task alerts, I need a few details.\n\nWhat\'s your name?');
    return;
  }

  if (session.step === 1) {
    // Received name
    await setVolunteerSession(telegramId, { step: 2, temp_name: messageText.trim() });
    await sendMessage(chatId, `Nice to meet you, ${messageText.trim()}! 👋\n\nWhat area or locality are you based in?\n(e.g., Okhla Phase 2, Sangam Vihar, Jasola)`);
    return;
  }

  if (session.step === 2) {
    // Received area
    await setVolunteerSession(telegramId, { step: 3, temp_area: messageText.trim() });
    await sendMessage(chatId, buildSkillsMenu());
    return;
  }

  if (session.step === 3) {
    // Received skills
    const nums = messageText.split(',').map(n => parseInt(n.trim()) - 1).filter(n => n >= 0 && n < SKILL_LIST.length);
    const selectedSkills = nums.map(i => SKILL_LIST[i]);
    if (selectedSkills.length === 0) {
      await sendMessage(chatId, 'Please enter valid numbers from the list. Example: "1,3,5"');
      return;
    }

    // Create volunteer document
    const db = admin.firestore();
    await db.collection('volunteers').add({
      name: session.temp_name,
      telegram_id: String(telegramId),
      phone: '',
      skills: selectedSkills,
      location_lat: null,
      location_lng: null,
      area_name: session.temp_area,
      available: true,
      active_task_id: null,
      completed_tasks_count: 0,
      joined_at: FieldValue.serverTimestamp(),
      last_active: FieldValue.serverTimestamp(),
    });

    await deleteVolunteerSession(telegramId);

    await sendMessage(chatId,
      `✅ You're registered!\n\nName: ${session.temp_name}\nArea: ${session.temp_area}\nSkills: ${selectedSkills.join(', ')}\nStatus: Available ✅\n\nYou'll receive task alerts when there's a need in your area.\n\nReply /available or /busy to update your status anytime.`
    );
    return;
  }
}

// ── VOLUNTEER COMMAND HANDLERS ─────────────────────────────────────

async function handleVolunteerCommand(chatId, telegramId, text, volunteer) {
  const db = admin.firestore();
  const cmd = text.toUpperCase().trim();

  if (cmd === '/AVAILABLE') {
    await db.collection('volunteers').doc(volunteer.volunteer_id).update({ available: true });
    await sendMessage(chatId, "You're now active — ready to receive tasks. ✅");
    return true;
  }

  if (cmd === '/BUSY') {
    await db.collection('volunteers').doc(volunteer.volunteer_id).update({ available: false });
    await sendMessage(chatId, "Got it. We won't send you tasks while you're busy. 🙏");
    return true;
  }

  if (cmd === '/MYTASKS') {
    if (volunteer.active_task_id) {
      const taskSnap = await db.collection('tasks').doc(volunteer.active_task_id).get();
      if (taskSnap.exists) {
        const t = taskSnap.data();
        await sendMessage(chatId, `📋 Your active task:\n📍 ${t.location_text}\n🏷 ${t.need_type}\n🚨 Urgency: ${t.urgency}/5\n\nReply DONE when complete.`);
      } else {
        await sendMessage(chatId, 'No active task found.');
      }
    } else {
      await sendMessage(chatId, 'You have no active tasks right now.');
    }
    return true;
  }

  if (cmd === '/DONE' || cmd === 'DONE') {
    if (volunteer.active_task_id) {
      const { handleDone } = require('./completeTask');
      await handleDone(chatId, telegramId, volunteer);
    } else {
      await sendMessage(chatId, 'You have no active task to mark as done.');
    }
    return true;
  }

  if (cmd === 'ARRIVED') {
    if (volunteer.active_task_id) {
      await db.collection('tasks').doc(volunteer.active_task_id).update({
        [`volunteer_arrivals.${telegramId}`]: FieldValue.serverTimestamp(),
      });
      await sendMessage(chatId, '✅ Arrival noted! Thank you for being there. 🙏\n\nReply DONE when the task is complete.');
    } else {
      await sendMessage(chatId, 'You have no active task. This might be an old message.');
    }
    return true;
  }

  if (cmd === '/HELP') {
    await sendMessage(chatId, `*Volunteer Commands:*\n\n/available — Ready to receive tasks\n/busy — Pause task alerts\n/mytasks — View your active task\n/done — Mark current task complete\n\nReplies:\n*YES* — Accept a task\n*NO* — Decline a task\n*ARRIVED* — Confirm you've reached the location\n*DONE* — Mark task complete`);
    return true;
  }

  return false; // not a recognized volunteer command
}

// ── YES/NO HANDLERS ────────────────────────────────────────────────

async function handleYes(chatId, telegramId, volunteer) {
  const db = admin.firestore();
  
  // Find task where this volunteer is in dispatched_to
  const snap = await db.collection('tasks')
    .where('dispatched_to', 'array-contains', String(telegramId))
    .where('status', 'in', ['dispatching', 'open'])
    .limit(1)
    .get();

  if (snap.empty) {
    await sendMessage(chatId, 'Thank you for responding! This task has already been filled.\nWe\'ll notify you for the next one. 🙏');
    return;
  }

  const taskDoc = snap.docs[0];
  const task = taskDoc.data();
  const taskId = taskDoc.id;

  // Check if quota already met
  const currentAssigned = task.assigned_volunteers ? task.assigned_volunteers.length : 0;
  if (currentAssigned >= task.count_needed) {
    await sendMessage(chatId, 'Thank you for responding! This task has already been filled.\nWe\'ll notify you for the next one. 🙏');
    return;
  }

  // Assign this volunteer
  const newAssigned = [...(task.assigned_volunteers || []), String(telegramId)];
  const newStatus = newAssigned.length >= task.count_needed ? 'assigned' : 'dispatching';

  await db.collection('tasks').doc(taskId).update({
    assigned_volunteers: newAssigned,
    status: newStatus,
    updated_at: FieldValue.serverTimestamp(),
  });

  // Update volunteer
  await db.collection('volunteers').doc(volunteer.volunteer_id).update({
    available: false,
    active_task_id: taskId,
    last_active: FieldValue.serverTimestamp(),
  });

  // Confirmation to volunteer
  const arriveTime = new Date(Date.now() + 30 * 60 * 1000);
  const timeStr = arriveTime.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });
  await sendMessage(chatId,
    `✅ You're confirmed!\n\nTask: ${task.brief_description || task.need_type}, ${task.location_text}\nPlease report by: ${timeStr}\n\nWhen you arrive, reply ARRIVED\nWhen done, reply DONE\n\nThank you! 🙏`
  );

  // Write audit log
  await writeAuditLog(taskId, 'volunteer_accepted', telegramId, 'volunteer', {
    volunteer_name: volunteer.name,
    task_location: task.location_text,
  });

  // If quota met: notify all remaining dispatched volunteers
  if (newStatus === 'assigned') {
    const remaining = (task.dispatched_to || []).filter(id => !newAssigned.includes(id));
    for (const vid of remaining) {
      await sendMessage(vid, 'Thank you for responding! This task has already been filled.\nWe\'ll notify you for the next one. 🙏');
    }
  }
}

async function handleNo(chatId, telegramId, volunteer) {
  const db = admin.firestore();
  
  // Find the task this volunteer was dispatched for
  const snap = await db.collection('tasks')
    .where('dispatched_to', 'array-contains', String(telegramId))
    .where('status', 'in', ['dispatching', 'open'])
    .limit(1)
    .get();

  await sendMessage(chatId, 'No problem. We\'ll find someone nearby.\nReply /available when you\'re free again. 🙏');

  if (!snap.empty) {
    const taskId = snap.docs[0].id;
    await writeAuditLog(taskId, 'volunteer_declined', telegramId, 'volunteer', {
      volunteer_name: volunteer.name,
    });
    
    // Try to dispatch next candidate
    const { dispatchNextCandidate } = require('./dispatchVolunteers');
    await dispatchNextCandidate(taskId, String(telegramId));
  }
}

// ── MAIN WEBHOOK HANDLER ──────────────────────────────────────────

async function handleTelegramWebhook(body) {
  const msg = body.message;
  if (!msg) return;

  const chatId = msg.chat.id;
  const telegramId = msg.from.id;
  const text = msg.text || '';
  const upperText = text.toUpperCase().trim();

  // ── Check if sender is a registered volunteer ──
  const volunteer = await getVolunteerByTelegramId(telegramId);

  if (volunteer) {
    // This is a known volunteer
    // Handle YES/NO first (most time-sensitive)
    if (upperText === 'YES') {
      await handleYes(chatId, telegramId, volunteer);
      return;
    }
    if (upperText === 'NO') {
      await handleNo(chatId, telegramId, volunteer);
      return;
    }
    
    // Try other volunteer commands
    const handled = await handleVolunteerCommand(chatId, telegramId, text, volunteer);
    if (handled) return;
    
    // If not a recognized command, treat as field report (volunteers can also report)
  }

  // ── Check for registration in progress ──
  if (upperText === '/REGISTER' || upperText === 'REGISTER') {
    const existing = await getVolunteerByTelegramId(telegramId);
    if (existing) {
      await sendMessage(chatId, `You're already registered as a volunteer!\nName: ${existing.name}\nStatus: ${existing.available ? 'Available ✅' : 'Busy 🔴'}`);
      return;
    }
    await handleRegistration(chatId, telegramId, text);
    return;
  }

  const session = await getVolunteerSession(telegramId);
  if (session) {
    await handleRegistration(chatId, telegramId, text);
    return;
  }

  // ── Field worker commands ──
  if (text === '/start') {
    await sendMessage(chatId, MSG_START);
    return;
  }

  if (text === '/help') {
    await sendMessage(chatId, MSG_HELP_FIELD);
    return;
  }

  if (text === '/status') {
    const db = admin.firestore();
    const snap = await db.collection('tasks')
      .where('source_ngo_user', '==', String(telegramId))
      .orderBy('created_at', 'desc')
      .limit(1)
      .get();

    if (snap.empty) {
      await sendMessage(chatId, 'No reports found. Send a photo, voice note, or text to report a need.');
    } else {
      const task = snap.docs[0].data();
      const volunteerCount = task.assigned_volunteers ? task.assigned_volunteers.length : 0;
      await sendMessage(chatId,
        `Your last report:\n📍 ${task.location_text || 'Location not specified'}\n🏷 ${task.need_type}\n📊 Status: ${task.status}\n👥 Volunteers dispatched: ${volunteerCount}`
      );
    }
    return;
  }

  if (text === '/cancel') {
    const db = admin.firestore();
    const snap = await db.collection('tasks')
      .where('source_ngo_user', '==', String(telegramId))
      .where('status', 'in', ['open', 'dispatching'])
      .orderBy('created_at', 'desc')
      .limit(1)
      .get();

    if (snap.empty) {
      await sendMessage(chatId, 'No active reports to cancel.');
    } else {
      await db.collection('tasks').doc(snap.docs[0].id).update({
        status: 'cancelled',
        updated_at: FieldValue.serverTimestamp(),
      });
      await sendMessage(chatId, 'Your last report has been cancelled. Send a new one anytime.');
    }
    return;
  }

  // ── Rate limiting check ──
  const recentCount = await countRecentTasksFromSender(telegramId);
  if (recentCount >= 10) {
    await sendMessage(chatId, MSG_RATE_LIMIT);
    return;
  }

  // ── Determine message type and extract ──
  let extracted = null;
  let sourceType = 'text';
  let rawInputText = '';

  // Processing acknowledgment
  await sendMessage(chatId, MSG_PROCESSING);

  try {
    if (msg.photo) {
      // Photo message — get highest resolution (last in array)
      sourceType = 'image';
      const photo = msg.photo[msg.photo.length - 1];
      
      try {
        const { base64, mimeType } = await downloadFileAsBase64(photo.file_id, 'image/jpeg');
        rawInputText = '[photo]';
        extracted = await extractFromImage(base64, mimeType);
      } catch (err) {
        if (err.message === 'FILE_TOO_LARGE') {
          await sendMessage(chatId, MSG_FILE_TOO_LARGE);
          return;
        }
        throw err;
      }

    } else if (msg.voice || msg.audio) {
      // Voice note
      sourceType = 'voice';
      const fileId = msg.voice ? msg.voice.file_id : msg.audio.file_id;
      
      const { base64, mimeType } = await downloadFileAsBase64(fileId, 'audio/ogg');
      rawInputText = '[voice note]';
      extracted = await extractFromAudio(base64, mimeType);

    } else if (msg.document) {
      // Document sent as file (may be an image)
      sourceType = 'image';
      const doc = msg.document;
      
      if (doc.file_size && doc.file_size > 5 * 1024 * 1024) {
        await sendMessage(chatId, MSG_FILE_TOO_LARGE);
        return;
      }
      
      const mime = doc.mime_type || 'image/jpeg';
      const { base64 } = await downloadFileAsBase64(doc.file_id, mime);
      rawInputText = '[document/image]';
      extracted = await extractFromImage(base64, mime);

    } else if (text && text.length > 0 && !text.startsWith('/')) {
      // Plain text report
      sourceType = 'text';
      rawInputText = text;
      extracted = await extractFromText(text);

    } else {
      // Unknown message type or unhandled command
      await sendMessage(chatId, MSG_HELP_FIELD);
      return;
    }

  } catch (err) {
    console.error('Extraction error:', err);
    await sendMessage(chatId, MSG_ERROR);
    return;
  }

  // ── Handle extraction errors ──
  if (!extracted || extracted.error) {
    console.error('Extraction failed:', extracted);
    await sendMessage(chatId, MSG_ERROR);
    return;
  }

  // ── Duplicate detection ──
  if (extracted.location) {
    const duplicate = await findDuplicateTask(extracted.location, extracted.need_type);
    if (duplicate) {
      const minutesAgo = Math.round((Date.now() - (duplicate.created_at?.toMillis?.() || Date.now())) / 60000);
      await sendMessage(chatId,
        `A similar report from ${extracted.location} was already received ${minutesAgo > 0 ? minutesAgo + ' minutes' : 'moments'} ago.\nCoordinator is handling it. Reply /status to check.`
      );
      return;
    }
  }

  // ── Determine review flags ──
  const needsReview = extracted.confidence_score < 0.80;
  let status = 'open';
  if (extracted.confidence_score >= 0.60 && extracted.confidence_score < 0.80) {
    status = 'flagged_medium';
  } else if (extracted.confidence_score < 0.60) {
    status = 'flagged_low';
  }

  // ── Write to Firestore ──
  const taskData = {
    ngo_id: 'asha_foundation',
    location_text: extracted.location || 'Location not specified',
    location_lat: null,
    location_lng: null,
    need_type: extracted.need_type,
    urgency: extracted.urgency,
    skills_required: extracted.skills_required,
    count_needed: extracted.count_needed,
    estimated_people_affected: extracted.estimated_people_affected,
    confidence_score: extracted.confidence_score,
    needs_review: needsReview,
    status: needsReview ? status : 'open',
    assigned_volunteers: [],
    dispatched_to: [],
    source_type: sourceType,
    source_ngo_user: String(telegramId),
    raw_input_text: rawInputText,
    dispatched_at: null,
    completed_at: null,
    time_to_dispatch_seconds: null,
    dispatch_timeout: false,
    notes: '',
    brief_description: extracted.brief_description,
  };

  const taskId = await createTask(taskData);
  await writeAuditLog(taskId, 'task_created', telegramId, 'field_worker', {
    source_type: sourceType,
    confidence: extracted.confidence_score,
  });

  // ── Reply to field worker ──
  if (extracted.confidence_score >= 0.80) {
    await sendMessage(chatId, buildSuccessMessage(extracted, taskId));
  } else if (extracted.confidence_score >= 0.60) {
    await sendMessage(chatId, buildLowConfidenceMessage(extracted));
    // Notify coordinator
    const coordinatorId = process.env.NGO_COORDINATOR_TELEGRAM_ID;
    if (coordinatorId) {
      await sendMessage(coordinatorId,
        `⚠️ New low-confidence report needs review.\n📍 ${extracted.location || 'Unknown'}\n🏷 ${extracted.need_type}\nConfidence: ${Math.round(extracted.confidence_score * 100)}%\n\nCheck your dashboard.`
      );
    }
  } else {
    await sendMessage(chatId, MSG_ERROR);
    // Notify coordinator of very low confidence
    const coordinatorId = process.env.NGO_COORDINATOR_TELEGRAM_ID;
    if (coordinatorId) {
      await sendMessage(coordinatorId,
        `🔴 Very low confidence report submitted (${Math.round(extracted.confidence_score * 100)}%). Manual verification needed. Check dashboard.`
      );
    }
  }
}

module.exports = { handleTelegramWebhook };