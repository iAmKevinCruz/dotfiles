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
wta() {
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
wt() {
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

# Find the true repo root (where .jj/repo/ lives)
_ws_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.jj/repo" ]]; then
      echo "$dir"
      return 0
    fi
    dir="${dir:h}"
  done
  echo "Error: not inside a jj repository" >&2
  return 1
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

  case "$subcmd" in
    init)   shift; _ws_init "$@" ;;
    create) shift; _ws_create "$@" ;;
    list)   shift; _ws_list "$@" ;;
    remove) shift; _ws_remove "$@" ;;
    launch) shift; _ws_launch "$@" ;;
    *)      _ws_pick "$@" ;;
  esac
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

_ws_init() {
  local root
  root=$(_ws_root) || return 1

  local names
  names=$(_ws_names "$root")

  if echo "$names" | grep -qx 'default'; then
    jj -R "$root" new 'root()' --quiet
    jj -R "$root" workspace forget default --quiet
    echo "Initialized bare layout: cleared root and forgot default workspace."
  else
    echo "Already initialized (no default workspace)."
  fi
}

_ws_create() {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo "Usage: ws create <name>  (e.g., ws create feature/add-auth)" >&2
    return 1
  fi

  local root
  root=$(_ws_root) || return 1

  # slash → dot for workspace name and directory, keep slash for bookmark
  local ws_name="${input//\//.}"
  local bookmark="$input"
  local ws_path="$root/$ws_name"

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

  jj -R "$root" workspace add --name "$ws_name" "$ws_path" -r 'trunk()' --quiet
  jj -R "$root" bookmark create "$bookmark" -r "$ws_name@" --quiet
  cd "$ws_path"
  echo "Created workspace '$ws_name' (bookmark: $bookmark)"
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
    # New workspace — create inside repo root (no bookmark for ephemeral launches)
    ws_path="$root/$ws_name"
    jj -R "$root" workspace add --name "$ws_name" "$ws_path" -r 'trunk()' --quiet
    echo "Created workspace '$ws_name'."
  fi

  # Run command in subshell — doesn't affect parent shell cwd
  (cd "$ws_path" && "$@")
}

# catppuccin mocha theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
