// depresso-backend/src/services/textAnalysisService.js
const axios = require('axios');

/**
 * Unified Text Analysis Service
 * Analyzes all user text input for sentiment, CBT patterns, emotions, and risk flags
 */

// CBT Cognitive Distortion Patterns
const CBT_PATTERNS = {
    'all-or-nothing': {
        keywords: ['always', 'never', 'everyone', 'nobody', 'everything', 'nothing', 'completely', 'totally'],
        description: 'All-or-Nothing Thinking'
    },
    'overgeneralization': {
        keywords: ['every time', 'everyone does', 'no one ever', 'all the time', 'constantly'],
        description: 'Overgeneralization'
    },
    'catastrophizing': {
        keywords: ['disaster', 'terrible', 'awful', 'worst', 'ruined', 'destroyed', 'nightmare', 'horrible'],
        description: 'Catastrophizing'
    },
    'emotional-reasoning': {
        keywords: ['i feel like i am', 'i feel so', 'i feel like everyone', 'i feel worthless', 'i feel stupid'],
        description: 'Emotional Reasoning'
    },
    'should-statements': {
        keywords: ['should', 'must', 'ought to', 'have to', 'supposed to', 'need to'],
        description: 'Should Statements'
    },
    'labeling': {
        keywords: ['i am a loser', 'i am stupid', 'i am worthless', 'i am a failure', 'i am useless'],
        description: 'Labeling'
    },
    'personalization': {
        keywords: ['my fault', 'i caused', 'i made them', 'because of me', 'i am to blame'],
        description: 'Personalization'
    },
    'mental-filter': {
        keywords: ['only', 'just', 'except', 'but', 'however'],
        description: 'Mental Filter (focusing on negatives)'
    }
};

// Risk/Crisis Keywords
const CRISIS_KEYWORDS = [
    'suicide', 'kill myself', 'end my life', 'want to die', 
    'self harm', 'hurt myself', 'cutting', 'no reason to live',
    'better off dead', 'everyone would be better without me'
];

// Emotion Keywords
const EMOTION_PATTERNS = {
    anxious: ['anxious', 'worried', 'nervous', 'scared', 'afraid', 'panic', 'stress', 'overwhelmed'],
    sad: ['sad', 'depressed', 'down', 'unhappy', 'miserable', 'hopeless', 'empty', 'lonely'],
    angry: ['angry', 'mad', 'furious', 'irritated', 'frustrated', 'annoyed', 'rage'],
    hopeful: ['hopeful', 'optimistic', 'looking forward', 'excited', 'confident', 'positive'],
    grateful: ['grateful', 'thankful', 'blessed', 'appreciate', 'lucky', 'fortunate'],
    calm: ['calm', 'peaceful', 'relaxed', 'serene', 'content', 'tranquil'],
    motivated: ['motivated', 'determined', 'driven', 'inspired', 'energized', 'ambitious'],
    confused: ['confused', 'uncertain', 'unclear', 'lost', 'don\'t know', 'unsure']
};

// Positive/Negative word lists for sentiment
const POSITIVE_WORDS = [
    'happy', 'joy', 'love', 'great', 'good', 'wonderful', 'amazing', 'better',
    'improved', 'progress', 'success', 'accomplished', 'proud', 'grateful',
    'hopeful', 'optimistic', 'calm', 'peaceful', 'excited', 'motivated'
];

const NEGATIVE_WORDS = [
    'sad', 'depressed', 'anxious', 'worried', 'scared', 'angry', 'frustrated',
    'terrible', 'awful', 'bad', 'worse', 'fail', 'failure', 'hopeless',
    'worthless', 'useless', 'hate', 'hurt', 'pain', 'suffering'
];

/**
 * Main analysis function
 * @param {string} text - The text to analyze
 * @param {object} context - Additional context (typing speed, time of day, etc.)
 * @returns {object} - Complete analysis results
 */
exports.analyzeText = async (text, context = {}) => {
    const lowerText = text.toLowerCase();
    
    return {
        sentiment: detectSentiment(lowerText),
        sentimentScore: calculateSentimentScore(lowerText),
        cbtDistortions: detectCBTPatterns(lowerText),
        emotions: detectEmotions(lowerText),
        riskLevel: assessRiskLevel(lowerText),
        keywords: extractKeywords(lowerText),
        metadata: {
            wordCount: text.split(/\s+/).length,
            characterCount: text.length,
            typingSpeed: context.typingSpeed || null,
            sessionDuration: context.sessionDuration || null,
            timeOfDay: context.timeOfDay || null
        }
    };
};

/**
 * Detect sentiment: positive, neutral, or negative
 */
function detectSentiment(text) {
    const positiveCount = POSITIVE_WORDS.filter(word => text.includes(word)).length;
    const negativeCount = NEGATIVE_WORDS.filter(word => text.includes(word)).length;
    
    if (positiveCount > negativeCount + 2) return 'positive';
    if (negativeCount > positiveCount + 2) return 'negative';
    return 'neutral';
}

/**
 * Calculate sentiment score (0.0 = negative, 0.5 = neutral, 1.0 = positive)
 */
function calculateSentimentScore(text) {
    const positiveCount = POSITIVE_WORDS.filter(word => text.includes(word)).length;
    const negativeCount = NEGATIVE_WORDS.filter(word => text.includes(word)).length;
    const totalWords = text.split(/\s+/).length;
    
    if (totalWords === 0) return 0.5;
    
    const positiveRatio = positiveCount / totalWords;
    const negativeRatio = negativeCount / totalWords;
    
    // Score between 0 and 1
    const score = 0.5 + (positiveRatio * 5) - (negativeRatio * 5);
    return Math.max(0, Math.min(1, score));
}

/**
 * Detect CBT cognitive distortions
 */
function detectCBTPatterns(text) {
    const detected = [];
    
    for (const [key, pattern] of Object.entries(CBT_PATTERNS)) {
        const hasPattern = pattern.keywords.some(keyword => text.includes(keyword));
        if (hasPattern) {
            detected.push({
                type: key,
                description: pattern.description
            });
        }
    }
    
    return detected;
}

/**
 * Detect emotional tones
 */
function detectEmotions(text) {
    const detected = [];
    
    for (const [emotion, keywords] of Object.entries(EMOTION_PATTERNS)) {
        const matchCount = keywords.filter(keyword => text.includes(keyword)).length;
        if (matchCount > 0) {
            detected.push({
                emotion,
                confidence: Math.min(matchCount / keywords.length, 1.0)
            });
        }
    }
    
    // Sort by confidence
    return detected.sort((a, b) => b.confidence - a.confidence).slice(0, 3);
}

/**
 * Assess risk level based on crisis keywords
 */
function assessRiskLevel(text) {
    const hasCrisisKeyword = CRISIS_KEYWORDS.some(keyword => text.includes(keyword));
    
    if (hasCrisisKeyword) {
        return 'high';
    }
    
    // Check for multiple negative indicators
    const negativeCount = NEGATIVE_WORDS.filter(word => text.includes(word)).length;
    const totalWords = text.split(/\s+/).length;
    
    if (negativeCount > totalWords * 0.3) {
        return 'caution';
    }
    
    return 'safe';
}

/**
 * Extract important keywords (simple frequency-based)
 */
function extractKeywords(text) {
    const words = text
        .toLowerCase()
        .replace(/[^\w\s]/g, '')
        .split(/\s+/)
        .filter(word => word.length > 4); // Only words longer than 4 chars
    
    // Count frequencies
    const frequency = {};
    words.forEach(word => {
        frequency[word] = (frequency[word] || 0) + 1;
    });
    
    // Get top 5
    return Object.entries(frequency)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([word]) => word);
}

/**
 * Quick sentiment check (for real-time feedback)
 */
exports.quickSentimentCheck = (text) => {
    const lowerText = text.toLowerCase();
    return {
        sentiment: detectSentiment(lowerText),
        score: calculateSentimentScore(lowerText)
    };
};

module.exports = exports;
