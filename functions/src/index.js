const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const MODEL_NAME = "gemini-2.5-flash";

function buildPrompt(query, financialContext) {
  const contextText = typeof financialContext === "string" && financialContext.trim().length > 0
    ? financialContext.trim()
    : "No app financial data context was provided.";

  return `You are CashTrack's finance assistant.
Use the user's app data context below when answering.
If data is missing for a claim, clearly say it is unavailable instead of guessing.
Keep the answer practical and concise.

App Financial Context:
${contextText}

User Question:
${query}`;
}

exports.generateAiResponse = onCall(
  {
    region: "us-central1",
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Server AI key is not configured."
      );
    }

    const query = typeof request.data?.query === "string" ? request.data.query.trim() : "";
    const financialContext =
      typeof request.data?.financialContext === "string"
        ? request.data.financialContext
        : "";

    if (!query) {
      throw new HttpsError("invalid-argument", "Query is required.");
    }

    const prompt = buildPrompt(query, financialContext);

    const endpoint =
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${apiKey}`;

    let response;
    try {
      response = await fetch(endpoint, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({
          contents: [
            {
              parts: [{text: prompt}],
            },
          ],
        }),
      });
    } catch (err) {
      logger.error("Gemini request failed", err);
      throw new HttpsError("internal", "Failed to contact AI provider.");
    }

    const json = await response.json().catch(() => ({}));
    if (!response.ok) {
      logger.error("Gemini error response", json);
      throw new HttpsError("internal", "AI provider rejected the request.");
    }

    const text = json?.candidates?.[0]?.content?.parts
      ?.map((p) => p?.text || "")
      .join("\n")
      .trim();

    return {
      text: text || "No response from AI service.",
    };
  }
);
