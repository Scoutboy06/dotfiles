# nono sandbox wrappers for coding agents. Sourced from ~/.zshrc.
#
# nono's --allow-cwd grants only the directory the agent starts in, which splits
# a project from its worktrees. Git's common dir resolves to the live checkout
# from inside a worktree *and* from the checkout itself, so either starting
# point yields the same pair of grants and the sandbox spans both halves.
#
# Assumed layout:
#   $NONO_PROJECTS_ROOT/<project>                live checkout
#   $NONO_WORKTREES_ROOT/<project>/<worktree>    its worktrees

[[ -n $NONO_CAP_FILE ]] && return 0   # already inside a sandbox
(( $+commands[nono] )) || return 0

: ${NONO_PROJECTS_ROOT:=$HOME/p}
: ${NONO_WORKTREES_ROOT:=$NONO_PROJECTS_ROOT/.worktrees}
: ${NONO_EXTENDS_PROFILE:=dotnet-dev}

typeset -ga _NONO_GRANTS

# Fill _NONO_GRANTS with the --allow pair for the project containing $PWD.
# Left empty outside a git repo, or for repos outside $NONO_PROJECTS_ROOT, in
# which case the caller falls back to plain --allow-cwd.
_nono_project_grants() {
  local common root name
  _NONO_GRANTS=()
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 0
  root=${common:h}; name=${root:t}
  [[ $root == $NONO_PROJECTS_ROOT/* ]] || return 0
  _NONO_GRANTS=(--allow "$root")
  # Grant the worktree parent, not each worktree: the grant is recursive and
  # live, so worktrees created mid-session are covered without a restart.
  mkdir -p "$NONO_WORKTREES_ROOT/$name" 2>/dev/null &&
    _NONO_GRANTS+=(--allow "$NONO_WORKTREES_ROOT/$name")
}

_nono_wrap() {  # $1 = nono profile, rest = program + args
  local profile=$1; shift
  _nono_project_grants
  nono wrap -s --allow-cwd $_NONO_GRANTS -p "$profile" --extends "$NONO_EXTENDS_PROFILE" -- "$@"
}

# claude-local is the local profile extending the pack's claude (adds read
# access to the bun binary); see ~/.config/nono/profiles/claude-local.json.
claude()   { _nono_wrap claude-local      claude   "$@" }
opencode() { _nono_wrap nolabs-ai/opencode opencode "$@" }
pi()       { _nono_wrap nolabs-ai/pi       pi       "$@" }
