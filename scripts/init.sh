#!/usr/bin/env bash
set -Eeuo pipefail
if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) )); then shopt -s inherit_errexit; fi
log() { printf '%s [%s] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$1" "$2" >&2; }
fail() { log ERROR "$1"; exit 1; }
trap 'log ERROR "第 $LINENO 行失败；可能已部分完成，Machine 将保留。"' ERR
trap 'log WARN "已中断，请检查 Machine 状态。"; exit 130' INT TERM
if [[ -t 1 && "${TERM:-dumb}" != dumb && -z "${NO_COLOR:-}" ]]; then
  bold=$'\033[1m'; dim=$'\033[2m'; accent=$'\033[32m'; reset=$'\033[0m'
else
  bold=''; dim=''; accent=''; reset=''
fi
step() { printf '\n%s%s  %s%s\n' "$bold" "$1" "$2" "$reset"; }
choose_install() {
  local answer
  printf '\n  请选择：\n  %s1%s. %s\n  %s2%s. %s（默认）\n' "$bold" "$reset" "$1" "$bold" "$reset" "$2"
  while :; do
    printf '  输入 1 或 2 [2]: '
    read -r answer || fail '输入结束'
    case "$answer" in
      1) return 0 ;;
      2|'') return 1 ;;
      *) printf '  ! 无效输入，请输入 1 或 2。\n' ;;
    esac
  done
}
ask() {
  local answer
  while :; do
    printf '  %s?%s %s %s[y/N]%s ' "$accent" "$reset" "$1" "$dim" "$reset"
    read -r answer || fail '输入结束'
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO|'') return 1 ;;
      *) printf '    请输入 y 或 n。\n' ;;
    esac
  done
}

# 单文件内嵌安装实现；原样发送给 Linux Bash，不在宿主展开。
remote_script() {
  cat <<'CODEXBOX_REMOTE'
#!/usr/bin/env bash
set -Eeuo pipefail
if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) )); then shopt -s inherit_errexit; fi
trap 'printf "初始化失败：第 %s 行，请检查上方错误后重试。\n" "$LINENO" >&2' ERR
install_base=$1
install_codex=$2
shift 2
# shellcheck source=/dev/null
. /etc/os-release
[[ "$ID" == ubuntu ]] || { printf '目标不是 Ubuntu\n' >&2; exit 1; }
if [[ "$install_base" == yes ]]; then
  sudo -n true
  sudo -n apt-get update
  sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
fi
if [[ "$install_codex" == yes ]]; then
  command -v curl >/dev/null || { printf "缺少 curl；请安装基础工具包或手动安装 Codex。\n" >&2; exit 1; }
  task_tmp=$(mktemp -d)
  trap 'rm -rf -- "$task_tmp"' EXIT
  fetch() { curl --fail --location --proto '=https' --tlsv1.2 --connect-timeout 20 --max-time 180 "$1" -o "$2"; }
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v codex >/dev/null; then
    fetch https://chatgpt.com/codex/install.sh "$task_tmp/codex-install.sh"
    sh "$task_tmp/codex-install.sh"
  fi
  codex --version
fi
CODEXBOX_REMOTE
}
apply=false
case "${1:-}" in
  --apply) apply=true;;
  --dry-run|'') ;;
  --help|-h) printf '用法：bash scripts/init.sh [--dry-run|--apply]\n默认仅预览。\n'; exit 0;;
  *) fail '未知参数';;
esac
(( $# <= 1 )) || fail '参数过多'
[[ "$(uname -s)" == Darwin ]] || fail '请在 macOS 上运行'
command -v orb >/dev/null || fail '请安装并启动 OrbStack'
printf '\n%sCodexbox Setup%s\n' "$bold" "$reset"
printf '  创建 Ubuntu Machine，按需安装工具与 Codex CLI。\n'
if $apply; then printf '  模式：执行（最终确认后开始）\n'; else printf '  模式：预览（不会创建或安装）\n'; fi
step '01 / 04' 'Machine 配置'
orb version
help_text=$(orb create --help)
versions=()
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*ubuntu: ]]; then
    values=${line#*:}
    IFS=',' read -r -a items <<< "$values"
    for item in "${items[@]}"; do
      read -r token rest <<< "$item"
      token=${token##*/}
      [[ "$token" =~ ^[0-9]+\.[0-9]+$ ]] || fail '无法识别 Ubuntu 版本'
      versions+=("$token")
    done
  fi
done <<< "$help_text"
(( ${#versions[@]} > 0 )) || fail '未找到 Ubuntu 版本'
printf '\n  名称（回车使用 cxbox）\n  > '
read -r machine || fail '输入结束'
machine=${machine:-cxbox}
[[ "$machine" =~ ^[a-z][a-z0-9-]*$ && ${#machine} -le 63 ]] || fail '名称须小写字母开头，仅含小写字母、数字和连字符，最多 63 字符'
names=$(orb list --quiet)
while IFS= read -r name; do [[ "$name" != "$machine" ]] || fail '同名 Machine 已存在'; done <<< "$names"
printf '\n  请选择 Ubuntu 版本：\n'
for ((i=0; i<${#versions[@]}; i++)); do printf '    %s%s%s. Ubuntu %s\n' "$bold" "$((i+1))" "$reset" "${versions[i]}"; done
printf '\n  选择版本编号\n  > '
read -r choice || fail '输入结束'
[[ "$choice" =~ ^[1-9][0-9]?$ ]] || fail '版本编号无效'
(( choice <= ${#versions[@]} )) || fail '版本编号无效'
version=${versions[choice-1]}
packages=(ca-certificates curl git git-lfs openssh-client python3 jq ripgrep fd-find rsync unzip zip xz-utils bubblewrap dnsutils iputils-ping netcat-openbsd build-essential pkg-config)
step '02 / 04' '基础工具包'
printf '\n  网络与连接  ca-certificates, curl, openssh-client\n'
printf '              HTTPS 验证、文件下载和 SSH 连接\n'
printf '  Git 与代码  git, git-lfs, ripgrep, fd-find\n'
printf '              版本管理、大文件支持和代码搜索\n'
printf '  文件与数据  rsync, unzip, zip, xz-utils, jq, python3\n'
printf '              文件同步、压缩解压及 JSON 和脚本处理\n'
printf '  构建与沙箱  build-essential, pkg-config, bubblewrap\n'
printf '              编译工具、依赖查找和 Codex Linux 沙箱\n'
printf '  网络诊断    dnsutils, iputils-ping, netcat-openbsd\n'
printf '              DNS、连通性和 TCP 端口检查\n'
install_base=no
if choose_install '安装基础工具包' '跳过基础工具包'; then install_base=yes; fi
install_codex=no
step '03 / 04' 'Codex CLI'
printf '\n  官方安装命令：\n'
printf '    curl -fsSL https://chatgpt.com/codex/install.sh | sh\n'
printf '  选择自动安装时，向导会先下载脚本到临时文件，再执行。\n'
if choose_install '自动安装 Codex CLI' '稍后手动安装'; then install_codex=yes; fi
step '04 / 04' '执行计划'
printf '  Machine       %s / Ubuntu %s / 宿主原生架构\n' "$machine" "$version"
if [[ "$install_base" == yes ]]; then printf '  基础工具包    安装\n'; else printf '  基础工具包    跳过（含 bubblewrap 和 curl）\n'; fi
if [[ "$install_codex" == yes ]]; then printf '  Codex CLI     自动安装\n'; else printf '  Codex CLI     稍后手动安装\n'; fi
printf '\n  集成模式      OrbStack 默认集成（宿主文件共享与 SSH agent 集成）\n'
if [[ "$install_base" == yes ]]; then printf '  安装来源      Ubuntu 软件源\n'; fi
if [[ "$install_codex" == yes ]]; then printf '  安装来源      https://chatgpt.com/codex/install.sh\n'; fi
printf '  执行位置      orb -m %s，Machine 默认用户；系统包使用 sudo。\n' "$machine"
if ! $apply; then printf '\n%s✓%s 预览完成；添加 --apply 并确认后执行。\n' "$accent" "$reset"; exit 0; fi
if ! ask '确认创建并安装上述组件？'; then log INFO '已取消'; exit 0; fi
log INFO "创建 $machine"
orb create "ubuntu:$version" "$machine"
log INFO '安装所选组件'
remote_script | orb -m "$machine" bash -s -- "$install_base" "$install_codex" "${packages[@]}"
orb -m "$machine" uname -sm
log INFO "初始化完成。进入：orb -m ${machine}；认证、模型和桌面端接入另行配置。"
