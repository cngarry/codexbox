# 环境与安全边界

## Machine 与 SSH

在已启动 OrbStack 的 macOS 上，可通过向导创建 Ubuntu Machine，也可参考 [OrbStack Machine 文档](https://docs.orbstack.dev/machines/)手动创建。使用前检查本机 `orb create --help` 和 `orb list`。向导不修改默认 Machine，不处理已有同名 Machine。

```bash
orb list
orb -m <machine>
ssh <machine>@orb
```

将 `<machine>` 替换为实际名称。OrbStack 的 `orb` SSH 入口及用户选择方式参见[官方 SSH 文档](https://docs.orbstack.dev/machines/ssh)。桌面客户端接入方式及其支持情况以客户端实际能力为准，先验证目标 Machine 和用户，再执行任务。

## 文件与网络

默认集成模式下，Machine 可通过 `/mnt/mac` 访问宿主文件，修改或删除会直接影响原文件。macOS 可通过 OrbStack 文件共享访问 Machine 文件；Linux home 与 macOS home 是不同目录。具体行为参见[文件共享](https://docs.orbstack.dev/machines/file-sharing)和[网络文档](https://docs.orbstack.dev/machines/network)。

共享文件、宿主网络、SSH agent 转发和宿主命令集成可能扩大执行权限。默认集成并非隔离安全边界；按需评估 [OrbStack 隔离选项](https://docs.orbstack.dev/machines/isolated)及其对工作流的影响。启动服务时检查监听地址和实际网络暴露范围。Codex 的权限、沙箱和网络设置应按任务风险单独配置。

## 安装与维护

向导可选用 Ubuntu 软件源安装基础包，并可下载执行 Codex 官方安装脚本。安装来源和选择在执行前显示。失败时保留 Machine，可能存在部分安装；先检查状态，再手动修复或使用新名称重新创建。

Codex 的登录、模型、客户端连接和运行权限不由向导配置。凭据、私钥、登录态和会话数据应保存在各自的受控环境中，不要复制到仓库。不要覆盖已有配置；维护、更新或删除环境前先确认目标及恢复方式。

参考：[Codex CLI 文档](https://developers.openai.com/codex/cli/)、[OrbStack 命令](https://docs.orbstack.dev/machines/commands)。
