from database import (
    create_conversation,
    save_message,
    get_recent_messages,
    get_summary
)


print("=" * 60)
print("SUPABASE CHAT HISTORY TEST")
print("=" * 60)


# ============================================================
# 1. Create conversation
# ============================================================

conversation = create_conversation(
    user_id="test_user",
    title="Wheat Disease Test"
)

conversation_id = conversation["id"]

print("\nConversation created:")
print(conversation_id)


# ============================================================
# 2. Save user message
# ============================================================

save_message(
    conversation_id,
    "user",
    "What is yellow rust in wheat?"
)

print("\nUser message saved.")


# ============================================================
# 3. Save assistant message
# ============================================================

save_message(
    conversation_id,
    "assistant",
    "Yellow rust is a disease of wheat."
)

print("Assistant message saved.")


# ============================================================
# 4. Read messages
# ============================================================

messages = get_recent_messages(
    conversation_id
)

print("\nRecent messages:")

for message in messages:

    print(
        message["role"],
        ":",
        message["content"]
    )


# ============================================================
# 5. Read summary
# ============================================================

summary = get_summary(
    conversation_id
)

print("\nConversation summary:")
print(repr(summary))


print("\n" + "=" * 60)
print("SUPABASE TEST COMPLETE")
print("=" * 60)