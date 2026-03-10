#!/bin/bash
# ============================================================================
# Mini Remote — Slack Notifier
# Sends formatted Slack notifications via incoming webhook.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env" 2>/dev/null || true

# ---- Parse Arguments ----
STATUS=""
REPO=""
BRANCH=""
PROMPT=""
PROMPT_NUM=""
TOTAL_PROMPTS=""
DURATION=""
FILES_CHANGED=""
ADDITIONS=""
DELETIONS=""
COMMIT=""
NEXT_PROMPT=""
MESSAGE=""
COMPLETED=""
FAILED=""
TOTAL_FILES=""
TOTAL_ADDITIONS=""
TOTAL_DELETIONS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --status) STATUS="$2"; shift 2 ;;
        --repo) REPO="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --prompt) PROMPT="$2"; shift 2 ;;
        --prompt-num) PROMPT_NUM="$2"; shift 2 ;;
        --total-prompts) TOTAL_PROMPTS="$2"; shift 2 ;;
        --duration) DURATION="$2"; shift 2 ;;
        --files-changed) FILES_CHANGED="$2"; shift 2 ;;
        --additions) ADDITIONS="$2"; shift 2 ;;
        --deletions) DELETIONS="$2"; shift 2 ;;
        --commit) COMMIT="$2"; shift 2 ;;
        --next-prompt) NEXT_PROMPT="$2"; shift 2 ;;
        --message) MESSAGE="$2"; shift 2 ;;
        --completed) COMPLETED="$2"; shift 2 ;;
        --failed) FAILED="$2"; shift 2 ;;
        --total-files) TOTAL_FILES="$2"; shift 2 ;;
        --total-additions) TOTAL_ADDITIONS="$2"; shift 2 ;;
        --total-deletions) TOTAL_DELETIONS="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [ -z "$SLACK_WEBHOOK_URL" ]; then
    echo "Warning: SLACK_WEBHOOK_URL not set — skipping notification"
    exit 0
fi

# ---- Build Slack Message ----
case "$STATUS" in
    "completed")
        EMOJI="✅"
        TITLE="🤖 Mini Remote — Task Complete"
        
        QUEUE_LINE=""
        if [ -n "$NEXT_PROMPT" ]; then
            QUEUE_LINE="\n📋 Queue: $PROMPT_NUM/$TOTAL_PROMPTS done — next: \"$NEXT_PROMPT\""
        elif [ "$TOTAL_PROMPTS" -gt 1 ]; then
            QUEUE_LINE="\n📋 Queue: $PROMPT_NUM/$TOTAL_PROMPTS done — this was the last one!"
        fi
        
        PAYLOAD=$(cat << EOF
{
    "blocks": [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": "$TITLE"}
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": "📁 *Repo:* $REPO"},
                {"type": "mrkdwn", "text": "🌿 *Branch:* $BRANCH"},
                {"type": "mrkdwn", "text": "⏱️ *Duration:* $DURATION"},
                {"type": "mrkdwn", "text": "🔗 *Commit:* \`$COMMIT\`"}
            ]
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": "📝 *Prompt:* \"$PROMPT\""}
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": "$EMOJI *Status:* Completed\n📊 $FILES_CHANGED files changed, +$ADDITIONS -$DELETIONS$QUEUE_LINE"}
        }
    ]
}
EOF
        )
        ;;
    
    "failed")
        PAYLOAD=$(cat << EOF
{
    "blocks": [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": "🤖 Mini Remote — Task Failed"}
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": "📁 *Repo:* $REPO"},
                {"type": "mrkdwn", "text": "🌿 *Branch:* $BRANCH"},
                {"type": "mrkdwn", "text": "⏱️ *Duration:* $DURATION"},
                {"type": "mrkdwn", "text": "📋 *Queue:* $PROMPT_NUM/$TOTAL_PROMPTS"}
            ]
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": "📝 *Prompt:* \"$PROMPT\""}
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": "❌ *Error:* $MESSAGE"}
        }
    ]
}
EOF
        )
        ;;
    
    "blocked")
        PAYLOAD=$(cat << EOF
{
    "blocks": [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": "🤖 Mini Remote — Task Blocked"}
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": "📁 *Repo:* $REPO"},
                {"type": "mrkdwn", "text": "🌿 *Branch:* $BRANCH"}
            ]
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": "🛑 *Prompt:* \"$PROMPT\"\n\n⚠️ $MESSAGE"}
        }
    ]
}
EOF
        )
        ;;
    
    "queue-complete")
        FAIL_LINE=""
        if [ "$FAILED" -gt 0 ]; then
            FAIL_LINE="\n❌ *Failed:* $FAILED"
        fi
        
        PAYLOAD=$(cat << EOF
{
    "blocks": [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": "🏁 Mini Remote — All Tasks Complete"}
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": "📁 *Repo:* $REPO"},
                {"type": "mrkdwn", "text": "🌿 *Branch:* $BRANCH"},
                {"type": "mrkdwn", "text": "⏱️ *Total time:* $DURATION"},
                {"type": "mrkdwn", "text": "✅ *Completed:* $COMPLETED/$TOTAL_PROMPTS"}
            ]
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": "📊 $TOTAL_FILES files changed, +$TOTAL_ADDITIONS -$TOTAL_DELETIONS$FAIL_LINE\n\n_All changes pushed. Pull when ready._"}
        }
    ]
}
EOF
        )
        ;;
    
    *)
        PAYLOAD="{\"text\": \"🤖 Mini Remote: $MESSAGE\"}"
        ;;
esac

# ---- Send to Slack ----
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H 'Content-type: application/json' \
    --data "$PAYLOAD" \
    "$SLACK_WEBHOOK_URL")

if [ "$HTTP_CODE" = "200" ]; then
    echo "Slack notification sent ($STATUS)"
else
    echo "Warning: Slack returned HTTP $HTTP_CODE"
fi
