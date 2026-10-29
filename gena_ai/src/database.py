import os
import uuid
from datetime import datetime, timezone
from pathlib import Path
from dotenv import load_dotenv

# Ensure .env is loaded from gena_ai parent folder if present
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / ".env"
if ENV_PATH.exists():
    load_dotenv(dotenv_path=ENV_PATH)
else:
    load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase = None
if SUPABASE_URL and SUPABASE_KEY:
    try:
        # pyrefly: ignore [missing-import]
        from supabase import create_client, ClientOptions
        supabase = create_client(
            SUPABASE_URL,
            SUPABASE_KEY,
            options=ClientOptions(
                postgrest_client_timeout=1.5,
                storage_client_timeout=1.5,
                function_client_timeout=1.5
            )
        )
    except Exception as e:
        print(f"[Database] Warning: Failed to initialize Supabase client: {e}")

# In-memory storage fallback when Supabase is unreachable or paused
_local_conversations = {}
_local_messages = {}


# ============================================================
# 3. Create conversation
# ============================================================

def create_conversation(
    user_id=None,
    title="New Conversation"
):
    conv_id = str(uuid.uuid4())
    data = {
        "id": conv_id,
        "title": title,
        "summary": "",
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    if user_id:
        data["user_id"] = user_id
    _local_conversations[conv_id] = data

    if supabase is not None:
        try:
            insert_data = {"title": title, "summary": ""}
            if user_id:
                insert_data["user_id"] = user_id
            response = (
                supabase
                .table("conversations")
                .insert(insert_data)
                .execute()
            )
            if response.data and len(response.data) > 0:
                remote_data = response.data[0]
                _local_conversations[remote_data["id"]] = remote_data
                return remote_data
        except Exception as e:
            print(f"[Database] Supabase create_conversation failed ({e}), using local session")

    # Local fallback
    return data


# ============================================================
# 4. Save message
# ============================================================

def save_message_local(
    conversation_id,
    role,
    content
):
    local_record = {
        "conversation_id": conversation_id,
        "role": role,
        "content": content,
        "created_at": datetime.now(timezone.utc).isoformat()
    }

    # Ensure in-memory store has it immediately (0ms delay)
    if conversation_id not in _local_messages:
        _local_messages[conversation_id] = []
    _local_messages[conversation_id].append(local_record)
    return local_record


def persist_message_to_supabase(
    conversation_id,
    role,
    content
):
    if supabase is not None:
        try:
            response = (
                supabase
                .table("messages")
                .insert({
                    "conversation_id": conversation_id,
                    "role": role,
                    "content": content
                })
                .execute()
            )
            if response.data and len(response.data) > 0:
                return response.data[0]
        except Exception as e:
            print(f"[Database] Supabase background save_message failed ({e}), local store intact")
    return None


def save_message(
    conversation_id,
    role,
    content
):
    local_record = save_message_local(conversation_id, role, content)
    persist_message_to_supabase(conversation_id, role, content)
    return local_record


# ============================================================
# 5. Get recent messages
# ============================================================

def get_recent_messages(
    conversation_id,
    limit=10
):
    # Check local in-memory cache first to eliminate unnecessary network latency
    local_msgs = _local_messages.get(conversation_id, [])
    if local_msgs:
        return local_msgs[-limit:]

    if supabase is not None:
        try:
            response = (
                supabase
                .table("messages")
                .select("role, content, created_at")
                .eq("conversation_id", conversation_id)
                .order("created_at", desc=True)
                .limit(limit)
                .execute()
            )
            messages = response.data or []
            if messages:
                messages.reverse()
                return messages
        except Exception as e:
            print(f"[Database] Supabase get_recent_messages failed ({e}), using local store")

    # Local fallback
    return local_msgs[-limit:]


# ============================================================
# 6. Get conversation
# ============================================================

def get_conversation(
    conversation_id
):
    if supabase is not None:
        try:
            response = (
                supabase
                .table("conversations")
                .select("*")
                .eq("id", conversation_id)
                .single()
                .execute()
            )
            return response.data
        except Exception as e:
            pass

    return _local_conversations.get(conversation_id)


# ============================================================
# 7. Get conversation summary
# ============================================================

def get_summary(
    conversation_id
):
    conversation = get_conversation(conversation_id)
    if not conversation:
        return ""
    return conversation.get("summary", "")


# ============================================================
# 8. Update conversation summary
# ============================================================

def update_summary(
    conversation_id,
    summary
):
    if supabase is not None:
        try:
            response = (
                supabase
                .table("conversations")
                .update({"summary": summary})
                .eq("id", conversation_id)
                .execute()
            )
            return response.data
        except Exception as e:
            pass

    if conversation_id in _local_conversations:
        _local_conversations[conversation_id]["summary"] = summary
    return None


# ============================================================
# 9. Conversation language state management
# ============================================================

_conversation_languages = {}

def set_conversation_language(
    conversation_id: str,
    language: str
):
    if not conversation_id:
        return
    _conversation_languages[conversation_id] = language
    if conversation_id in _local_conversations:
        _local_conversations[conversation_id]["language"] = language
    if supabase is not None:
        try:
            supabase.table("conversations").update({"language": language}).eq("id", conversation_id).execute()
        except Exception:
            pass


def get_conversation_language(
    conversation_id: str
):
    if not conversation_id:
        return None
    if conversation_id in _conversation_languages:
        return _conversation_languages[conversation_id]
    if conversation_id in _local_conversations:
        return _local_conversations[conversation_id].get("language")
    if supabase is not None:
        try:
            res = (
                supabase
                .table("conversations")
                .select("language")
                .eq("id", conversation_id)
                .single()
                .execute()
            )
            if res.data and "language" in res.data and res.data["language"]:
                _conversation_languages[conversation_id] = res.data["language"]
                return res.data["language"]
        except Exception:
            pass
    return None