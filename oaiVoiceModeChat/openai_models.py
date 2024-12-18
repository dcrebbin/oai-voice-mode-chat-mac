from pydantic import BaseModel
from typing import List, Optional, Union

class ConversationItem(BaseModel):
    id: Optional[str]
    title: Optional[str]
    create_time: str
    update_time: str
    mapping: Optional[str]
    current_node: Optional[str]
    conversation_template_id: Optional[str]
    gizmo_id: Optional[str]
    is_archived: bool
    is_starred: Optional[bool]
    is_unread: Optional[bool]
    workspace_id: Optional[str]
    async_status: Optional[str]
    safe_urls: Optional[List[str]]
    conversation_origin: Optional[str]
    snippet: Optional[str]

class ConversationHistory(BaseModel):
    items: List[ConversationItem]

class Message(BaseModel):
    title: Optional[str]
    create_time: Optional[float]
    update_time: Optional[float]
    mapping: Optional[dict]

class MessageNode(BaseModel):
    id: str
    message: Optional['MessageContent']
    parent: Optional[str]
    children: List[str]

class MessageContent(BaseModel):
    id: Optional[str]
    author: Optional['Author']
    create_time: Optional[float]
    update_time: Optional[float]
    content: Optional['InnerContent']
    status: Optional[str]
    end_turn: Optional[bool]
    weight: Optional[float]
    metadata: Optional['MessageMetadata']
    recipient: Optional[str]
    channel: Optional[str]

class Author(BaseModel):
    role: str
    name: Optional[str]
    metadata: dict

class InnerContent(BaseModel):
    content_type: str
    parts: Optional[List[Union[str, 'ContentPart']]]

class ContentPart(BaseModel):
    content_type: Optional[str]
    text: Optional[str]
    direction: Optional[str]
    decoding_id: Optional[str]
    expiry_datetime: Optional[str]
    frames_asset_pointers: Optional[List[str]]
    video_container_asset_pointer: Optional[str]
    audio_asset_pointer: Optional['AudioAssetPointer']
    audio_start_timestamp: Optional[float]

class AudioAssetPointer(BaseModel):
    expiry_datetime: Optional[str]
    content_type: str
    asset_pointer: str
    size_bytes: int
    format: str
    metadata: 'AudioMetadata'

class AudioMetadata(BaseModel):
    start_timestamp: Optional[float]
    end_timestamp: Optional[float]
    pretokenized_vq: Optional[str]
    interruptions: Optional[str]
    original_audio_source: Optional[str]
    transcription: Optional[str]
    start: Optional[float]
    end: Optional[float]

class MessageMetadata(BaseModel):
    voice_mode_message: Optional[bool]
    request_id: Optional[str]
    message_source: Optional[str]
    timestamp_: Optional[str]
    message_type: Optional[str]
    real_time_audio_has_video: Optional[bool]
    is_visually_hidden_from_conversation: Optional[bool]
    citations: Optional[List[str]]
    content_references: Optional[List[str]]
    is_complete: Optional[bool]
    parent_id: Optional[str]
    model_switcher_deny: Optional[List['ModelSwitcherDeny']]

class ModelSwitcherDeny(BaseModel):
    slug: str
    context: str
    reason: str
    description: str
