#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
task_tmp=$(mktemp -d)
trap 'rm -rf -- "$task_tmp"' EXIT
mkdir "$task_tmp/bin"
cat > "$task_tmp/bin/orb" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CALLS"
case "$*" in
  version) printf 'mock version\n';;
  'create --help') printf '  ubuntu: noble/24.04, resolute/26.04 (default)\n';;
  'list --quiet') printf '%s' "${EXISTING:-}";;
  'create ubuntu:24.04 cxbox') ;;
  '-m cxbox bash -s -- '* ) cat > "$REMOTE_INPUT";;
  '-m cxbox uname -sm') printf 'Linux arm64\n';;
  *) exit 99;;
esac
MOCK
chmod +x "$task_tmp/bin/orb"
export PATH="$task_tmp/bin:$PATH" CALLS="$task_tmp/calls" REMOTE_INPUT="$task_tmp/received.sh"
printf '\n1\n2\n2\n' | /bin/bash "$root/scripts/init.sh" > "$task_tmp/output"
[[ $(wc -l < "$CALLS") -eq 3 ]]
grep -q 'cxbox / Ubuntu 24.04' "$task_tmp/output"
if printf '\n' | EXISTING=cxbox /bin/bash "$root/scripts/init.sh" > /dev/null 2>&1; then exit 1; fi
if printf 'bad;name\n' | /bin/bash "$root/scripts/init.sh" > /dev/null 2>&1; then exit 1; fi
printf '\n2\n1\n1\n' | /bin/bash "$root/scripts/init.sh" > "$task_tmp/output"
grep -q 'Ubuntu 26.04' "$task_tmp/output"
grep -q 'Codex CLI     自动安装' "$task_tmp/output"
# 模拟确认执行，验证命令被发送至指定 Machine，并检查输入脚本。
printf '\n1\n2\n2\ny\n' | /bin/bash "$root/scripts/init.sh" --apply > "$task_tmp/applied"
grep -q '^-m cxbox bash -s -- no no ' "$CALLS"
[[ -s "$REMOTE_INPUT" ]]
/bin/bash -n "$REMOTE_INPUT"
grep -q 'apt-get install' "$REMOTE_INPUT"
printf '\n1\n1\n2\ny\n' | /bin/bash "$root/scripts/init.sh" --apply > "$task_tmp/base-applied"
grep -q '^-m cxbox bash -s -- yes no .*git-lfs.*fd-find.*netcat-openbsd.*build-essential' "$CALLS"
# 检查内嵌远端脚本本身的语法，不执行安装。
awk '/^CODEXBOX_REMOTE$/ {exit} /cat <<.*CODEXBOX_REMOTE/ {body=1; next} body {print}' "$root/scripts/init.sh" > "$task_tmp/remote.sh"
[[ -s "$task_tmp/remote.sh" ]]
/bin/bash -n "$task_tmp/remote.sh"
printf 'PASS: preview, version selection, optional packs, duplicate and invalid names, worker syntax\n'
