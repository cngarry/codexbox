# 初始化向导

在已安装并启动 OrbStack 的 macOS 上运行，使用 macOS 自带 Bash 3.2 与 `orb`，宿主无需 Python。

```bash
# 交互选择并预览，不创建 Machine 或安装软件
bash scripts/init.sh

# 交互选择、查看计划并确认执行
bash scripts/init.sh --apply
```

名称默认 `cxbox`，发行版固定 Ubuntu，版本从 `orb create --help` 的当前列表选择。默认使用宿主原生架构及 OrbStack 默认集成模式，包含文件共享和 SSH agent 集成。已有同名 Machine 会拒绝处理；不会删除、重建或修改全局默认 Machine。

基础工具包可选择安装或跳过，选择时按网络连接、代码搜索、文件处理、构建沙箱和网络诊断分类展示具体软件包。包含 `build-essential`、`git-lfs`、`fd-find`、`rsync` 和 `netcat-openbsd`。跳过后不会执行 apt 操作；若选择自动安装 Codex，Machine 须已有 curl 和可用的 HTTPS 证书。跳过也意味着不会安装 bubblewrap，使用 Codex Linux 沙箱前需自行补齐。

Codex 可选择下载官方安装脚本并执行，或稍后手动安装。自动安装使用官方脚本默认版本；不设置模型、认证和桌面端连接。外部脚本通过 HTTPS 下载到临时目录，执行后清理；执行前可查看计划中的来源。安装会访问 Ubuntu 软件源及选中的官方发布地址。

失败时停止并保留 Machine，不自动回滚已安装的软件。新建失败后可换名重新执行；部分安装失败需在保留的 Machine 内检查并手动补齐。该版本只处理新 Machine，不提供已有环境恢复模式。

验证：`bash tests/test-init.sh`。测试使用模拟 OrbStack，不创建资源。

`init.sh` 是单文件工具，内嵌 Linux 安装逻辑，通过 `orb -m <machine> bash -s -- ...` 和标准输入发送给指定 Machine 的默认用户执行；安装包通过 sudo 安装，无需其他安装脚本。
