// THE CHANGE: Removed dotenv bypass
const { GoogleGenAI } = require('@google/genai');
const { EXTRACTION_PROMPT, TEXT_SUFFIX, IMAGE_SUFFIX, AUDIO_SUFFIX } = require('./geminiPrompt');

// THE CHANGE: Hardcoded API key for the bypass
const ai = new GoogleGenAI({ apiKey: "amitapi" });/////////////////////////////////////////////////////////////////////////

// Parse Gemini's JSON response safely (Kept exactly as requested)
function parseGeminiResponse(rawText) {
  try {
    // Strip any accidental markdown code blocks
    let cleaned = rawText.trim();
    cleaned = cleaned.replace(/^```json\s*/i, '').replace(/\s*```$/i, '');
    cleaned = cleaned.replace(/^```\s*/i, '').replace(/\s*```$/i, '');
    return JSON.parse(cleaned);
  } catch (e) {
    console.error('JSON parse failed. Raw:', rawText);
    return null;
  }
}

// Validate and fill defaults for extracted data (Kept exactly as requested)
function validateExtraction(data) {
  const VALID_NEED_TYPES = ['medical', 'food_ration', 'sanitation', 'education', 'shelter', 'disaster', 'other'];
  const VALID_SKILLS = ['nurse', 'doctor', 'first_aid', 'logistics', 'driving', 'teacher',
    'tutoring', 'construction', 'sanitation', 'social_work', 'cooking', 'counseling',
    'rescue', 'photography', 'general'];

  return {
    location: data.location || null,
    need_type: VALID_NEED_TYPES.includes(data.need_type) ? data.need_type : 'other',
    urgency: Number.isInteger(data.urgency) && data.urgency >= 1 && data.urgency <= 5
      ? data.urgency : 3,
    skills_required: Array.isArray(data.skills_required)
      ? data.skills_required.filter(s => VALID_SKILLS.includes(s))
      : ['general'],
    count_needed: Number.isInteger(data.count_needed) && data.count_needed > 0
      ? data.count_needed : 1,
    estimated_people_affected: Number.isInteger(data.estimated_people_affected)
      ? data.estimated_people_affected : null,
    brief_description: typeof data.brief_description === 'string'
      ? data.brief_description.substring(0, 200) : 'Field report submitted',
    confidence_score: typeof data.confidence_score === 'number'
      ? Math.min(1.0, Math.max(0.0, data.confidence_score)) : 0.5,
  };
}

// Extract from plain text
async function extractFromText(text) {
  try {
    // THE CHANGE: Updated to active gemini-2.5-flash and modern generateContent syntax
    const promptText = EXTRACTION_PROMPT + TEXT_SUFFIX + '\n\nFIELD REPORT:\n' + text;
    const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: promptText
    });
    
    const rawText = response.text;
    const parsed = parseGeminiResponse(rawText);
    if (!parsed) return { error: 'PARSE_FAILED', raw: rawText };
    return validateExtraction(parsed);
  } catch (err) {
    console.error('extractFromText error:', err.message);
    return { error: err.message };
  }
}

// Extract from image (base64 string + mimeType like 'image/jpeg')
async function extractFromImage(base64Data, mimeType = 'image/jpeg') {
  try {
    // THE CHANGE: Updated multimodal array syntax for new SDK
    const promptText = EXTRACTION_PROMPT + IMAGE_SUFFIX;
    const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: [
            promptText,
            { inlineData: { mimeType: mimeType, data: base64Data } }
        ]
    });
    
    const rawText = response.text;
    const parsed = parseGeminiResponse(rawText);
    if (!parsed) return { error: 'PARSE_FAILED', raw: rawText };
    return validateExtraction(parsed);
  } catch (err) {
    console.error('extractFromImage error:', err.message);
    return { error: err.message };
  }
}

// Extract from audio (base64 .ogg)
async function extractFromAudio(base64Data, mimeType = 'audio/ogg') {
  try {
    // THE CHANGE: Updated multimodal array syntax for new SDK
    const promptText = EXTRACTION_PROMPT + AUDIO_SUFFIX;
    const response = await ai.models.generateContent({
         model: 'gemini-2.5-flash',
         contents: [
            promptText,
            { inlineData: { mimeType: mimeType, data: base64Data } }
        ]
    });
    
    const rawText = response.text;
    const parsed = parseGeminiResponse(rawText);
    if (!parsed) return { error: 'PARSE_FAILED', raw: rawText };
    return validateExtraction(parsed);
  } catch (err) {
    console.error('extractFromAudio error:', err.message);
    return { error: err.message };
  }
}

module.exports = { extractFromText, extractFromImage, extractFromAudio };