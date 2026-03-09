// @ts-ignore
declare const Deno: any;

// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"
// @ts-ignore
import {
  GoogleGenerativeAI,
  HarmCategory,
  HarmBlockThreshold,
} from "https://esm.sh/@google/generative-ai@0.19.0"

/** DB timestamptz → UTC 기준 캘린더 날짜 YYYY-MM-DD (Edge에서 일일 작성 횟수 기준 통일) */
function utcCalendarDateString(isoOrTimestamp: string): string {
  return new Date(isoOrTimestamp).toISOString().split("T")[0];
}

function base64UrlEncode(bytes: Uint8Array): string {
  // Uint8Array -> binary string -> base64 -> url-safe(base64url)
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const normalized = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/\s+/g, "");

  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function getFirebaseAccessToken(): Promise<string | null> {
  const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
  const privateKeyPem = Deno.env.get("FIREBASE_PRIVATE_KEY");

  if (!projectId || !clientEmail || !privateKeyPem) return null;

  const privateKey = privateKeyPem.replace(/\\n/g, "\n");

  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = base64UrlEncode(new TextEncoder().encode(JSON.stringify(header)));
  const encodedPayload = base64UrlEncode(new TextEncoder().encode(JSON.stringify(payload)));
  const signatureInput = `${encodedHeader}.${encodedPayload}`;

  const keyData = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    keyData,
    new TextEncoder().encode(signatureInput),
  );

  const encodedSignature = base64UrlEncode(new Uint8Array(signature));
  const jwt = `${signatureInput}.${encodedSignature}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  if (!tokenRes.ok) {
    console.error("FCM OAuth token fetch failed:", tokenRes.status, await tokenRes.text());
    return null;
  }

  const tokenData = await tokenRes.json();
  return tokenData?.access_token ?? null;
}

Deno.serve(async (req: Request) => {

  console.log("AUTH HEADER:", req.headers.get("authorization"))

  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
      }
    })
  }

  let payload: any = null

  try {
    try {
      payload = await req.json()
    } catch {
      payload = null
    }

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) throw new Error('GEMINI_API_KEY is not set')

    const genAI = new GoogleGenerativeAI(geminiApiKey)
    const chatModel = genAI.getGenerativeModel({ model: "gemini-flash-latest" })

    // ===== JSON 스키마 정의 (교정 + 추천 통합) =====
    const combinedSchema = {
      type: "object",
      properties: {
        corrected_text: { type: "string" },
        content_furigana: { type: "string" },
        corrected_content_furigana: { type: "string" },
        spelling_feedback: {
          type: "array",
          items: {
            type: "object",
            properties: {
              original: { type: "string" },
              corrected: { type: "string" },
              reason: { type: "string" },
            },
            required: ["original", "corrected", "reason"],
          },
        },
        recommendations: {
          type: "array",
          minItems: 5,
          items: {
            type: "object",
            properties: {
              type: { type: "string" },
              word: { type: "string" },
              reading: { type: "string" },
              pos: { type: "string" },
              meaning_translated: {
                type: "object",
                properties: {
                  ko: { type: "string" },
                  en: { type: "string" },
                  ja: { type: "string" },
                },
                required: ["ko", "en", "ja"],
              },
              connection: { type: "string" },
              example_jp: { type: "string" },
              example_translated: { type: "string" },
              example_en: { type: "string" },
              level: { type: "string" },
              ruby: { type: "string" },
            },
            required: [
              "type",
              "word",
              "reading",
              "ruby",
              "pos",
              "meaning_translated",
              "connection",
              "example_jp",
              "example_translated",
              "example_en",
              "level",
            ],
          },
        },
      },
      required: [
        "corrected_text",
        "content_furigana",
        "corrected_content_furigana",
        "spelling_feedback",
        "recommendations",
      ],
    };

    // 시스템 지시어: 피드백 = 추천 1순위 강제 + 무조건 5개 이상 보장
    const diarySystemInstruction = `You are a professional Japanese tutor. 
    1. [FEEDBACK = RECOMMENDATIONS]: This is the most critical rule. If you correct ANY word or grammar in "spelling_feedback", you MUST include that corrected word/grammar as an item in "recommendations". 
    2. [QUANTITY]: You MUST recommend AT LEAST 5 items. If you only have 1 or 2 corrections, you MUST creatively brainstorm and include contextually related vocabulary/grammar (synonyms, thematic words) to reach 5+ items. NEVER return 1~4 items.
    3. [JLPT LEVEL PRIORITY]: Prioritize mid/advanced expressions at JLPT N4, N3, N2, N1.
    4. [WORD / READING / RUBY]: For each recommendation, provide exactly:
       - "word": plain Japanese (e.g., 食べる). No ruby markup.
       - "reading": pure Hiragana only (e.g., たべる). No Kanji, no brackets.
       - "ruby": display form with [Kanji](reading) for every Kanji; do NOT wrap Kana in brackets (e.g., [食](た)べる). Pure Kana words: use the word as-is for "ruby".
    5. [FURIGANA]: Use [Kanji](reading) for EVERY Kanji in ALL Japanese fields: example_jp, meaning_translated.ja, and "ruby".
    6. [MEANING JSON]: "meaning_translated" MUST be exactly {"ko": "...", "en": "...", "ja": "..."}. The "ja" value MUST include furigana using [Kanji](reading).
    7. [GRAMMAR CONNECTIONS]: If type is "grammar", the "connection" field MUST use JLPT-style part-of-speech notation. If type is "word", the "connection" field MUST be empty ("").
    8. [EXAMPLE RULE]: EVERY recommendation MUST include exactly ONE highly natural example sentence in 'example_jp' (with furigana), and translations in 'example_translated' (Korean) and 'example_en' (English).
    9. [GRAMMAR FORMAT RULE]: If type is "grammar", the "word" and "ruby" MUST start with a tilde "〜".
    10. [STRICT LANGUAGE ISOLATION]: The fields "word", "reading", "ruby", and "example_jp" MUST consist of 100% pure Japanese characters ONLY (Kanji, Hiragana, Katakana, and standard Japanese punctuation). ABSOLUTELY NO non-Japanese characters (such as Korean Hangul, English alphabets, etc.) are allowed in these fields. (e.g., NEVER output a mixed word like "魅力적な", it MUST be strictly "魅力的な").`;

    const diaryModel = genAI.getGenerativeModel({
      model: "gemini-flash-latest",
      systemInstruction: diarySystemInstruction,
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: combinedSchema,
      },
    })

    const record = payload?.record
    const oldRecord = payload?.old_record
    const isRetryFailed = oldRecord?.feedback_status === 'failed'

    if (record && record.feedback_status === 'pending' && record.content) {
      const diary_id = record.id
      const content = record.content
      const user_id = record.user_id
      const language_code = record.language_code ?? 'ko'

      const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
      const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      const supabase = createClient(supabaseUrl, supabaseKey)

      // 1. 유저의 기본 role 확인
      const { data: userData } = await supabase
        .from('users')
        .select('role')
        .eq('id', user_id)
        .maybeSingle()
        
      let isPremium = userData?.role === 'premium'

      // 2. 만약 기본 role이 free라면, subscriptions 테이블 검사!
      if (!isPremium) {
        const nowStr = new Date().toISOString()
        const { data: subData } = await supabase
          .from('subscriptions')
          .select('id')
          .eq('user_id', user_id)
          .eq('status', 'active')
          .gte('end_date', nowStr)
          .maybeSingle()

        if (subData) {
          isPremium = true
        }
      }

      const maxChars = isPremium ? 1000 : 300
      if (typeof content === 'string' && content.length > maxChars) {
        throw new Error('글자 수 제한을 초과했습니다.')
      }

      let todayUtcStr: string | null = null
      let stats: { daily_write_count: number; last_write_date: string | null } | null = null

      if (!isPremium && !isRetryFailed) {
        todayUtcStr = new Date().toISOString().split("T")[0]

        const { data: statsData } = await supabase
          .from('user_stats')
          .select('daily_write_count, last_write_date')
          .eq('user_id', user_id)
          .maybeSingle();
        stats = statsData ?? null

        const lastUtcDay = stats?.last_write_date
          ? utcCalendarDateString(stats.last_write_date)
          : null
        if (
          stats &&
          lastUtcDay === todayUtcStr &&
          stats.daily_write_count >= 2
        ) {
          throw new Error('무료 회원은 하루에 두 번만 작성할 수 있습니다.');
        }
      }
      await supabase.from('diaries').update({ feedback_status: 'processing', user_id: user_id }).eq('id', diary_id)

      let correctionLanguage = '한국어';
      if (language_code === 'ja') correctionLanguage = '日本語';
      if (language_code === 'en') correctionLanguage = 'English';

      // 💡 여기서도 "피드백을 무조건 추천에 넣어라"고 강하게 압박합니다.
      const combinedPrompt = `
Analyze this diary: "${content}" for a Japanese learner and return ONE JSON object matching the schema.

1. Correct errors into 100% natural Japanese ("corrected_text"). Explain corrections in ${correctionLanguage} ("spelling_feedback").
2. Provide "content_furigana" and "corrected_content_furigana" with correct [Kanji](reading) formatting.
   CRITICAL RULE FOR content_furigana: DO NOT translate Korean/English words into Japanese. Keep the original text EXACTLY as it is. ONLY add furigana to the Japanese Kanji that already exist in the original text.
3. CRITICAL: If you add any items to "spelling_feedback", you MUST also add those exact corrected words/grammar points into "recommendations".
4. You MUST provide AT LEAST 5 recommendations. If the corrections are fewer than 5, brainstorm related synonyms, higher-level rephrasings, and native collocations based on the diary theme to reach 5+ items.
5. Prioritize JLPT N3/N2/N1 expressions.
6. STRICT LANGUAGE ISOLATION in "recommendations": The "word", "reading", "ruby", and "example_jp" fields MUST contain ONLY valid Japanese characters (Kanji, Hiragana, Katakana). NEVER mix in Korean (Hangul), English, or any other languages. (e.g., Mixing languages like "魅力적な" is strictly FORBIDDEN).
`;

const delay = (ms: number) => new Promise(res => setTimeout(res, ms));
const stripCodeFence = (text: string) => text
  .replace(/^```(?:json)?/mi, '')
  .replace(/```$/m, '')
  .trim();
  const toLevel = (value: any) => String(value ?? 'N3').toUpperCase();
  const isAdvancedLevel = (value: any) => ['N3', 'N2', 'N1'].includes(toLevel(value));
  const isValidRec = (item: any) =>
    item &&
    typeof item === 'object' &&
    String(item.word ?? '').trim() !== '';
  const uniqueByTypeWord = (items: any[]) => {
    const seen = new Set<string>();
    const out: any[] = [];
    for (const item of items) {
      if (!isValidRec(item)) continue;
      const type = String(item.type ?? 'word').toLowerCase().trim();
      const word = String(item.word ?? '').toLowerCase().trim();
      if (!word) continue;
      const key = `${type}:${word}`;
      if (seen.has(key)) continue;
      seen.add(key);
      out.push(item);
    }
    return out;
  };
  
  let parsed: any = null;
  let attempts = 0;
  const maxAttempts = 3;

  while (attempts < maxAttempts) {
    try {
      attempts++;
      console.log(`[Attempt ${attempts}] API 호출 중...`);
      
      const combinedResult = await diaryModel.generateContent(combinedPrompt);
      const combinedText = stripCodeFence(combinedResult.response.text().trim());
      parsed = JSON.parse(combinedText);
      break; // 성공 시 while 루프 정상 탈출
    } catch (error) {
      console.error(`[Attempt ${attempts}] Gemini 호출 또는 JSON 파싱 실패:`, error);
      if (attempts >= maxAttempts) throw error;
      const backoff = 1000 * Math.pow(2, attempts - 1);
      await delay(backoff);
    }
  }

  const correctionNotes = parsed.spelling_feedback?.map((e: any) => ({
    original: e.original || '',
    corrected: e.corrected || '',
    reason: e.reason || '',
  })) ?? []

  let recommendations = uniqueByTypeWord(
    Array.isArray(parsed.recommendations) ? parsed.recommendations : [],
  );

  let fallbackAttempts = 0;
  while (recommendations.length < 5 && fallbackAttempts < 2) {
    fallbackAttempts++;
    const need = 5 - recommendations.length;
    const existingWords = recommendations.map((r) => String(r.word ?? '').trim()).filter((w) => w);

    const dynamicFallbackPrompt = `
You generated fewer than 5 recommendations. 
The user's original diary content was: ${JSON.stringify(content)}.
Based on the **theme or context** of this diary, brainstorm and generate EXACTLY ${need} additional advanced Japanese expressions (JLPT N4/N3/N2/N1) related to what the user wrote about.
Do NOT use these words: ${JSON.stringify(existingWords)}.
Return ONLY a pure JSON array matching this exact structure:
[
{
"type": "word",
"word": "plain japanese",
"reading": "hiragana",
"pos": "part of speech",
"meaning_translated": {"ko": "...", "en": "...", "ja": "..."},
"connection": "",
"example_jp": "...",
"example_translated": "...",
"example_en": "...",
"level": "N3",
"ruby": "..."
}
]
`;
    try {
      console.log(`[Dynamic Fallback ${fallbackAttempts}] 일기 문맥 기반 추가 추천 단어 ${need}개 생성 요청 중...`);
      const fallbackResult = await chatModel.generateContent(dynamicFallbackPrompt);
      const fallbackText = stripCodeFence(fallbackResult.response.text().trim());
      const fallbackParsed = JSON.parse(fallbackText);
      const fallbackList = Array.isArray(fallbackParsed) ? fallbackParsed : (fallbackParsed.recommendations || []);

      recommendations = uniqueByTypeWord([...recommendations, ...fallbackList]);
    } catch (e) {
      console.error("Dynamic fallback failed:", e);
    }
  }

  parsed.recommendations = recommendations;

  await supabase.from('user_recommendations').delete().eq('diary_id', diary_id).eq('is_bookmarked', false)
  await supabase.from('user_recommendations').update({ diary_id: null }).eq('diary_id', diary_id).eq('is_bookmarked', true)

 // 💡 여기서부터 Bulk Insert (가장 빠르고 안전한 로직)
// 💡 1. 단어/문법 DB에 일괄 저장 (Bulk Upsert) - 기존 데이터 병합 로직 추가
if (parsed.recommendations && parsed.recommendations.length > 0) {
  const vocabularyList: any[] = [];
  const grammarList: any[] = [];

  // 💡 품사/레벨 변환기 (생략 없이 기존 코드 유지)
  // 💡 품사 변환기 (소문자 영단어 강제 및 DB Enum 호환)
  const mapPos = (rawPos: string): string => {
    if (!rawPos) return 'etc';
    const p = String(rawPos).toLowerCase();
    if (p.includes('代名詞') || p.includes('pronoun') || p.includes('대명사')) return 'pronoun';
    if (p.includes('形容動詞') || p.includes('na-adjective')) return 'adjective';
    if (p.includes('形容詞') || p.includes('adjective') || p.includes('형용사')) return 'adjective';
    if (p.includes('感動詞') || p.includes('interjection') || p.includes('감탄사')) return 'interjection';
    if (p.includes('動詞') || p.includes('verb') || p.includes('동사')) return 'verb';
    if (p.includes('名詞') || p.includes('noun') || p.includes('명사')) return 'noun';
    if (p.includes('副詞') || p.includes('adverb') || p.includes('부사')) return 'adverb';
    if (p.includes('助詞') || p.includes('particle') || p.includes('조사')) return 'particle';
    if (p.includes('接続詞') || p.includes('conjunction') || p.includes('접속사')) return 'conjunction';
    return 'etc';
  };

  // 💡 JLPT 레벨 변환기 (대문자 강제)
  const mapLevel = (rawLevel: any): string => {
    if (!rawLevel) return 'ETC';
    const l = String(rawLevel).toUpperCase();
    if (l.includes('N1')) return 'N1';
    if (l.includes('N2')) return 'N2';
    if (l.includes('N3')) return 'N3';
    if (l.includes('N4')) return 'N4';
    if (l.includes('N5')) return 'N5';
    return 'ETC';
  };
  for (const item of parsed.recommendations) {
    const typeRaw = (item.type || 'word').toString().toLowerCase();
    const isGrammar = typeRaw.includes('grammar') || typeRaw.includes('문法') || typeRaw.includes('문형');
    
    const newExample = {
      jp: item.example_jp || '',
      ko: item.example_translated || '',
      ...(item.example_en ? { en: item.example_en } : {}),
    };

    if (!isGrammar) {
      vocabularyList.push({
        word: item.word,
        reading: item.reading || null,
        ruby: (item.ruby != null && String(item.ruby).trim() !== '') ? String(item.ruby).trim() : '',
        pos: [mapPos(item.pos)],
        meanings: item.meaning_translated ?? {},
        examples: [newExample], // 일단 단일 배열로 세팅
        level: [mapLevel(item.level)],
        updated_at: new Date().toISOString(),
      });
    } else {
      grammarList.push({
        title: item.word,
        reading: item.reading || null,
        ruby: (item.ruby != null && String(item.ruby).trim() !== '') ? String(item.ruby).trim() : '',
        level: mapLevel(item.level),
        meaning: item.meaning_translated ?? {},
        connection: item.connection ? item.connection.toString() : '',
        examples: [newExample], // 일단 단일 배열로 세팅
        updated_at: new Date().toISOString(),
      });
    }
  }

  // 💡 1-1. 기존 데이터 일괄 조회 (병합을 위함)
  const newWords = vocabularyList.map(v => v.word);
  const newTitles = grammarList.map(g => g.title);

  let existingVocabs: any[] = [];
  let existingGrammars: any[] = [];

  if (newWords.length > 0) {
    const { data } = await supabase.from('vocabulary').select('id, word, examples').in('word', newWords);
    existingVocabs = data || [];
  }
  if (newTitles.length > 0) {
    const { data } = await supabase.from('grammar').select('id, title, examples, connection').in('title', newTitles);
    existingGrammars = data || [];
  }

 // 💡 1-2. 기존 데이터와 병합 (Merge)
 const mergedVocabularyList = vocabularyList.map(newVocab => {
  const existing = existingVocabs.find(v => v.word === newVocab.word);
  if (existing) {
    // 기존 예문에 새 예문 추가 (Append)
    const mergedExamples = [...(existing.examples || []), ...newVocab.examples];
    
    // 🚨 수정됨: id를 명시하지 않고 예문만 덮어씌웁니다. 
    // 배열 내 모든 객체의 형태를 동일하게 맞추기 위함입니다.
    return { ...newVocab, examples: mergedExamples };
  }
  return newVocab;
});

const mergedGrammarList = grammarList.map(newGrammar => {
  const existing = existingGrammars.find(g => g.title === newGrammar.title);
  if (existing) {
    // 기존 예문에 새 예문 추가 (Append)
    const mergedExamples = Array.from(
      new Map([...(existing.examples || []), ...newVocab.examples].map(e => [e.jp, e])).values()
    );
    
    // 문법 connection 조건부 업데이트
    const isConnectionEmpty = !existing.connection || existing.connection.trim() === '';
    const finalConnection = isConnectionEmpty && newGrammar.connection 
      ? newGrammar.connection 
      : existing.connection;

    // 🚨 수정됨: id를 명시하지 않고 속성만 덮어씌웁니다.
    return { 
      ...newGrammar, 
      examples: mergedExamples, 
      connection: finalConnection 
    };
  }
  return newGrammar;
});

  // 💡 1-3. 병합된 최종 데이터로 Upsert 실행
  let upsertedWords: any[] = [];
  let upsertedGrammars: any[] = [];

  if (mergedVocabularyList.length > 0) {
    const { data, error } = await supabase.from('vocabulary')
      .upsert(mergedVocabularyList, { onConflict: 'word' })
      .select('id, word');
    if (error) throw new Error(`Vocab Upsert Error: ${error.message}`);
    upsertedWords = data || [];
  }
  
  if (mergedGrammarList.length > 0) {
    const { data, error } = await supabase.from('grammar')
      .upsert(mergedGrammarList, { onConflict: 'title' })
      .select('id, title');
    if (error) throw new Error(`Grammar Upsert Error: ${error.message}`);
    upsertedGrammars = data || [];
  }

  // 3. 유저 매핑
  for (const item of parsed.recommendations) {
    const typeRaw = (item.type || 'word').toString().toLowerCase();
    const isGrammar = typeRaw.includes('grammar') || typeRaw.includes('문法') || typeRaw.includes('문형');
    const normalizedType = isGrammar ? 'grammar' : 'word';

    let wordId = null;
    let grammarId = null;

    if (normalizedType === 'word') {
      const matched = upsertedWords.find(w => w.word === item.word);
      if (matched) wordId = matched.id;
    } else {
      const matched = upsertedGrammars.find(g => g.title === item.word);
      if (matched) grammarId = matched.id;
    }

    if (wordId || grammarId) {
      let query = supabase.from('user_recommendations').select('id, is_bookmarked').eq('user_id', user_id).eq('item_type', normalizedType);
      if (wordId) query = query.eq('word_id', wordId);
      if (grammarId) query = query.eq('grammar_id', grammarId);
      
      const { data: existingRec, error: selectErr } = await query.limit(1).maybeSingle();
      if (selectErr) throw selectErr;

      if (existingRec) {
        const { error: updateErr } = await supabase.from('user_recommendations').update({ diary_id: diary_id }).eq('id', existingRec.id);
        if (updateErr) throw updateErr;
      } else {
        const { error: insertErr } = await supabase.from('user_recommendations').insert({
          user_id: user_id,
          diary_id: diary_id,
          item_type: normalizedType,
          word_id: wordId,
          grammar_id: grammarId,
          is_bookmarked: false
        });
        if (insertErr) throw insertErr;
      }
    }
  }
}
  await supabase.from('diaries').update({
    corrected_content: parsed.corrected_text,
    content_furigana: parsed.content_furigana,
    corrected_content_furigana: parsed.corrected_content_furigana,
    correction_notes: correctionNotes,
    feedback_status: 'completed',
    user_id: user_id,
  }).eq('id', diary_id)

  if (!isPremium && todayUtcStr && !isRetryFailed) {
    const nowIso = new Date().toISOString()
    if (stats) {
      const lastUtcDay = stats.last_write_date
        ? utcCalendarDateString(stats.last_write_date)
        : null
      const newCount =
        lastUtcDay === todayUtcStr ? stats.daily_write_count + 1 : 1
      await supabase
        .from('user_stats')
        .update({ daily_write_count: newCount, last_write_date: nowIso })
        .eq('user_id', user_id);
    } else {
      await supabase
        .from('user_stats')
        .insert({ user_id: user_id, daily_write_count: 1, last_write_date: nowIso });
    }
  }

  // =========================================================================
  // 분석 완료 푸시 알림 발송 (FCM HTTP v1)
  // =========================================================================
  try {
    const { data: pushUserData } = await supabase
      .from("users")
      .select("fcm_token")
      .eq("id", user_id)
      .maybeSingle();

    const fcmToken = pushUserData?.fcm_token;

    if (fcmToken) {
      const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
      const accessToken = await getFirebaseAccessToken();

      if (projectId && accessToken) {
        await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: fcmToken,
              notification: {
                title: "✨AI 피드백이 완료되었어요✨",
                body: "어떤 표현을 추천했을까요? 지금 확인해 보세요!",
              },
              data: {
                type: "diary_feedback_completed",
                diaryId: String(diary_id),
              },
              android: {
                priority: "high",
                notification: { sound: "default" }
              },
              apns: {
                payload: { aps: { "content-available": 1, sound: "default" } }
              }
            },
          }),
        });
      }
    }
  } catch (pushError) {
    console.error("FCM push failed (ignored):", pushError);
  }

  return new Response(JSON.stringify({ success: true, result: parsed }), { headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } })
}

if (payload?.message) {
  const result = await chatModel.generateContent(payload.message)
  const text = result.response.text()
  return new Response(JSON.stringify({ reply: text }), { headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } })
}

return new Response("No-op: not a pending diary", { status: 200 })

} catch (error: any) {
console.error("Error caught in Edge Function:", error);
try {
  if (payload?.record?.id) {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)
    const userId = payload.record.user_id
    const diaryId = payload.record.id

    await supabase.from('diaries').update({ feedback_status: 'failed', user_id: userId }).eq('id', diaryId)

    // =========================================================================
    // 🚀 [복구] 분석 실패 푸시 알림 발송
    // =========================================================================
    const { data: pushUserData } = await supabase
      .from("users")
      .select("fcm_token")
      .eq("id", userId)
      .maybeSingle();

    const fcmToken = pushUserData?.fcm_token;

    if (fcmToken) {
      const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
      const accessToken = await getFirebaseAccessToken();

      if (projectId && accessToken) {
        await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: fcmToken,
              notification: {
                title: "AI가 피드백을 완수하지 못했어요😢",
                body: "앱에서 재분석을 시도해 주세요. 반복되면 문의하기로 제보 부탁드려요🥹",
              },
              data: {
                type: "diary_feedback_failed",
                diaryId: String(diaryId),
              },
              android: {
                priority: "high",
                notification: { sound: "default" }
              },
              apns: {
                payload: { aps: { "content-available": 1, sound: "default" } }
              }
            },
          }),
        });
        console.log("✅ 실패 알림 FCM 발송 완료!");
      }
    }
  }
} catch (fallbackError) {
  console.error("DB 업데이트 또는 실패 알림 전송 중 에러:", fallbackError);
}

return new Response(JSON.stringify({ success: false, error: error.message }), { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } })
}
})