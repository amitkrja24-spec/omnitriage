// THE CHANGE: Removed dotenv bypass
const fetch = require('node-fetch');

// THE CHANGE: Hardcoded the Telegram Bot Token
const BASE_URL = `https://api.telegram.org/bot4amit`;/////////////////////////////////////////////////////////

// Send a text message to a Telegram chat
async function sendMessage(chatId, text, options = {}) {
  try {
    const body = {
      chat_id: chatId,
      text: text,
      parse_mode: 'Markdown',
      ...options,
    };
    const response = await fetch(`${BASE_URL}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const data = await response.json();
    if (!data.ok) {
      console.error('Telegram sendMessage error:', data);
    }
    return data;
  } catch (err) {
    console.error('sendMessage failed:', err.message);
  }
}

// Get file info from Telegram (needed before downloading)
async function getFile(fileId) {
  try {
    const response = await fetch(`${BASE_URL}/getFile?file_id=${fileId}`);
    const data = await response.json();
    if (!data.ok) throw new Error(`getFile failed: ${JSON.stringify(data)}`);
    return data.result; // { file_id, file_size, file_path }
  } catch (err) {
    console.error('getFile failed:', err.message);
    throw err;
  }
}

// Download a file from Telegram servers, returns Buffer
async function downloadFile(filePath) {
  try {
    // THE CHANGE: Hardcoded the Telegram Bot Token here as well
    const url = `https://api.telegram.org/file/bot4amit/${filePath}`;///////////////////////////////////
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Download failed: ${response.status}`);
    const arrayBuffer = await response.arrayBuffer();
    return Buffer.from(arrayBuffer);
  } catch (err) {
    console.error('downloadFile failed:', err.message);
    throw err;
  }
}

// Download a Telegram file by file_id, return as base64 string and mimeType
async function downloadFileAsBase64(fileId, defaultMime = 'application/octet-stream') {
  const fileInfo = await getFile(fileId);
  
  // Check file size (5MB limit)
  if (fileInfo.file_size && fileInfo.file_size > 5 * 1024 * 1024) {
    throw new Error('FILE_TOO_LARGE');
  }
  
  const buffer = await downloadFile(fileInfo.file_path);
  const base64 = buffer.toString('base64');
  
  // Determine MIME type from file path
  let mimeType = defaultMime;
  if (fileInfo.file_path.endsWith('.jpg') || fileInfo.file_path.endsWith('.jpeg')) {
    mimeType = 'image/jpeg';
  } else if (fileInfo.file_path.endsWith('.png')) {
    mimeType = 'image/png';
  } else if (fileInfo.file_path.endsWith('.ogg')) {
    mimeType = 'audio/ogg';
  } else if (fileInfo.file_path.endsWith('.mp4')) {
    mimeType = 'video/mp4';
  }
  
  return { base64, mimeType, fileSize: fileInfo.file_size };
}

module.exports = { sendMessage, getFile, downloadFile, downloadFileAsBase64 };