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


# catppuccin mocha theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
