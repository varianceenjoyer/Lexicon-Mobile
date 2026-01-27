# Commands

## Claude Code

### ralph-loop Setup

*Configure filesystem hooks to sandbox Claude filesystem permissions within project directory.*

**Prerequisites:**
- `jq` must be installed (`apt install jq` / `brew install jq`)

**1. Add hook configuration to ~/.claude/settings.json:**

    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Read|Write|Edit|MultiEdit",
          "hooks": [
            {
              "type": "command",
              "command": "home/dev/.claude/hooks/restrict_paths.sh"
            }
          ]
        }
      ]
    }

**2. Create ~/.claude/hooks/restrict_paths.sh:**

    mkdir -p ~/.claude/hooks
    touch ~/.claude/hooks/restrict_paths.sh
    nano ~/.claude/hooks/restrict_paths.sh

**3. Paste the following into restrict_paths.sh (set your sandbox root with ALLOWED_BASE):**

    #!/bin/bash
    TOOL_INPUT=$(cat)
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

    ALLOWED_BASE="$HOME/projects"

    if [[ -n "$FILE_PATH" ]]; then
      REAL_PATH=$(realpath -m "$FILE_PATH" 2>/dev/null)
      if [[ ! "$REAL_PATH" =~ ^"$ALLOWED_BASE" ]]; then
        echo '{"decision": "block", "reason": "Path outside allowed directory tree"}'
        exit 0
      fi
    fi

    echo '{"decision": "allow"}'

**4. Make hook executable:**

chmod +x ~/.claude/hooks/restrict_paths.sh

**5. Open Claude Code and install the ralph-loop plugin:**

    claude --dangerously-skip-permissions
    /plugin install ralph-loop@claude-plugins-official

**6. Verify restrict_paths.sh hook is working:**

    Read ~/.bashrc

    (should output PreToolUse blocking error and identify the hook)

    If the hook blocked the read, then Claude is successfully sandboxed within the ALLOWED_BASE directory
---

### ralph-loop Run

Now we can let ralph-loop run without fear of corrupting system binaries!

**ralph-loop**

    claude --dangerously-skip-permissions
    /ralph-loop:ralph-loop "prompt" --max-iterations 10

**ralph-loop + MCP**

    claude --mcp-config ~/.claude/settings.json --dangerously-skip-permissions
    /ralph-loop:ralph-loop "prompt" --max-iterations 10

## SSH

**Run ssh-agent**
    eval `ssh-agent`
**Key Creation**
    ssh-keygen -t ed25519 -f ~/.ssh/key_name
**Add to Agent**
    ssh-add ~/.ssh/key_name

## TMUX

**~/.tmux.conf**

```bash
# Disable mouse by default
set -g mouse off

# WSL clipboard support
set -s copy-command 'clip.exe'

# Enable clipboard integration
set -g set-clipboard on

# Toggle mouse with prefix + m
bind m \
    set -g mouse \; \
    display 'Mouse: #{?mouse,ON,OFF}'

# Start window/pane indexing at 1
set -g base-index 1
setw -g pane-base-index 1

# 4-pane layout (prefix + Alt-4)
bind-key M-4 split-window -h \; select-pane -t 1 \; split-window -v \; select-pane -t 3 \; split-window -v \; select-layout tiled

# 9-pane layout (prefix + Alt-9)
bind-key M-9 split-window -h \; split-window -h \; select-pane -t 1 \; split-window -v \; split-window -v \; select-pane -t 4 \; split-window -v \; split-window -v \; select-pane -t 7 \; split-window -v \; split-window -v \; select-layout tiled
```