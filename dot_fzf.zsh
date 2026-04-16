# Setup fzf
# ---------
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
# source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" # old way
source <(fzf --zsh)

# Reset the completion. Replaces the **<TAB>
export FZF_COMPLETION_TRIGGER=''
bindkey '^T' fzf-completion
bindkey '^I' $fzf_default_completion

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)               fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset)     fzf --preview "eval 'echo \$' {}" "$@" ;;
    ssh)              fzf --preview 'dig {}' "$@" ;;
    *)                fzf --preview "--preview 'bat -n --color=always --line-range :500 {}'" "$@" ;;
  esac
}

# Replaces the 'z' command with an fzf integrated version for zoxide
# z() {
#   if [[ -z "$*" ]]; then
#     # No arguments, use fzf to pick a directory
#     local dir=$(zoxide query -l | fzf +s --tac | awk '{print $NF}')
#     if [ -n "$dir" ]; then
#       cd "$dir" || return
#     fi
#   else
#     # Arguments provided, pass them to zoxide query, and attempt to cd to result
#     local dir=$(zoxide query "$@")
#     if [ -n "$dir" ]; then
#       cd "$dir" || return
#     fi
#   fi
# }

# Function for `zz` command to support initial filtering
zz() {
  local dir=$(zoxide query -l | fzf -q "$*" | awk '{print $NF}')
  if [ -n "$dir" ]; then
    cd "$dir" || return
  fi
}

# search branches (including remote) and add them as new wt in the bare wt root
wtta() {
  local initial_query="$1"

  local branches branch branch_name worktree_path bare_repo_root worktree_dir branch_path navigate
  branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" |
    fzf-tmux -q "$initial_query" -d $(( 2 + $(wc -l <<< "$branches") )) +m --keep-right --preview 'git log --all --oneline --graph --decorate --color=always {1} --no-commit-id --name-only -r $(cut -d " " -f 1 <<< {}) | bat --color=always --style=numbers,changes --line-range :500')

  # Check if fzf was exited without selecting a branch
  if [[ $? -ne 0 ]]; then
    echo "No branch selected. Exiting..."
    return
  fi

  branch_name=$(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##") &&

  # Get the full path to the git directory (works for bare repos)
  bare_repo_root=$(git rev-parse --git-dir) &&

  # For a path like /path/to/repo.git/worktrees/branch, this strips out the "/worktrees/branch" part
  # to isolate the root of the bare repository
  bare_repo_root="${bare_repo_root%/worktrees/*}" &&

  # Determine the path for the new branch worktree
  # This will maintain the original branch structure e.g., feature/some-feature
  worktree_dir="${bare_repo_root}/${branch_name}" &&

  # Ensure the directory for the new worktree exists
  mkdir -p "$worktree_dir" &&

  # Add the new worktree
  git worktree add "$worktree_dir" "$branch_name"

  # Check if the command is followed by 'z' to navigate into the directory
  # navigate="$1"

  z "$worktree_dir"

  # if [[ "$navigate" == "z" ]]; then
    # Use zoxide to jump to the directory
    # commented this out since I always want to cd into the directory after adding the wt
    # z "$worktree_dir"
  # fi
}

# fzf list the worktrees in bare repo. Zoxide into selection
wtt() {
  local is_bare_repo=$(git rev-parse --is-bare-repository)
  
  # get 1st argument
  local initial_query="$1"

  # Get the full path to the git directory (works for bare repos)
  local bare_repo_root=$(git rev-parse --git-dir)
  
  # For a path like /path/to/repo.git/worktrees/branch, this strips out the "/worktrees/branch" part
  # to isolate the root of the bare repository
  if [ "$is_bare_repo" = true ]; then
    bare_repo_root=$(pwd)
  else
    bare_repo_root="${bare_repo_root%/worktrees/*}"
  fi

  local branches=$(git worktree list | awk '{print $1}' | sed "s#${bare_repo_root}/##")
  local branch=$(echo "$branches" | fzf-tmux -q "$initial_query" -d $(( 2 + $(wc -l <<< "$branches") )) +m --keep-right --preview 'git log --all --oneline --graph --decorate --color=always {1} --no-commit-id --name-only -r $(cut -d " " -f 1 <<< {}) | bat --color=always --style=numbers,changes --line-range :500')

  # Assuming the worktree directory names are the same as branch names
  # Use 'z' command to jump to the directory, relative to the bare repo root
  if [[ -n "$branch" ]]; then
    z "$bare_repo_root/$branch"
  fi
}

# --- ws: JJ Workspace Manager ---

# Find the true repo root (where .jj/repo/ lives as a real directory, not a pointer file)
_ws_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.jj/repo" ]]; then
      # Real repo root — .jj/repo is a directory
      echo "$dir"
      return 0
    elif [[ -f "$dir/.jj/repo" ]]; then
      # Workspace subdir — .jj/repo is a file pointing to the real repo
      local pointer
      pointer=$(<"$dir/.jj/repo")
      # Resolve the relative path to get the true root
      echo "$(cd "$dir/.jj" && cd "$(dirname "$pointer")/.." && pwd)"
      return 0
    fi
    dir="${dir:h}"
  done
  echo "Error: not inside a jj repository" >&2
  return 1
}

# Check if repo is in bare layout (no default workspace)
# Returns 0 if bare, 1 if regular
_ws_is_bare() {
  local root="$1"
  local names
  names=$(_ws_names "$root")
  if echo "$names" | grep -qx 'default'; then
    return 1
  fi
  return 0
}

# Compute the path for a new workspace based on layout
# Bare:    $root/$ws_name           (e.g., /projects/myrepo/feature.auth)
# Regular: $root/../$basename.$ws_name (e.g., /projects/myrepo.feature.auth)
_ws_new_ws_path() {
  local root="$1" ws_name="$2"
  if _ws_is_bare "$root"; then
    echo "$root/$ws_name"
  else
    echo "${root:h}/${root:t}.$ws_name"
  fi
}

# Get workspace names, one per line
_ws_names() {
  local root="$1"
  jj -R "$root" workspace list --no-pager -T 'name ++ "\n"'
}

# Get the actual path for a workspace (handles external workspaces)
_ws_path() {
  local root="$1" name="$2"
  jj -R "$root" workspace root --name "$name" --no-pager --quiet 2>/dev/null
}

ws() {
  local subcmd="${1:-}"

  # Top-level help
  case "$subcmd" in
    -h|--help|help) _ws_help; return ;;
  esac

  # Per-command help: ws <cmd> -h|--help
  if [[ "${2:-}" == -h || "${2:-}" == --help ]]; then
    _ws_cmd_help "$subcmd"
    return
  fi

  local root
  root=$(_ws_root) || return 1

  case "$subcmd" in
    bare)   shift; _ws_bare "$root" "$@" ;;
    create) shift; _ws_create "$@" ;;
    list)   shift; _ws_list "$@" ;;
    remove) shift; _ws_remove "$@" ;;
    rename) shift; _ws_rename "$@" ;;
    launch) shift; _ws_launch "$@" ;;
    tidy)   shift; _ws_tidy "$@" ;;
    push)   shift; _ws_push "$@" ;;
    status) shift; _ws_status "$@" ;;
    sync)   shift; _ws_sync "$@" ;;
    clean)  shift; _ws_clean "$@" ;;
    *)      _ws_pick "$@" ;;
  esac
}

_ws_help() {
  cat <<'EOF'
ws — JJ Workspace Manager

Usage: ws [command] [args...]

Commands:
  ws [query]                       Switch workspaces (fzf picker)
  ws create [name] [-r rev] ...    Create workspace (direct or browse mode)
  ws list                          List workspaces with status
  ws remove [query]                Remove workspace (fzf picker)
  ws rename <old> <new>            Rename workspace + directory + bookmark
  ws launch <name> <cmd> [args]    Create workspace + run command in subshell
  ws tidy [--model=<model>]        AI-assisted change organization
  ws push [name]                   Advance bookmark + push
  ws status                        Overview of all workspaces
  ws sync                          Fetch + rebase onto trunk
  ws clean                         Remove merged workspaces
  ws bare init                     Convert repo to bare layout (optional)

Run 'ws <command> -h' for command-specific help.
EOF
}

_ws_cmd_help() {
  case "$1" in
    bare)
      _ws_bare_help
      ;;
    init)
      cat <<'EOF'
ws bare init — Convert repo to bare layout

Usage: ws bare init

Converts a jj repo to bare layout where the root directory stays clean
(only .jj/ and .git/) and all work happens in workspace subdirectories.

If external workspaces exist, prompts to migrate, remove, or skip each one.
Safe and idempotent — does nothing if already initialized.

Commands run:
  jj new 'root()'              # Clear files from root
  jj workspace forget default   # Remove default workspace
  jj workspace forget <name>    # (migrate) Forget old workspace
  jj workspace add <path>       # (migrate) Re-add at new path in repo root

Undo: prints 'jj op restore <id>' after completion.
EOF
      ;;
    create)
      cat <<'EOF'
ws create — Create a new workspace

Usage:
  ws create                              # Browse bookmarks (fzf picker)
  ws create -f                           # Fetch first, then browse
  ws create --remote[=<remote>]          # Browse remote branches
  ws create <name>                       # Create on trunk (direct)
  ws create <name> -r <rev>              # Create on specific revision
  ws create <name> --remote=<remote>     # Fetch + track remote branch

Naming: slash → dot for workspace/directory, slash kept for bookmark.
  feature/auth → workspace: feature.auth, dir: feature.auth/, bookmark: feature/auth

Commands run:
  jj workspace add --name <ws> <path> -r <rev>
  jj bookmark create <name> -r '<ws>@'
  jj bookmark track <name>@<remote>      # (remote mode)
EOF
      ;;
    list)
      cat <<'EOF'
ws list — List workspaces with status

Usage: ws list

Shows all workspaces with change ID, commit hash, and description.

Commands run:
  jj workspace list
EOF
      ;;
    remove)
      cat <<'EOF'
ws remove — Remove a workspace

Usage:
  ws remove              # Open fzf picker
  ws remove [query]      # Open picker pre-filtered

Opens fzf to select a workspace, then confirms before removing.
Deletes the workspace, its directory, and any matching bookmark.
If you're inside the removed workspace, navigates to repo root.

Commands run:
  jj workspace forget <name>
  jj bookmark delete <bookmark>   # If a matching bookmark exists
  rm -rf <workspace-dir>
EOF
      ;;
    rename)
      cat <<'EOF'
ws rename — Rename workspace, directory, and bookmark

Usage: ws rename <old> <new>

Atomically renames the workspace, moves its directory, and renames the
bookmark. Both names use slash notation (e.g., feature/auth → feature/login).
Must be run from outside the workspace being renamed.

Commands run:
  jj workspace add --name <new> <new-path> -r '<old>@'
  jj workspace forget <old>
  jj bookmark rename <old> <new>
  rm -rf <old-dir>
EOF
      ;;
    launch)
      cat <<'EOF'
ws launch — Create workspace + run command

Usage: ws launch <name> <cmd> [args...]

Creates the workspace if it doesn't exist (idempotent), then runs the
command in a subshell. Doesn't change the parent shell's working directory.
Designed for spinning up parallel AI agent workflows.

Examples:
  ws launch agent/task-1 claude "Add authentication"
  ws launch quick-test echo "hello"

Commands run:
  jj workspace add --name <ws> <path> -r 'trunk()'
  (cd <path> && <cmd> [args...])
EOF
      ;;
    tidy)
      cat <<'EOF'
ws tidy — AI-assisted change organization

Usage:
  ws tidy                    # Default model (sonnet)
  ws tidy --model=<model>    # Specific model (haiku, opus, etc.)

Analyzes workspace state and proposes jj commands to organize edits into
clean, logical revisions with proper descriptions.

Flow: gather state → AI analysis → show plan → confirm → execute.
Prints 'jj op restore <id>' for undo safety.

Commands run (proposed by AI):
  jj describe -m "..."
  jj new
  jj squash --into <rev>
  jj split <paths...>
EOF
      ;;
    push)
      cat <<'EOF'
ws push — Advance bookmark + push

Usage:
  ws push              # Push current workspace's bookmark
  ws push [name]       # Push a specific workspace's bookmark

Advances the workspace's bookmark to its current change, then pushes.
Auto-detects current workspace from $PWD if no name given.
Converts workspace name (dot notation) to bookmark name (slash notation).

Commands run:
  jj bookmark advance <bookmark>
  jj git push --bookmark <bookmark>
EOF
      ;;
    status)
      cat <<'EOF'
ws status — Overview of all workspaces

Usage: ws status

Shows a table of all workspaces with bookmark name, commits ahead of
trunk, and current description.

Commands run:
  jj workspace list -T 'name ++ "\n"'
  jj log -r '<ws>@ ~ ::trunk()' --no-graph   # Per workspace, for ahead count
EOF
      ;;
    sync)
      cat <<'EOF'
ws sync — Fetch + rebase onto trunk

Usage: ws sync

Fetches from all remotes, then rebases the current workspace's change
onto trunk(). Reports conflicts if any.

Commands run:
  jj git fetch --all-remotes
  jj rebase -d 'trunk()'
EOF
      ;;
    clean)
      cat <<'EOF'
ws clean — Remove merged workspaces

Usage: ws clean

Finds workspaces whose current change is in trunk's ancestry (already
merged). Shows the list and asks for confirmation before removing.
Also deletes matching bookmarks.

Commands run:
  jj log -r '<ws>@ & ::trunk()'   # Check if merged
  jj workspace forget <name>       # Per merged workspace
  jj bookmark delete <bookmark>    # If matching bookmark exists
  rm -rf <workspace-dir>
EOF
      ;;
    *)
      echo "No help available for '$1'. Run 'ws help' for all commands."
      ;;
  esac
}

_ws_bare() {
  local root="$1"
  shift

  local subcmd="${1:-}"
  case "$subcmd" in
    -h|--help|"") _ws_bare_help; return ;;
    init) shift; _ws_bare_init "$root" "$@" ;;
    *)
      echo "Unknown bare command: $subcmd" >&2
      echo "Run 'ws bare' for available commands." >&2
      return 1
      ;;
  esac
}

_ws_bare_help() {
  cat <<'EOF'
ws bare — Bare layout management

Usage: ws bare <command>

Commands:
  ws bare init    Convert repo to bare layout (clear root, forget default workspace)

A bare layout keeps the repo root clean (only .jj/ and .git/) with all work
in workspace subdirectories. This is optional — ws works with regular repos too.

Run 'ws bare init -h' for more details.
EOF
}

_ws_pick() {
  local root
  root=$(_ws_root) || return 1

  local initial_query="$*"
  local names
  names=$(_ws_names "$root") || return 1

  if [[ -z "$names" ]]; then
    echo "No workspaces found. Use 'ws create <name>' to create one."
    return 1
  fi

  local selected
  selected=$(echo "$names" | fzf-tmux \
    -q "$initial_query" \
    -d $(( 2 + $(wc -l <<< "$names") )) \
    +m --keep-right \
    --preview "jj -R '$root' log --no-pager --color=always -r '{1}@' --limit 5")

  if [[ -n "$selected" ]]; then
    local ws_path
    ws_path=$(_ws_path "$root" "$selected")
    if [[ -d "$ws_path" ]]; then
      z "$ws_path"
    else
      echo "Error: workspace directory '$ws_path' not found." >&2
      return 1
    fi
  fi
}

_ws_bare_init() {
  local root="$1"
  shift

  # Handle help flag
  if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
    _ws_cmd_help init
    return 0
  fi

  local names
  names=$(_ws_names "$root")

  if ! echo "$names" | grep -qx 'default'; then
    echo "Already initialized (no default workspace)."
    return 0
  fi

  # Gather info
  local change_count
  change_count=$(jj -R "$root" log --no-pager --no-graph -r 'all() ~ root()' -T 'concat("")' 2>/dev/null | wc -l)

  # Find non-default workspaces
  local other_workspaces=()
  while IFS= read -r name; do
    [[ -z "$name" || "$name" == "default" ]] && continue
    other_workspaces+=("$name")
  done <<< "$names"

  # Classify workspaces
  local external_workspaces=() internal_workspaces=()
  for name in "${other_workspaces[@]}"; do
    local p
    p=$(_ws_path "$root" "$name")
    if [[ "$p" == "$root/$name" ]]; then
      internal_workspaces+=("$name")
    else
      external_workspaces+=("$name")
    fi
  done

  # --- Show summary ---
  echo "━━━ ws bare init ━━━"
  echo ""
  echo "This will convert the repo to bare layout:"
  echo "  • Project files will be cleared from the root directory"
  echo "  • The default workspace will be forgotten"
  if [[ "$change_count" -gt 0 ]]; then
    echo "  • Your $change_count existing change(s) are safe — nothing is abandoned"
  fi
  echo ""

  if [[ ${#internal_workspaces[@]} -gt 0 ]]; then
    echo "${#internal_workspaces[@]} workspace(s) already in repo root (no action needed):"
    for name in "${internal_workspaces[@]}"; do
      echo "  ✓ $name"
    done
    echo ""
  fi

  # --- Collect migration plan for external workspaces ---
  # Actions are collected first, executed after bare init
  local -A ws_actions  # ws_name -> action (migrate|remove|skip)
  local -A ws_paths    # ws_name -> current path
  local -A ws_changes  # ws_name -> change_id

  if [[ ${#external_workspaces[@]} -gt 0 ]]; then
    echo "${#external_workspaces[@]} external workspace(s) need attention:"
    echo ""
    for name in "${external_workspaces[@]}"; do
      local p desc
      p=$(_ws_path "$root" "$name")
      desc=$(jj -R "$root" log --no-pager --no-graph --limit 1 -r "${name}@" -T 'description.first_line()' 2>/dev/null)
      [[ -z "$desc" ]] && desc="(no description)"
      echo "  $name"
      echo "    path: $p"
      echo "    desc: $desc"
    done
    echo ""

    for name in "${external_workspaces[@]}"; do
      local p
      p=$(_ws_path "$root" "$name")
      ws_paths[$name]="$p"

      echo "┌ $name"
      echo "│ $p"
      echo "│"
      echo "│  [m] Migrate — move into repo root as ./$name"
      echo "│  [r] Remove  — forget workspace and delete its directory"
      echo "│  [s] Skip    — leave as-is (external workspace)"
      echo "│  [q] Quit    — abort ws bare init"
      echo "│"
      echo -n "└ [m/r/s/q]: "
      read -r choice

      case "$choice" in
        m|M)
          if [[ -d "$root/$name" ]]; then
            echo "  ✗ Directory './$name' already exists in repo root, will skip."
            ws_actions[$name]="skip"
          else
            ws_actions[$name]="migrate"
            # Capture change ID now while workspace still exists
            ws_changes[$name]=$(jj -R "$root" log --no-pager --no-graph --limit 1 -r "${name}@" -T 'change_id.short()' 2>/dev/null)
            echo "  Will migrate after init."
          fi
          ;;
        r|R)
          echo -n "  Confirm delete '$name' and its files? [y/N] "
          read -r del_confirm
          if [[ "$del_confirm" == [yY] ]]; then
            ws_actions[$name]="remove"
            echo "  Will remove after init."
          else
            ws_actions[$name]="skip"
            echo "  Kept."
          fi
          ;;
        s|S)
          ws_actions[$name]="skip"
          echo "  Skipped."
          ;;
        q|Q)
          echo ""
          echo "Aborted. No changes made."
          return 0
          ;;
        *)
          ws_actions[$name]="skip"
          echo "  Unknown choice, skipping."
          ;;
      esac
      echo ""
    done
  fi

  # --- Final confirmation ---
  echo -n "Proceed with bare layout init? [y/N] "
  read -r confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    return 0
  fi

  # Record operation ID for undo safety
  local op_id
  op_id=$(jj -R "$root" op log --no-pager --no-graph --limit 1 -T 'id.short() ++ "\n"' 2>/dev/null | head -1)

  echo ""

  # --- Phase 1: Snapshot external workspaces marked for migration ---
  for name in "${external_workspaces[@]}"; do
    if [[ "${ws_actions[$name]}" == "migrate" ]]; then
      local p="${ws_paths[$name]}"
      echo "Snapshotting '$name'..."
      jj util snapshot -R "$p" --quiet 2>/dev/null
    fi
  done

  # --- Phase 2: Bare init (clear root, forget default) ---
  echo "Clearing root directory..."
  if ! jj -R "$root" new 'root()' --quiet 2>&1; then
    echo "Error: failed to clear root. Undo with: jj op restore $op_id" >&2
    return 1
  fi
  if ! jj -R "$root" workspace forget default --quiet 2>&1; then
    echo "Error: failed to forget default workspace. Undo with: jj op restore $op_id" >&2
    return 1
  fi
  echo "✓ Bare layout initialized."

  # --- Phase 3: Execute workspace actions ---
  local had_errors=false

  for name in "${external_workspaces[@]}"; do
    local action="${ws_actions[$name]}"
    local old_path="${ws_paths[$name]}"

    case "$action" in
      migrate)
        local change_id="${ws_changes[$name]}"
        local target_path="$root/$name"
        local tmp_bm="_ws_migrate_${name//[^a-zA-Z0-9_-]/_}"

        # Pin the change with a temp bookmark so jj doesn't auto-abandon it after forget
        jj -R "$root" bookmark create "$tmp_bm" -r "$change_id" --quiet 2>/dev/null

        # Forget old workspace, re-add at new path, delete old dir
        if ! jj -R "$root" workspace forget "$name" --quiet 2>&1; then
          echo "✗ Failed to forget workspace '$name'." >&2
          jj -R "$root" bookmark delete "$tmp_bm" --quiet 2>/dev/null
          had_errors=true
          continue
        fi

        if jj -R "$root" workspace add --name "$name" "$target_path" -r "$change_id" --quiet 2>&1; then
          [[ -d "$old_path" ]] && rm -rf "$old_path"
          # Create a bookmark matching the workspace name (slash notation)
          local bm_name="${name//.//}"
          if ! jj -R "$root" bookmark list --no-pager -T 'name ++ "\n"' 2>/dev/null | grep -qx "$bm_name"; then
            jj -R "$root" bookmark create "$bm_name" -r "${name}@" --quiet 2>/dev/null
          fi
          echo "✓ Migrated '$name' → ./$name"
        else
          echo "✗ Failed to migrate '$name'. Old directory kept at: $old_path" >&2
          had_errors=true
        fi

        # Clean up temp bookmark
        jj -R "$root" bookmark delete "$tmp_bm" --quiet 2>/dev/null
        ;;
      remove)
        jj -R "$root" workspace forget "$name" --quiet 2>/dev/null
        [[ -d "$old_path" ]] && rm -rf "$old_path"
        echo "✓ Removed '$name'."
        ;;
      skip)
        # nothing to do
        ;;
    esac
  done

  # --- Summary ---
  local skipped_names=()
  for name in "${external_workspaces[@]}"; do
    [[ "${ws_actions[$name]}" == "skip" ]] && skipped_names+=("$name")
  done

  if [[ ${#skipped_names[@]} -gt 0 ]]; then
    echo ""
    echo "${#skipped_names[@]} workspace(s) left as external:"
    for name in "${skipped_names[@]}"; do
      echo "  · $name"
    done
    echo "These still work but live outside the repo root."
    echo "You can remove them later with: ws remove"
  fi

  echo ""
  if [[ "$had_errors" == true ]]; then
    echo "Completed with errors. Undo everything with: jj op restore $op_id"
  else
    echo "Done. Undo with: jj op restore $op_id"
  fi
  echo "Create workspaces with 'ws create <name>' to start working."
}

_ws_create() {
  local input="" rev="" remote="" fetch=false

  # Parse args: ws create [<name>] [-r <rev>] [--remote[=<remote>]] [-f] [-h]
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) _ws_create_help; return 0 ;;
      -f|--fetch) fetch=true; shift ;;
      -r)       rev="$2"; shift 2 ;;
      --remote=*) remote="${1#--remote=}"; shift ;;
      --remote) remote="${2:-origin}"; shift 2 ;;
      *)        input="$1"; shift ;;
    esac
  done

  # No name given → interactive browse mode
  if [[ -z "$input" ]]; then
    _ws_create_browse "$remote" "$fetch"
    return $?
  fi

  local root
  root=$(_ws_root) || return 1

  # slash → dot for workspace name and directory, keep slash for bookmark
  local ws_name="${input//\//.}"
  local bookmark="$input"
  local ws_path
  ws_path=$(_ws_new_ws_path "$root" "$ws_name")

  if [[ -d "$ws_path" ]]; then
    echo "Error: directory '$ws_name' already exists." >&2
    return 1
  fi

  local names
  names=$(_ws_names "$root")
  if echo "$names" | grep -qx "$ws_name"; then
    echo "Error: workspace '$ws_name' already exists." >&2
    return 1
  fi

  # Determine base revision
  local base_rev='trunk()'
  if [[ -n "$remote" ]]; then
    echo "Fetching '$bookmark' from $remote..."
    if ! jj -R "$root" git fetch --remote "$remote" --branch "$bookmark" 2>&1; then
      echo "Error: failed to fetch '$bookmark' from $remote." >&2
      return 1
    fi
    base_rev="$bookmark@$remote"
  elif [[ -n "$rev" ]]; then
    base_rev="$rev"
  fi

  jj -R "$root" workspace add --name "$ws_name" "$ws_path" -r "$base_rev" --quiet

  # Create bookmark if one doesn't already exist
  if jj -R "$root" bookmark create "$bookmark" -r "$ws_name@" --quiet 2>/dev/null; then
    # Track remote if fetched from one
    if [[ -n "$remote" ]]; then
      jj -R "$root" bookmark track "$bookmark@$remote" --quiet 2>/dev/null
    fi
    echo "Created workspace '$ws_name' (bookmark: $bookmark)"
  else
    echo "Created workspace '$ws_name' (bookmark '$bookmark' already exists, skipped)"
  fi

  cd "$ws_path"
}

_ws_create_help() {
  cat >&2 <<'EOF'
Usage: ws create [<name>] [-r <rev>] [--remote[=<remote>]] [-f] [-h]

Browse mode (no name given):
  ws create                       Browse all bookmarks (local + remote)
  ws create -f                    Same, but fetch from all remotes first
  ws create --remote              Browse only origin's branches (fetches)
  ws create --remote=upstream     Browse only upstream's branches (fetches)

Direct mode (name given):
  ws create feature/auth          Create workspace on trunk()
  ws create feature/auth -r main  Create workspace on specific revision
  ws create feature/auth --remote Fetch + track from origin

Flags:
  -f, --fetch       Fetch all remotes before browsing
  -r <rev>          Base revision for new workspace
  --remote[=<name>] Filter to remote branches / fetch from remote (default: origin)
  -h, --help        Show this help
EOF
}

_ws_create_browse() {
  local remote="$1" fetch="$2"

  local root
  root=$(_ws_root) || return 1

  # Fetch if requested
  if [[ -n "$remote" ]]; then
    echo "Fetching from $remote..."
    jj -R "$root" git fetch --remote "$remote" 2>&1
  elif [[ "$fetch" == true ]]; then
    echo "Fetching from all remotes..."
    jj -R "$root" git fetch 2>&1
  fi

  # Build bookmark list
  local bookmarks
  if [[ -n "$remote" ]]; then
    # Remote-only: list bookmarks from that remote, deduplicated
    bookmarks=$(jj -R "$root" bookmark list --remote "$remote" --no-pager \
      -T 'name ++ "\n"' 2>/dev/null | sort -u)
  else
    # All: local bookmarks + all remote bookmarks, deduplicated
    bookmarks=$(jj -R "$root" bookmark list --all-remotes --no-pager \
      -T 'name ++ "\n"' 2>/dev/null | sort -u)
  fi

  if [[ -z "$bookmarks" ]]; then
    echo "No bookmarks found."
    return 1
  fi

  # Get existing workspaces for marking
  local existing_ws
  existing_ws=$(_ws_names "$root")

  # Build display list: mark bookmarks that already have a workspace
  local display_lines=()
  while IFS= read -r bm; do
    [[ -z "$bm" ]] && continue
    local ws_name="${bm//\//.}"
    if echo "$existing_ws" | grep -qx "$ws_name"; then
      display_lines+=("● $bm")
    else
      display_lines+=("  $bm")
    fi
  done <<< "$bookmarks"

  local header="● = workspace exists (will switch)  │  enter = create workspace"

  # fzf selection
  local selected
  selected=$(printf '%s\n' "${display_lines[@]}" | fzf-tmux \
    -d $(( 3 + ${#display_lines[@]} )) \
    +m --keep-right \
    --header "$header" \
    --preview "
      branch=\$(echo {} | sed 's/^[● ]*//')
      jj -R '$root' log --no-pager --color=always -r \"\$branch\" --limit 5 2>/dev/null \
        || echo 'No local revision (remote-only branch)'")

  [[ -z "$selected" ]] && return 0

  # Strip marker prefix to get the branch name
  local branch_name="${selected#● }"
  branch_name="${branch_name#  }"

  local ws_name="${branch_name//\//.}"

  # If workspace already exists, switch to it
  if echo "$existing_ws" | grep -qx "$ws_name"; then
    local ws_path
    ws_path=$(_ws_path "$root" "$ws_name")
    echo "Switching to existing workspace '$ws_name'"
    z "$ws_path"
    return 0
  fi

  # Create new workspace from this branch
  if [[ -n "$remote" ]]; then
    _ws_create "$branch_name" --remote="$remote"
  else
    # Check if this branch exists on a remote, prefer creating from remote
    local branch_remote
    branch_remote=$(jj -R "$root" bookmark list --all-remotes --no-pager \
      -T 'name ++ "\t" ++ remote ++ "\n"' 2>/dev/null \
      | grep "^${branch_name}	" | grep -v "	$" | grep -v "	git$" | head -1 | cut -f2)

    if [[ -n "$branch_remote" ]]; then
      _ws_create "$branch_name" --remote="$branch_remote"
    else
      _ws_create "$branch_name"
    fi
  fi
}

_ws_list() {
  local root
  root=$(_ws_root) || return 1

  jj -R "$root" workspace list --no-pager
}

_ws_remove() {
  local root
  root=$(_ws_root) || return 1

  local initial_query="$*"
  local names
  names=$(_ws_names "$root") || return 1

  if [[ -z "$names" ]]; then
    echo "No workspaces to remove."
    return 1
  fi

  local selected
  selected=$(echo "$names" | fzf-tmux \
    -q "$initial_query" \
    -d $(( 2 + $(wc -l <<< "$names") )) \
    +m --keep-right \
    --preview "jj -R '$root' log --no-pager --color=always -r '{1}@' --limit 5")

  if [[ -z "$selected" ]]; then
    return 0
  fi

  local ws_path
  ws_path=$(_ws_path "$root" "$selected")

  echo -n "Remove workspace '$selected' and delete '$ws_path'? [y/N] "
  read -r confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    return 0
  fi

  jj -R "$root" workspace forget "$selected" --quiet
  if [[ -d "$ws_path" ]]; then
    rm -rf "$ws_path"
  fi
  echo "Removed workspace '$selected'."

  # If we were inside the removed workspace, go to repo root
  if [[ "$PWD" == "$ws_path"* ]]; then
    cd "$root"
  fi
}

_ws_launch() {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo "Usage: ws launch <name> <cmd> [args...]" >&2
    return 1
  fi
  shift

  if [[ $# -eq 0 ]]; then
    echo "Usage: ws launch <name> <cmd> [args...]" >&2
    return 1
  fi

  local root
  root=$(_ws_root) || return 1

  # slash → dot for workspace name and directory
  local ws_name="${input//\//.}"

  local ws_path
  local names
  names=$(_ws_names "$root")

  if echo "$names" | grep -qx "$ws_name"; then
    # Existing workspace — resolve real path
    ws_path=$(_ws_path "$root" "$ws_name")
  else
    # New workspace — path depends on layout (bare: inside root, regular: sibling)
    ws_path=$(_ws_new_ws_path "$root" "$ws_name")
    jj -R "$root" workspace add --name "$ws_name" "$ws_path" -r 'trunk()' --quiet
    echo "Created workspace '$ws_name'."
  fi

  # Run command in subshell — doesn't affect parent shell cwd
  (cd "$ws_path" && "$@")
}

_ws_rename() {
  if [[ $# -lt 2 || "$1" == "-h" || "$1" == "--help" ]]; then
    cat >&2 <<'EOF'
Usage: ws rename <old> <new>

Renames a workspace, its directory, and its bookmark atomically.
Both names use slash notation (e.g., feature/old feature/new).

Example:
  ws rename feature/auth feature/authentication
EOF
    [[ "$1" == "-h" || "$1" == "--help" ]] && return 0
    return 1
  fi

  local root
  root=$(_ws_root) || return 1

  local old_input="$1" new_input="$2"
  local old_ws="${old_input//\//.}"
  local new_ws="${new_input//\//.}"
  local old_bookmark="$old_input"
  local new_bookmark="$new_input"

  # Verify old workspace exists
  local names
  names=$(_ws_names "$root")
  if ! echo "$names" | grep -qx "$old_ws"; then
    echo "Error: workspace '$old_ws' not found." >&2
    return 1
  fi

  # Verify new workspace doesn't exist
  if echo "$names" | grep -qx "$new_ws"; then
    echo "Error: workspace '$new_ws' already exists." >&2
    return 1
  fi

  local old_path
  old_path=$(_ws_path "$root" "$old_ws")
  local new_path
  new_path=$(_ws_new_ws_path "$root" "$new_ws")

  # Must be outside the workspace being renamed
  if [[ "$PWD" == "$old_path"* ]]; then
    echo "Error: can't rename workspace while inside it. cd to repo root first." >&2
    return 1
  fi

  # 1. Rename the jj workspace
  # jj workspace rename only works for the current workspace, so we need to
  # create new + forget old instead
  jj -R "$root" workspace add --name "$new_ws" "$new_path" -r "$old_ws@" --quiet 2>&1
  jj -R "$root" workspace forget "$old_ws" --quiet 2>&1

  # 2. Remove old directory
  if [[ -d "$old_path" ]]; then
    rm -rf "$old_path"
  fi

  # 3. Rename bookmark if it exists
  if jj -R "$root" bookmark list --no-pager -T 'name ++ "\n"' 2>/dev/null | grep -qx "$old_bookmark"; then
    jj -R "$root" bookmark rename "$old_bookmark" "$new_bookmark" --quiet 2>&1
    echo "Renamed workspace '$old_ws' → '$new_ws' (bookmark: $old_bookmark → $new_bookmark)"
  else
    echo "Renamed workspace '$old_ws' → '$new_ws' (no bookmark to rename)"
  fi
}

_ws_push() {
  local root
  root=$(_ws_root) || return 1

  # Determine which workspace to push
  local ws_name
  if [[ -n "$1" ]]; then
    ws_name="${1//\//.}"
  else
    # Detect current workspace from PWD
    local names
    names=$(_ws_names "$root")
    while IFS= read -r name; do
      local wp
      wp=$(_ws_path "$root" "$name")
      if [[ "$PWD" == "$wp"* ]]; then
        ws_name="$name"
        break
      fi
    done <<< "$names"

    if [[ -z "$ws_name" ]]; then
      echo "Error: not inside a workspace. Specify a name: ws push <name>" >&2
      return 1
    fi
  fi

  # Convert workspace name (dot) back to bookmark name (slash)
  local bookmark="${ws_name//.//}"

  # Advance bookmark to workspace's current change
  echo "Advancing bookmark '$bookmark'..."
  if ! jj -R "$root" bookmark advance "$bookmark" --to "$ws_name@" --quiet 2>/dev/null; then
    # bookmark advance failed — try bookmark set as fallback (bookmark may not be an ancestor)
    if ! jj -R "$root" bookmark set "$bookmark" -r "$ws_name@" --quiet 2>&1; then
      echo "Error: failed to advance bookmark '$bookmark'." >&2
      return 1
    fi
  fi

  # Push
  echo "Pushing '$bookmark'..."
  jj -R "$root" git push --bookmark "$bookmark" 2>&1
}

_ws_status() {
  local root
  root=$(_ws_root) || return 1

  local names
  names=$(_ws_names "$root")

  if [[ -z "$names" ]]; then
    echo "No workspaces."
    return 0
  fi

  # Header
  printf "%-25s %-15s %-8s %s\n" "WORKSPACE" "BOOKMARK" "AHEAD" "DESCRIPTION"
  printf "%-25s %-15s %-8s %s\n" "─────────" "────────" "─────" "───────────"

  while IFS= read -r name; do
    [[ -z "$name" ]] && continue

    local bookmark="${name//.//}"

    # Count commits ahead of trunk
    local ahead
    ahead=$(jj -R "$root" log --no-pager --no-graph -r "trunk()..${name}@" -T 'concat("")' 2>/dev/null | wc -l)

    # Get description of current change
    local desc
    desc=$(jj -R "$root" log --no-pager --no-graph --limit 1 -r "${name}@" -T 'description.first_line()' 2>/dev/null)
    [[ -z "$desc" ]] && desc="(no description)"

    # Truncate long descriptions
    if [[ ${#desc} -gt 45 ]]; then
      desc="${desc:0:42}..."
    fi

    printf "%-25s %-15s %-8s %s\n" "$name" "$bookmark" "$ahead" "$desc"
  done <<< "$names"
}

_ws_sync() {
  local root
  root=$(_ws_root) || return 1

  echo "Fetching..."
  jj -R "$root" git fetch 2>&1

  echo "Rebasing onto trunk..."
  if jj rebase -d 'trunk()' --quiet 2>&1; then
    echo "Synced."
    jj log --no-pager --limit 3
  else
    echo "Rebase had conflicts. Resolve with: jj resolve" >&2
    return 1
  fi
}

_ws_clean() {
  local root
  root=$(_ws_root) || return 1

  local names
  names=$(_ws_names "$root")

  if [[ -z "$names" ]]; then
    echo "No workspaces."
    return 0
  fi

  # Find workspaces whose change is an ancestor of trunk (i.e., merged)
  local merged=()
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue

    # Check if workspace's change is in trunk's ancestry
    local is_merged
    is_merged=$(jj -R "$root" log --no-pager --no-graph -r "${name}@ & ::trunk()" -T 'change_id' 2>/dev/null)
    if [[ -n "$is_merged" ]]; then
      merged+=("$name")
    fi
  done <<< "$names"

  if [[ ${#merged[@]} -eq 0 ]]; then
    echo "No merged workspaces to clean up."
    return 0
  fi

  echo "Merged workspaces (safe to remove):"
  for name in "${merged[@]}"; do
    local desc
    desc=$(jj -R "$root" log --no-pager --no-graph --limit 1 -r "${name}@" -T 'description.first_line()' 2>/dev/null)
    echo "  $name — $desc"
  done

  echo ""
  echo -n "Remove all ${#merged[@]} merged workspace(s)? [y/N] "
  read -r confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    return 0
  fi

  for name in "${merged[@]}"; do
    local ws_path
    ws_path=$(_ws_path "$root" "$name")

    jj -R "$root" workspace forget "$name" --quiet
    if [[ -d "$ws_path" ]]; then
      rm -rf "$ws_path"
    fi
    echo "Removed '$name'."
  done

  # If we were inside a removed workspace, go to repo root
  if [[ ! -d "$PWD" ]]; then
    cd "$root"
  fi
}

_ws_tidy() {
  local root model="sonnet"
  root=$(_ws_root) || return 1

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) _ws_tidy_help; return 0 ;;
      --model=*) model="${1#--model=}"; shift ;;
      --model) model="$2"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; return 1 ;;
    esac
  done

  # Gather workspace context
  echo "Analyzing workspace..."
  local jj_status jj_diff jj_log
  jj_status=$(jj st --no-pager 2>&1)
  jj_diff=$(jj diff --no-pager 2>&1)
  # Truncate diff to avoid exceeding prompt limits (e.g. large build artifacts)
  local max_diff_lines=500
  local diff_lines
  diff_lines=$(echo "$jj_diff" | wc -l)
  if [[ $diff_lines -gt $max_diff_lines ]]; then
    jj_diff="$(echo "$jj_diff" | head -n $max_diff_lines)"$'\n\n'"... (truncated: $diff_lines total lines, showing first $max_diff_lines. Use jj diff to see full output.)"
  fi
  jj_log=$(jj log --no-pager --limit 10 2>&1)

  # Check there's something to tidy
  if [[ "$jj_status" == "The working copy is clean" ]] && \
     ! echo "$jj_log" | grep -q '(empty) (no description set)'; then
    echo "Nothing to tidy — working copy is clean and all changes are described."
    return 0
  fi

  # Record operation ID for undo safety
  local op_id
  op_id=$(jj op log --no-pager --no-graph --limit 1 -T 'id.short() ++ "\n"' 2>/dev/null | head -1)

  local prompt
  prompt=$(cat <<'PROMPT'
You are a jj (Jujutsu) version control assistant. Analyze this workspace state and propose commands to organize the changes into clean, logical revisions with proper descriptions.

Rules:
- ONLY use non-interactive jj commands (no -i flags, no editor-opening commands)
- Allowed commands: jj describe -m, jj new, jj squash --into, jj split (with path args only), jj absorb
- Each command must be on its own line, prefixed with exactly "$ " (dollar sign + space)
- Explain each step briefly BEFORE its command(s)
- If changes are already clean, say so and propose nothing
- Write concise, conventional-commit-style descriptions (feat:, fix:, refactor:, docs:, etc.)
- Do NOT invent changes that aren't in the diff — only organize what exists

Workspace state:

=== jj st ===
%STATUS%

=== jj diff ===
%DIFF%

=== jj log (last 10) ===
%LOG%

Propose a tidy plan:
PROMPT
)

  # Inject context into prompt
  prompt="${prompt/\%STATUS\%/$jj_status}"
  prompt="${prompt/\%DIFF\%/$jj_diff}"
  prompt="${prompt/\%LOG\%/$jj_log}"

  # Get plan from AI
  echo "Generating tidy plan (model: $model)..."
  local plan
  plan=$(echo "$prompt" | claude -p --model "$model" --allowedTools "" 2>&1)
  local rc=$?

  if [[ $rc -ne 0 || -z "$plan" ]]; then
    echo "Error: failed to generate plan (exit code: $rc)." >&2
    if [[ -n "$plan" ]]; then
      echo "Claude output:" >&2
      echo "$plan" >&2
    fi
    return 1
  fi

  # Display the plan
  echo ""
  echo "━━━ Tidy Plan ━━━"
  echo ""
  echo "$plan"
  echo ""
  echo "━━━━━━━━━━━━━━━━━"

  # Extract commands (lines starting with "$ ")
  local commands
  commands=$(echo "$plan" | grep '^[$] ' | sed 's/^[$] //')

  if [[ -z "$commands" ]]; then
    echo "No commands to execute — workspace looks clean."
    return 0
  fi

  local cmd_count
  cmd_count=$(echo "$commands" | wc -l)

  echo ""
  echo "Commands to execute ($cmd_count):"
  echo "$commands" | while IFS= read -r cmd; do
    echo "  → $cmd"
  done
  echo ""
  echo "Undo with: jj op restore $op_id"
  echo ""
  echo -n "Execute? [y/N] "
  read -r confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    return 0
  fi

  # Validate commands before executing
  while IFS= read -r cmd; do
    # Reject jj describe without -m (would open editor)
    if echo "$cmd" | grep -q '^jj describe' && ! echo "$cmd" | grep -q -- '-m '; then
      echo "Error: refusing to run 'jj describe' without -m flag (would open editor)." >&2
      echo "Plan command: $cmd" >&2
      return 1
    fi
  done <<< "$commands"

  # Execute commands one at a time
  echo ""
  while IFS= read -r cmd; do
    echo "→ $cmd"
    if ! eval "$cmd" 2>&1; then
      echo "Error: command failed. Stopping." >&2
      echo "Undo all changes with: jj op restore $op_id" >&2
      return 1
    fi
  done <<< "$commands"

  echo ""
  echo "Done. Undo with: jj op restore $op_id"
  jj log --no-pager --limit 5
}

_ws_tidy_help() {
  cat >&2 <<'EOF'
Usage: ws tidy [--model=<model>] [-h]

AI-assisted change organization. Analyzes your workspace and proposes
jj commands to organize edits into clean, logical revisions.

Flow:
  1. Gathers jj st, jj diff, jj log
  2. Sends context to AI for analysis
  3. Shows proposed plan with commands
  4. Asks for confirmation before executing
  5. Prints undo command (jj op restore) for safety

Flags:
  --model=<model>  AI model to use (default: sonnet)
  -h, --help       Show this help

Examples:
  ws tidy                  Tidy with default model (sonnet)
  ws tidy --model=haiku    Tidy with faster/cheaper model
EOF
}

# --- ws completions ---

_ws() {
  local -a subcmds=(
    'bare:Bare layout management'
    'create:Create a new workspace'
    'list:List workspaces with status'
    'remove:Remove a workspace (fzf picker)'
    'rename:Rename workspace + directory + bookmark'
    'launch:Create workspace + run command'
    'tidy:AI-assisted change organization'
    'push:Advance bookmark + push'
    'status:Overview of all workspaces'
    'sync:Fetch + rebase onto trunk'
    'clean:Remove merged workspaces'
    'help:Show all commands'
  )

  # Helper: complete workspace names
  _ws_complete_names() {
    local root
    root=$(_ws_root 2>/dev/null) || return
    local -a names=("${(@f)$(jj -R "$root" workspace list --no-pager -T 'name ++ "\n"' 2>/dev/null)}")
    compadd -X "workspace" -- "${names[@]}"
  }

  if (( CURRENT == 2 )); then
    _describe 'ws command' subcmds
    # Also allow bare workspace name for switching (default picker)
    _ws_complete_names
  else
    case "${words[2]}" in
      bare)
        if (( CURRENT == 3 )); then
          local -a bare_subcmds=('init:Convert repo to bare layout')
          _describe 'bare command' bare_subcmds
        fi
        ;;
      rename)
        # Both args complete with workspace names
        _ws_complete_names
        ;;
      remove|push)
        if (( CURRENT == 3 )); then
          _ws_complete_names
        fi
        ;;
      create)
        if (( CURRENT == 3 )); then
          # Complete with bookmark names for workspace creation
          local root
          root=$(_ws_root 2>/dev/null) || return
          local -a bmarks=("${(@f)$(jj -R "$root" bookmark list --no-pager -T 'name ++ "\n"' 2>/dev/null)}")
          compadd -X "bookmark" -- "${bmarks[@]}"
        fi
        ;;
      launch)
        if (( CURRENT == 3 )); then
          _ws_complete_names
        elif (( CURRENT == 4 )); then
          _command_names
        fi
        ;;
      *)
        _default
        ;;
    esac
  fi
}

compdef _ws ws

# catppuccin mocha theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
