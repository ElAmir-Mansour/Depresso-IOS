// Features/Dashboard/Core/Network/APIClient.swift
import Foundation
import ComposableArchitecture

// MARK: - API Configuration
enum APIConfig {
    // 🌍 PRODUCTION: Use this once you deploy to Koyeb/Render/Vercel
    static let baseURL = "https://depresso-ios.vercel.app/api/v1"
    
    // 💻 SIMULATOR: Local testing
    // static let baseURL = "http://localhost:3000/api/v1"
    
    // 📱 PHYSICAL DEVICE: Local testing (Your Mac's IP)
    // static let baseURL = "http://192.168.1.6:3000/api/v1"
}

// MARK: - API Errors
enum APIError: Error, Equatable {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case serverError(Int, String)
    case noData
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Client
struct APIClient {
    // Custom session with longer timeout for AI requests
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // 2 minutes
        config.timeoutIntervalForResource = 300 // 5 minutes
        return URLSession(configuration: config)
    }()

    // Generic request function
    // This is the core function that all API calls will use
    private static func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable? = nil
    ) async throws -> T {
        // Step 1: Build the URL
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        // Step 2: Configure the request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Step 2.5: Add authentication token if available
        if let token = await MainActor.run(body: { UserManager.shared.sessionToken }) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Step 3: Add body if provided (for POST/PUT requests)
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // Step 4: Make the network call using custom session
        let (data, response) = try await session.data(for: request)
        
        // Step 5: Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        // Step 6: Handle 204 No Content
        if httpResponse.statusCode == 204 || data.isEmpty {
            // For empty responses, return empty EmptyResponse
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
        }
        
        // Step 7: Decode the response
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - User Registration
    // Call this once when app first launches
    static func registerUser() async throws -> String {
        struct Response: Codable {
            let userId: String
        }
        
        let response: Response = try await request(
            endpoint: "/users/register",
            method: .post
        )
        
        return response.userId
    }
    
    // MARK: - Metrics Submission
    static func submitMetrics(
        userId: String,
        dailyMetrics: DailyMetrics,
        typingMetrics: TypingMetrics,
        motionMetrics: DeviceMotionMetrics
    ) async throws {
        struct Request: Codable {
            let userId: String
            let dailyMetrics: DailyMetricsDTO
            let typingMetrics: TypingMetricsDTO
            let motionMetrics: MotionMetricsDTO
        }
        
        // Convert your domain models to DTOs (Data Transfer Objects)
        let request = Request(
            userId: userId,
            dailyMetrics: DailyMetricsDTO(
                steps: dailyMetrics.steps,
                activeEnergy: dailyMetrics.activeEnergy,
                heartRate: dailyMetrics.heartRate
            ),
            typingMetrics: TypingMetricsDTO(
                wordsPerMinute: typingMetrics.wordsPerMinute,
                totalEditCount: typingMetrics.totalEditCount
            ),
            motionMetrics: MotionMetricsDTO(
                avgAccelerationX: motionMetrics.avgAccelerationX,
                avgAccelerationY: motionMetrics.avgAccelerationY,
                avgAccelerationZ: motionMetrics.avgAccelerationZ
            )
        )
        
        // Void response means we just check for errors
        let _: EmptyResponse = try await APIClient.request(
            endpoint: "/metrics/submit",
            method: .post,
            body: request
        )
    }
    
    // MARK: - Journal Entries
    static func createJournalEntry(
        userId: String,
        title: String?,
        content: String
    ) async throws -> JournalEntryDTO {
        struct Request: Codable {
            let userId: String
            let title: String?
            let content: String
        }
        
        return try await request(
            endpoint: "/journal/entries",
            method: .post,
            body: Request(userId: userId, title: title, content: content)
        )
    }
    
    static func addMessageToEntry(
        entryId: Int,
        userId: String,
        sender: String,
        content: String
    ) async throws -> AIChatMessageDTO {
        struct Request: Codable {
            let userId: String
            let sender: String
            let content: String
        }
        
        return try await request(
            endpoint: "/journal/entries/\(entryId)/messages",
            method: .post,
            body: Request(userId: userId, sender: sender, content: content)
        )
    }

    static func getMessages(entryId: Int) async throws -> [AIChatMessageDTO] {
        return try await request(
            endpoint: "/journal/entries/\(entryId)/messages",
            method: .get
        )
    }
    
    // MARK: - Community Posts
    static func getAllPosts() async throws -> [CommunityPostDTO] {
        return try await request(
            endpoint: "/community/posts",
            method: .get
        )
    }
    
    static func createPost(
        userId: String,
        title: String,
        content: String
    ) async throws -> CommunityPostDTO {
        struct Request: Codable {
            let userId: String
            let title: String
            let content: String
        }
        
        return try await request(
            endpoint: "/community/posts",
            method: .post,
            body: Request(userId: userId, title: title, content: content)
        )
    }
    
    static func likePost(postId: String, userId: String) async throws {
        struct Request: Codable {
            let userId: String
        }
        
        let _: EmptyResponse = try await request(
            endpoint: "/community/posts/\(postId)/like",
            method: .post,
body: Request(userId: userId)
        )
    }
    
    static func unlikePost(postId: String, userId: String) async throws {
        struct Request: Codable {
            let userId: String
        }
        
        let _: EmptyResponse = try await request(
            endpoint: "/community/posts/\(postId)/like",
            method: .delete,
            body: Request(userId: userId)
        )
    }
    
    // NEW: Get user's liked posts
    static func getLikedPosts(userId: String) async throws -> [String] {
        struct Response: Codable {
            let likedPostIds: [String]
        }
        
        let response: Response = try await request(
            endpoint: "/community/posts/liked?userId=\(userId)",
            method: .get
        )
        
        return response.likedPostIds
    }
    
    // MARK: - Assessments
    static func submitAssessment(
        userId: String,
        assessmentType: String,
        score: Int,
        answers: [Int]?
    ) async throws -> AssessmentDTO {
        struct Request: Codable {
            let userId: String
            let assessmentType: String
            let score: Int
            let answers: [Int]?
        }
        
        return try await request(
            endpoint: "/assessments",
            method: .post,
            body: Request(
                userId: userId,
                assessmentType: assessmentType,
                score: score,
                answers: answers
            )
        )
    }
    
    // NEW: Get user's streak
    static func getStreak(userId: String) async throws -> (current: Int, longest: Int) {
        struct Response: Codable {
            let currentStreak: Int
            let longestStreak: Int
        }
        
        let response: Response = try await request(
            endpoint: "/assessments/streak?userId=\(userId)",
            method: .get
        )
        
        return (current: response.currentStreak, longest: response.longestStreak)
    }
    
    // MARK: - User Profile
    
    // NEW: Get user profile
    static func getUserProfile(userId: String) async throws -> UserProfileDTO {
        return try await request(
            endpoint: "/users/profile/\(userId)",
            method: .get
        )
    }
    
    // NEW: Update user profile
    static func updateUserProfile(
        userId: String,
        name: String?,
        avatarUrl: String?,
        bio: String?
    ) async throws -> UserProfileDTO {
        struct Request: Codable {
            let name: String?
            let avatarUrl: String?
            let bio: String?
        }
        
        return try await request(
            endpoint: "/users/profile/\(userId)",
            method: .put,
            body: Request(name: name, avatarUrl: avatarUrl, bio: bio)
        )
    }
    
    // NEW: Delete user account
    static func deleteAccount(userId: String) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "/users/\(userId)",
            method: .delete
        )
    }
    
    // MARK: - Authentication (Apple Sign In)
    static func appleLogin(appleUserId: String, email: String?, fullName: String?, identityToken: String?) async throws -> (userId: String, sessionToken: String, isNewUser: Bool, name: String?, email: String?) {
        struct Request: Codable {
            let appleUserId: String
            let email: String?
            let fullName: String?
            let identityToken: String?
        }
        
        struct Response: Codable {
            let userId: String
            let sessionToken: String
            let isNewUser: Bool
            let name: String?
            let email: String?
        }
        
        let response: Response = try await request(
            endpoint: "/users/auth/apple",
            method: .post,
            body: Request(
                appleUserId: appleUserId,
                email: email,
                fullName: fullName,
                identityToken: identityToken
            )
        )
        
        return (response.userId, response.sessionToken, response.isNewUser, response.name, response.email)
    }
    
    static func linkAppleAccount(userId: String, appleUserId: String, email: String?, fullName: String?, identityToken: String?) async throws -> String {
        struct Request: Codable {
            let userId: String
            let appleUserId: String
            let email: String?
            let fullName: String?
            let identityToken: String?
        }
        
        struct Response: Codable {
            let success: Bool
            let sessionToken: String
        }
        
        let response: Response = try await request(
            endpoint: "/users/auth/apple/link",
            method: .post,
            body: Request(
                userId: userId,
                appleUserId: appleUserId,
                email: email,
                fullName: fullName,
                identityToken: identityToken
            )
        )
        
        return response.sessionToken
    }
    
    // MARK: - Analytics
    static func trackAnalytics(userId: String, eventType: String, postId: String?) async throws {
        struct Request: Codable {
            let userId: String
            let eventType: String
            let postId: String?
        }
        
        let _: EmptyResponse = try await request(
            endpoint: "/metrics/analytics",
            method: .post,
            body: Request(userId: userId, eventType: eventType, postId: postId)
        )
    }
    
    // MARK: - Research
    static func submitResearchEntry(
        userId: String,
        promptId: String,
        content: String,
        sentimentLabel: String,
        tags: [String],
        metadata: ResearchMetadataDTO
    ) async throws {
        struct Request: Codable {
            let userId: String
            let promptId: String
            let content: String
            let sentimentLabel: String
            let tags: [String]
            let metadata: ResearchMetadataDTO
        }
        
        let _: EmptyResponse = try await request(
            endpoint: "/research/entries",
            method: .post,
            body: Request(
                userId: userId,
                promptId: promptId,
                content: content,
                sentimentLabel: sentimentLabel,
                tags: tags,
                metadata: metadata
            )
        )
    }
    
    // MARK: - Unified Analysis
    
    static func submitForAnalysis(
        userId: String,
        source: String,
        content: String,
        originalId: String?,
        context: AnalysisContext?
    ) async throws -> AnalyzedEntryDTO {
        struct RequestBody: Codable {
            let userId: String
            let source: String
            let content: String
            let originalId: String?
            let context: AnalysisContext?
        }
        
        return try await request(
            endpoint: "/analysis/submit",
            method: .post,
            body: RequestBody(userId: userId, source: source, content: content, originalId: originalId, context: context)
        )
    }
    
    static func getAnalysisTrends(userId: String, days: Int = 30) async throws -> AnalysisTrendsDTO {
        return try await request(
            endpoint: "/analysis/trends?userId=\(userId)&days=\(days)",
            method: .get
        )
    }
    
    static func getAnalysisInsights(userId: String) async throws -> AnalysisInsightsDTO {
        return try await request(
            endpoint: "/analysis/insights?userId=\(userId)",
            method: .get
        )
    }
    
    static func getCommunityTrending(days: Int = 7, limit: Int = 10) async throws -> [CommunityPostDTO] {
        return try await request(
            endpoint: "/community/trending?days=\(days)&limit=\(limit)",
            method: .get
        )
    }
    
    static func getCommunityStats() async throws -> CommunityStatsDTO {
        return try await request(
            endpoint: "/community/stats",
            method: .get
        )
    }
}

// MARK: - Data Transfer Objects (DTOs)
// These match your backend response structure

struct EmptyResponse: Codable {}

struct DailyMetricsDTO: Codable {
    let steps: Double
    let activeEnergy: Double
    let heartRate: Double
}

struct TypingMetricsDTO: Codable {
    let wordsPerMinute: Double
    let totalEditCount: Int
}

struct MotionMetricsDTO: Codable {
    let avgAccelerationX: Double
    let avgAccelerationY: Double
    let avgAccelerationZ: Double
}

struct JournalEntryDTO: Codable {
    let id: Int
    let userId: String
    let title: String?
    let content: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case createdAt = "created_at"
    }
}

struct AIChatMessageDTO: Codable {
    let id: Int
    let entryId: Int
    let userId: String
    let sender: String
    let content: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case entryId = "entry_id"
        case userId = "user_id"
        case sender
        case content
        case createdAt = "created_at"
    }
}

struct CommunityPostDTO: Codable, Equatable {
    let id: String
    let title: String?
    let content: String
    let likeCount: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case likeCount = "like_count"
        case createdAt = "created_at"
    }
}

struct AssessmentDTO: Codable {
    let id: Int
    let userId: String
    let assessmentType: String
    let score: Int
    let answers: [Int]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case assessmentType = "assessment_type"
        case score
        case answers
        case createdAt = "created_at"
    }
}

struct UserProfileDTO: Codable {
    let id: String
    let name: String?
    let avatarUrl: String?
    let bio: String?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatarUrl = "avatar_url"
        case bio
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Analysis DTOs

struct AnalysisContext: Codable {
    let typingSpeed: Double?
    let sessionDuration: Double?
    let editCount: Int?
    let timeOfDay: String?
}

struct AnalyzedEntryDTO: Codable {
    let entry: UnifiedEntryDTO
    let analysis: TextAnalysisDTO
}

struct UnifiedEntryDTO: Codable {
    let id: String
    let userId: String
    let source: String
    let content: String
    let sentiment: String?
    let sentimentScore: Double?
    let emotionTags: [String]?
    let keywords: [String]?
    let riskLevel: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, content, sentiment, keywords
        case userId = "user_id"
        case source
        case sentimentScore = "sentiment_score"
        case emotionTags = "emotion_tags"
        case riskLevel = "risk_level"
        case createdAt = "created_at"
    }
}

struct TextAnalysisDTO: Codable {
    let sentiment: String
    let sentimentScore: Double
    let cbtDistortions: [CBTDistortionDTO]
    let emotions: [EmotionDTO]
    let riskLevel: String
    let keywords: [String]
    let metadata: AnalysisMetadataDTO
}

struct CBTDistortionDTO: Codable {
    let type: String
    let description: String
}

struct EmotionDTO: Codable {
    let emotion: String
    let confidence: Double
}

struct AnalysisMetadataDTO: Codable {
    let wordCount: Int
    let characterCount: Int
    let typingSpeed: Double?
    let sessionDuration: Double?
    let timeOfDay: String?
}

struct AnalysisTrendsDTO: Codable, Equatable {
    let sentimentTimeline: [SentimentTimelineDTO]
    let cbtPatterns: [CBTPatternFrequencyDTO]
    let emotions: [EmotionFrequencyDTO]
}

struct SentimentTimelineDTO: Codable, Equatable {
    let date: Date
    let avgSentiment: Double
    let entryCount: Int
    
    enum CodingKeys: String, CodingKey {
        case date
        case avgSentiment = "avg_sentiment"
        case entryCount = "entry_count"
    }
}

struct CBTPatternFrequencyDTO: Codable, Equatable {
    let distortionType: String?
    let description: String?
    let frequency: Int
    
    enum CodingKeys: String, CodingKey {
        case distortionType = "distortion_type"
        case description, frequency
    }
}

struct EmotionFrequencyDTO: Codable, Equatable {
    let emotion: String
    let count: Int
}

struct AnalysisInsightsDTO: Codable, Equatable {
    let overview: AnalysisOverviewDTO
    let topDistortions: [CBTPatternFrequencyDTO]
    let weeklyComparison: WeeklyComparisonAnalysisDTO
}

struct AnalysisOverviewDTO: Codable, Equatable {
    let totalEntries: Int
    let avgSentiment: Double
    let positiveCount: Int
    let negativeCount: Int
    let avgTypingSpeed: Double?
    let avgWordCount: Double?
    
    enum CodingKeys: String, CodingKey {
        case totalEntries = "total_entries"
        case avgSentiment = "avg_sentiment"
        case positiveCount = "positive_count"
        case negativeCount = "negative_count"
        case avgTypingSpeed = "avg_typing_speed"
        case avgWordCount = "avg_word_count"
    }
}

struct WeeklyComparisonAnalysisDTO: Codable, Equatable {
    let thisWeek: Double
    let lastWeek: Double
    let improvement: Double
    let isImproving: Bool
}

struct CommunityStatsDTO: Codable, Equatable {
    let overview: CommunityOverviewDTO
    let sentimentDistribution: [SentimentDistributionDTO]
}

struct CommunityOverviewDTO: Codable, Equatable {
    let totalPosts: Int
    let totalLikes: Int
    let avgLikesPerPost: Double
    let activeUsers: Int
    let postsThisWeek: Int
    let postsToday: Int
    
    enum CodingKeys: String, CodingKey {
        case totalPosts = "total_posts"
        case totalLikes = "total_likes"
        case avgLikesPerPost = "avg_likes_per_post"
        case activeUsers = "active_users"
        case postsThisWeek = "posts_this_week"
        case postsToday = "posts_today"
    }
}

struct SentimentDistributionDTO: Codable, Equatable {
    let sentiment: String
    let count: Int
    let avgScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case sentiment, count
        case avgScore = "avg_score"
    }
}

struct ResearchMetadataDTO: Codable {
    let typingSpeed: Double
    let sessionDuration: Double
    let timeOfDay: String
    let deviceModel: String
}
