#!/usr/bin/env bash
# =============================================================================
# Claude Code custom status line.
# Reads the session JSON from stdin and prints ONE colored status line.
# Segments are separated by a dim " | " and any empty-field segment is skipped.
# =============================================================================

# GUI launches don't inherit the shell PATH — make jq/git findable.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:$PATH"

# Resolve jq with an explicit fallback (in case PATH still misses it).
JQ="$(command -v jq 2>/dev/null || true)"
if [ -z "$JQ" ]; then
  for d in /opt/homebrew/bin /usr/local/bin /usr/bin; do
    if [ -x "$d/jq" ]; then JQ="$d/jq"; break; fi
  done
fi

input="$(cat)"
[ -n "$JQ" ] || { printf '%s\n' "(jq not found)"; exit 0; }

field() { printf '%s' "$input" | "$JQ" -r "$1 // empty" 2>/dev/null; }

cwd="$(field '.cwd')"
model="$(field '.model.display_name')"
effort="$(field '.effort.level')"
ctx="$(field '.context_window.remaining_percentage')"
five="$(field '.rate_limits.five_hour.used_percentage')"
seven="$(field '.rate_limits.seven_day.used_percentage')"

# ANSI colors (literal \033 — interpreted later by printf '%b').
DIM='\033[2m'; GREY='\033[90m'; CYAN='\033[1;96m'
GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; BYELLOW='\033[93m'
MAGENTA='\033[1;95m'
RESET='\033[0m'
SEP="${DIM} | ${RESET}"

segs=()

# cwd — dim grey
[ -n "$cwd" ] && segs+=("${GREY}${cwd}${RESET}")

# git branch — bright cyan + bold
if [ -n "$cwd" ]; then
  branch="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  [ -n "$branch" ] && segs+=("${CYAN}${branch}${RESET}")
fi

# Hey Clark active stage — magenta "🤖 <stage>" when a clark pipeline is running.
# The orchestrator writes ".clark/.active" as "<stage>|<agent>|<model>|<trace>|<ts>"
# (or "idle"). Show only if present, not idle, and modified within the last hour
# (so a crashed session's stale state auto-clears).
if [ -n "$cwd" ] && [ -f "$cwd/.clark/.active" ]; then
  if [ -n "$(find "$cwd/.clark/.active" -mmin -60 2>/dev/null)" ]; then
    active="$(head -n1 "$cwd/.clark/.active" 2>/dev/null)"
    stage="${active%%|*}"
    if [ -n "$stage" ] && [ "$stage" != "idle" ]; then
      segs+=("${MAGENTA}🤖 ${stage}${RESET}")
    fi
  fi
fi

# model — dim; append [effort] only when effort is set and not "medium"
if [ -n "$model" ]; then
  m="${DIM}${model}"
  [ -n "$effort" ] && [ "$effort" != "medium" ] && m="${m} [${effort}]"
  segs+=("${m}${RESET}")
fi

# ctx: N% — green >80, yellow >70, red otherwise
if [ -n "$ctx" ]; then
  ci=${ctx%%.*}
  if   [ "$ci" -gt 80 ] 2>/dev/null; then c="$GREEN"
  elif [ "$ci" -gt 70 ] 2>/dev/null; then c="$YELLOW"
  else c="$RED"; fi
  segs+=("${c}ctx: ${ctx}%${RESET}")
fi

# 5h: N% — bright yellow if >=70, else dim
if [ -n "$five" ]; then
  f5=${five%%.*}
  if [ "$f5" -ge 70 ] 2>/dev/null; then c="$BYELLOW"; else c="$DIM"; fi
  segs+=("${c}5h: ${five}%${RESET}")
fi

# 7d: N% — bright yellow if >=70, else dim
if [ -n "$seven" ]; then
  s7=${seven%%.*}
  if [ "$s7" -ge 70 ] 2>/dev/null; then c="$BYELLOW"; else c="$DIM"; fi
  segs+=("${c}7d: ${seven}%${RESET}")
fi

# Join segments with the dim separator.
line=""
for s in "${segs[@]}"; do
  if [ -z "$line" ]; then line="$s"; else line="${line}${SEP}${s}"; fi
done

# IMPORTANT: %b interprets the \033 escapes; the literal "%" in "ctx: 62%"
# is in the ARGUMENT (not the format string) so it is printed verbatim.
printf '%b\n' "$line"
