import Foundation

// MARK: - Empty Response (for endpoints with no meaningful return)

private struct MessageEmptyResponse: Decodable {}

// MARK: - Request Bodies

private struct SendMessageBody: Encodable {
    let characterId: String
    let targetId: String
    let content: String
    let action = "send"

    enum CodingKeys: String, CodingKey {
        case characterId = "character_id"
        case targetId = "target_id"
        case content
        case action
    }
}

private struct SendQuickMessageBody: Encodable {
    let characterId: String
    let targetId: String
    let quickId: String
    let action = "send_quick"

    enum CodingKeys: String, CodingKey {
        case characterId = "character_id"
        case targetId = "target_id"
        case quickId = "quick_id"
        case action
    }
}

private struct MarkReadBody: Encodable {
    let characterId: String
    let senderId: String
    let action = "mark_read"

    enum CodingKeys: String, CodingKey {
        case characterId = "character_id"
        case senderId = "sender_id"
        case action
    }
}

@MainActor
final class MessageService {
    static let shared = MessageService()
    private init() {}

    // MARK: - Get Conversations List

    /// Fetches all conversations for a character (grouped by other character, sorted by unread first).
    /// - Parameter characterId: The character ID
    /// - Returns: Array of Conversation objects
    func getConversations(characterId: String) async throws -> [Conversation] {
        do {
            let response: ConversationsResponse = try await APIClient.shared.get(
                APIEndpoints.socialMessages,
                params: ["character_id": characterId]
            )
            return response.conversations
        } catch {
            #if DEBUG
            print("[MessageService] getConversations error: \(error)")
            #endif
            throw error
        }
    }

    // MARK: - Get Thread (Messages with specific character)

    /// Fetches all messages in a conversation thread with another character.
    /// Automatically marks all received messages from that character as read.
    /// - Parameters:
    ///   - characterId: The current character ID
    ///   - withCharacterId: The other character's ID
    /// - Returns: Array of DirectMessageItem objects (chronologically ordered)
    func getThread(characterId: String, withCharacterId: String) async throws -> [DirectMessageItem] {
        do {
            let response: MessagesResponse = try await APIClient.shared.get(
                APIEndpoints.socialMessages,
                params: [
                    "character_id": characterId,
                    "with": withCharacterId
                ]
            )
            return response.messages
        } catch {
            #if DEBUG
            print("[MessageService] getThread error: \(error)")
            #endif
            throw error
        }
    }

    // MARK: - Send Message

    /// Sends a text message to another character.
    /// Requires both characters to be friends (accepted friendship in either direction).
    /// - Parameters:
    ///   - characterId: The sender's character ID
    ///   - targetId: The recipient's character ID
    ///   - content: The message text (max 200 characters)
    /// - Returns: SentMessageInfo with message details
    func sendMessage(
        characterId: String,
        targetId: String,
        content: String
    ) async throws -> SentMessageInfo {
        do {
            let body = SendMessageBody(characterId: characterId, targetId: targetId, content: content)
            let response: SendMessageResponse = try await APIClient.shared.post(
                APIEndpoints.socialMessages,
                body: body
            )
            return response.message
        } catch {
            #if DEBUG
            print("[MessageService] sendMessage error: \(error)")
            #endif
            throw error
        }
    }

    // MARK: - Send Quick Message

    /// Sends a predefined quick message to another character.
    /// Available quick messages: gg, rematch, thanks, nice_fight, well_played, haha, wow, oops.
    /// Requires both characters to be friends (accepted friendship in either direction).
    /// - Parameters:
    ///   - characterId: The sender's character ID
    ///   - targetId: The recipient's character ID
    ///   - quickId: The ID of the quick message (e.g., "gg", "rematch")
    /// - Returns: SentMessageInfo with message details
    func sendQuickMessage(
        characterId: String,
        targetId: String,
        quickId: String
    ) async throws -> SentMessageInfo {
        do {
            let body = SendQuickMessageBody(characterId: characterId, targetId: targetId, quickId: quickId)
            let response: SendMessageResponse = try await APIClient.shared.post(
                APIEndpoints.socialMessages,
                body: body
            )
            return response.message
        } catch {
            #if DEBUG
            print("[MessageService] sendQuickMessage error: \(error)")
            #endif
            throw error
        }
    }

    // MARK: - Mark Read

    /// Marks all unread messages from a specific sender as read.
    /// - Parameters:
    ///   - characterId: The current character ID (receiver)
    ///   - senderId: The sender's character ID (whose messages to mark as read)
    func markRead(characterId: String, senderId: String) async throws {
        do {
            let body = MarkReadBody(characterId: characterId, senderId: senderId)
            let _: MessageEmptyResponse = try await APIClient.shared.post(
                APIEndpoints.socialMessages,
                body: body
            )
        } catch {
            #if DEBUG
            print("[MessageService] markRead error: \(error)")
            #endif
            throw error
        }
    }
}
