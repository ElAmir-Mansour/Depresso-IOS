const { GoogleGenerativeAI } = require("@google/generative-ai");
const WebSocket = require("ws");

// We MUST use the exact Live API model variant for real-time speech
const LIVE_MODEL = "gemini-2.0-flash-exp";

class LiveAiService {
    constructor() {
        // We initialize the client with the first available key
        const keys = (process.env.GEMINI_API_KEY || '').split(',').map(k => k.trim());
        this.apiKey = keys[0];
        
        if (!this.apiKey) {
            console.error("🔴 CRITICAL: No GEMINI_API_KEY found in environment.");
        }

        this.genAI = new GoogleGenerativeAI(this.apiKey);
        console.log("✅ LiveAiService Initialized with Google GenAI SDK");
    }

    /**
     * Creates a bidirectional WebSocket bridge between the iOS App and Google's Live API
     * @param {WebSocket} clientWs - The WebSocket connection from the iOS app
     */
    setupLiveSession(clientWs) {
        console.log("🔌 New Live Session Requested from iOS");

        // The Gemini Live API uses a specialized WebSocket endpoint
        const HOST = "generativelanguage.googleapis.com";
        const WS_URL = `wss://${HOST}/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=${this.apiKey}`;

        // Connect to Google's Live API
        const geminiWs = new WebSocket(WS_URL);

        geminiWs.on("open", () => {
            console.log("🟢 Connected to Gemini Live API");

            // Initial setup message required by the Live API
            const setupMessage = {
                setup: {
                    model: `models/${LIVE_MODEL}`,
                    systemInstruction: {
                        parts: [{ 
                            text: "You are Depresso, an empathetic and concise AI voice companion for a mental wellness app. Keep your responses short, conversational, and supportive. The user is speaking to you directly. You can be interrupted." 
                        }]
                    }
                }
            };
            
            geminiWs.send(JSON.stringify(setupMessage));
        });

        // 📥 Handle incoming messages from iOS (Audio chunks)
        clientWs.on("message", (data) => {
            try {
                const message = JSON.parse(data);

                // If iOS sends audio data, forward it to Gemini
                if (message.realtimeInput) {
                    const clientContent = {
                        clientContent: {
                            turns: [{
                                role: "user",
                                parts: [{
                                    inlineData: {
                                        mimeType: "audio/pcm;rate=16000",
                                        data: message.realtimeInput.mediaChunks[0].data // Base64 PCM data
                                    }
                                }]
                            }],
                            turnComplete: true
                        }
                    };
                    
                    if (geminiWs.readyState === WebSocket.OPEN) {
                        geminiWs.send(JSON.stringify(clientContent));
                    }
                }
            } catch (err) {
                console.error("Error processing iOS message:", err);
            }
        });

        // 📤 Handle incoming messages from Gemini (Audio/Text responses)
        geminiWs.on("message", (data) => {
            try {
                // We just forward the raw JSON string straight back to iOS
                // iOS will parse the serverContent and play the audio
                if (clientWs.readyState === WebSocket.OPEN) {
                    clientWs.send(data.toString());
                }
            } catch (err) {
                console.error("Error processing Gemini response:", err);
            }
        });

        // Handle Disconnects
        clientWs.on("close", () => {
            console.log("🔴 iOS Client Disconnected");
            if (geminiWs.readyState === WebSocket.OPEN) {
                geminiWs.close();
            }
        });

        geminiWs.on("close", () => {
            console.log("🔴 Gemini Live API Disconnected");
            if (clientWs.readyState === WebSocket.OPEN) {
                clientWs.close();
            }
        });

        geminiWs.on("error", (error) => {
            console.error("❌ Gemini WS Error:", error);
        });
    }
}

module.exports = new LiveAiService();