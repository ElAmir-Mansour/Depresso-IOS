const { GoogleGenAI } = require('@google/genai');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { v4: uuidv4 } = require('uuid');

class RAGService {
    constructor() {
        const keys = (process.env.GEMINI_API_KEY || '').split(',').map(k => k.trim());
        this.apiKey = keys[0];
        
        if (this.apiKey) {
            this.ai = new GoogleGenAI({ apiKey: this.apiKey });
        } else {
            console.error("🔴 CRITICAL: No GEMINI_API_KEY found for RAG Service.");
        }

        // Cache for Store Names to avoid recreating them
        this.userHistoryStoreName = process.env.RAG_USER_HISTORY_STORE || null;
        this.clinicalStoreName = process.env.RAG_CLINICAL_STORE || null;
    }

    /**
     * Initializes the necessary File Search Stores if they don't exist yet.
     */
    async initStores() {
        if (!this.ai) return;

        try {
            console.log("Checking RAG Stores...");

            // In production, we'd list existing stores and find them by displayName, 
            // but for now we create them if the ENV vars aren't set.
            if (!this.userHistoryStoreName) {
                console.log("Creating User History Store...");
                const userStore = await this.ai.fileSearchStores.create({
                    config: {
                        displayName: 'Depresso User History Store',
                        embeddingModel: 'models/gemini-embedding-2' 
                    }
                });
                this.userHistoryStoreName = userStore.name;
                console.log(`✅ User History Store created: ${this.userHistoryStoreName}`);
            }

            if (!this.clinicalStoreName) {
                console.log("Creating Clinical Knowledge Store...");
                const clinicalStore = await this.ai.fileSearchStores.create({
                    config: {
                        displayName: 'Depresso Clinical Knowledge Base',
                        embeddingModel: 'models/gemini-embedding-2' 
                    }
                });
                this.clinicalStoreName = clinicalStore.name;
                console.log(`✅ Clinical Knowledge Store created: ${this.clinicalStoreName}`);
            }

            // Provide instructions for the developer to save these names
            console.log("---------------------------------------------------");
            console.log("Please save these Store Names to your .env file:");
            console.log(`RAG_USER_HISTORY_STORE=${this.userHistoryStoreName}`);
            console.log(`RAG_CLINICAL_STORE=${this.clinicalStoreName}`);
            console.log("---------------------------------------------------");

        } catch (error) {
            console.error("Failed to initialize RAG Stores:", error);
        }
    }

    /**
     * Helper to wait for file upload operation to complete
     */
    async _waitForOperation(operation) {
        let currentOperation = operation;
        while (!currentOperation.done) {
            await new Promise(resolve => setTimeout(resolve, 3000));
            currentOperation = await this.ai.operations.get({ operation: currentOperation });
        }
        return currentOperation;
    }

    /**
     * Uploads a user's historical journal entries and health data to the User History Store.
     * @param {string} userId - The user ID to tag the metadata with
     * @param {string} historyText - The formatted text of the user's history
     */
    async uploadUserHistory(userId, historyText) {
        if (!this.ai || !this.userHistoryStoreName) {
            throw new Error("RAG Service not initialized properly.");
        }

        // 1. Write the history to a temporary local file
        const tempFileName = `user_history_${userId}_${Date.now()}.txt`;
        const tempFilePath = path.join(os.tmpdir(), tempFileName);
        
        try {
            fs.writeFileSync(tempFilePath, historyText);

            // 2. Upload to the File Search Store
            console.log(`Uploading history for user ${userId} to RAG...`);
            let operation = await this.ai.fileSearchStores.uploadToFileSearchStore({
                file: tempFilePath,
                fileSearchStoreName: this.userHistoryStoreName,
                config: {
                    displayName: `History for ${userId}`,
                    customMetadata: [{ key: "userId", stringValue: userId }]
                }
            });

            // 3. Wait for processing
            await this._waitForOperation(operation);
            console.log(`✅ Successfully indexed history for user ${userId}`);

        } catch (error) {
            console.error(`Failed to upload history for user ${userId}:`, error);
            throw error;
        } finally {
            // Clean up temporary file
            if (fs.existsSync(tempFilePath)) {
                fs.unlinkSync(tempFilePath);
            }
        }
    }

    /**
     * Uploads a clinically validated reference PDF to the Clinical Knowledge Base Store.
     * @param {string} filePath - Path to the PDF file
     * @param {string} topic - The clinical topic (e.g., 'CBT', 'Anxiety')
     */
    async uploadClinicalDocument(filePath, topic) {
        if (!this.ai || !this.clinicalStoreName) {
            throw new Error("RAG Service not initialized properly.");
        }

        if (!fs.existsSync(filePath)) {
            throw new Error(`File not found: ${filePath}`);
        }

        try {
            const fileName = path.basename(filePath);
            console.log(`Uploading clinical reference '${fileName}' to RAG...`);
            
            let operation = await this.ai.fileSearchStores.uploadToFileSearchStore({
                file: filePath,
                fileSearchStoreName: this.clinicalStoreName,
                config: {
                    displayName: fileName,
                    customMetadata: [{ key: "topic", stringValue: topic }]
                }
            });

            await this._waitForOperation(operation);
            console.log(`✅ Successfully indexed clinical document: ${fileName}`);

        } catch (error) {
            console.error(`Failed to upload clinical document ${filePath}:`, error);
            throw error;
        }
    }

    getClinicalStoreName() {
        return this.clinicalStoreName;
    }

    getUserHistoryStoreName() {
        return this.userHistoryStoreName;
    }
}

module.exports = new RAGService();