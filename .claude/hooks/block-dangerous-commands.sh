#!/bin/bash
# PreToolUse hook: blocks dangerous bash commands

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [ "$TOOL" = "Bash" ]; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  if echo "$CMD" | grep -qE 'rm\s+-rf'; then
    echo '{"decision": "block", "reason": "Use trash instead of rm -rf"}'
    exit 0
  fi

  if echo "$CMD" | grep -qE 'git\s+push\s+.*(main|master)'; then
    echo '{"decision": "block", "reason": "Push to a feature branch, not main"}'
    exit 0
  fi
fi

echo '{"decision": "allow"}'
