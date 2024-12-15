
struct ConversationItem: Decodable {
    let id: String?
    let title: String?
    let create_time: String
    let update_time: String
    let mapping: String?
    let current_node: String?
    let conversation_template_id: String?
    let gizmo_id: String?
    let is_archived: Bool
    let is_starred: Bool?
    let is_unread: Bool?
    let workspace_id: String?
    let async_status: String?
    let safe_urls: [String]?
    let conversation_origin: String?
    let snippet: String?
}

struct ConversationHistory: Decodable {
    let items: [ConversationItem]
}
struct Message: Decodable {
    let title: String?
    let create_time: Double?
    let update_time: Double?
    let mapping: [String: MessageNode]?
}

struct MessageNode: Decodable {
    let id: String
    let message: MessageContent?
    let parent: String?
    let children: [String]
}

struct MessageContent: Decodable {
    let id: String?
    let author: Author?
    let create_time: Double?
    let update_time: Double?
    let content: InnerContent?
    let status: String?
    let end_turn: Bool?
    let weight: Double?
    let metadata: MessageMetadata?
    let recipient: String?
    let channel: String?
}

struct Author: Decodable {
    let role: String
    let name: String?
    let metadata: [String: String]
}

struct InnerContent: Decodable {
    let content_type: String
    let parts: [ContentPartEnum?]?
}

enum ContentPartEnum: Decodable {
    case contentPart(ContentPart)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let contentPart = try? container.decode(ContentPart.self) {
            self = .contentPart(contentPart)
        } else {
            throw DecodingError.typeMismatch(
                ContentPartEnum.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or ContentPart"
                )
            )
        }
    }
}

struct ContentPart: Decodable {
    let content_type: String?
    let text: String?
    let direction: String?
    let decoding_id: String?
    let expiry_datetime: String?
    let frames_asset_pointers: [String]?
    let video_container_asset_pointer: String?
    let audio_asset_pointer: AudioAssetPointer?
    let audio_start_timestamp: Double?
}

struct AudioAssetPointer: Decodable {
    let expiry_datetime: String?
    let content_type: String
    let asset_pointer: String
    let size_bytes: Int
    let format: String
    let metadata: AudioMetadata
}

struct AudioMetadata: Decodable {
    let start_timestamp: Double?
    let end_timestamp: Double?
    let pretokenized_vq: String?
    let interruptions: String?
    let original_audio_source: String?
    let transcription: String?
    let start: Double?
    let end: Double?
}

struct MessageMetadata: Decodable {
    let voice_mode_message: Bool?
    let request_id: String?
    let message_source: String?
    let timestamp_: String?
    let message_type: String?
    let real_time_audio_has_video: Bool?
    let is_visually_hidden_from_conversation: Bool?
    let citations: [String]?
    let content_references: [String]?
    let is_complete: Bool?
    let parent_id: String?
    let model_switcher_deny: [ModelSwitcherDeny]?
}

struct ModelSwitcherDeny: Decodable {
    let slug: String
    let context: String
    let reason: String
    let description: String
}
