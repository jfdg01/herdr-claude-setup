#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
effort=$(echo "$input" | jq -r '.effort.level // empty')

tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
compact_threshold=140000
compact_pct=$(echo "$tokens $compact_threshold" | awk '{printf "%.0f", $1/$2*100}')

branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)

parts=()

parts+=("$(printf '\033[38;2;244;197;106m%s@%s\033[0m' "$(whoami)" "$cwd")")

if [ -n "$effort" ]; then
  parts+=("$(printf '\033[38;2;232;160;180m%s/%s\033[0m' "$model" "$effort")")
else
  parts+=("$(printf '\033[38;2;232;160;180m%s\033[0m' "$model")")
fi

if [ -n "$branch" ]; then
  parts+=("$(printf '\033[38;2;200;168;224m%s\033[0m' "$branch")")
fi

parts+=("$(printf '\033[38;2;168;196;232m%s (%s%%)\033[0m' "$tokens" "$compact_pct")")

five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
weekly_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$five_hour_pct" ] || [ -n "$weekly_pct" ]; then
  five_str=$([ -n "$five_hour_pct" ] && printf '%.0f' "$five_hour_pct" || echo "?")
  week_str=$([ -n "$weekly_pct" ] && printf '%.0f' "$weekly_pct" || echo "?")
  parts+=("$(printf '\033[38;2;150;220;150mUsage: %s%%/%s%%\033[0m' "$five_str" "$week_str")")
fi

printf '%s' "$(IFS=' '; echo "${parts[*]}")"
