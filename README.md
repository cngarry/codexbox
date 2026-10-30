# Codexbox

Codexbox 是一套在 macOS 上使用 OrbStack Machine 运行 Codex CLI 的方案。它把 Linux 执行环境与宿主桌面工作流连接起来，支持由 Main Agent 设计任务、独立的执行 Agent 调查和实施，再由 Main Agent 验收结果。

![跨设备 Agent 协作架构示例](images/codexbox-architecture.png)

图中展示一种多设备部署示例；设备、云盘、模型接入和迁移方式可按实际需求调整。

方案复用现有客户端和 SSH 能力，不包含自建 Agent 通信协议或调度服务。远程连接、会话管理和模型供应商的支持取决于客户端、账号及所用版本；请以实际能力为准。

## 快速开始

需要 macOS、已安装并启动的 [OrbStack](https://orbstack.dev/) 和网络连接。初始化向导默认仅预览，明确确认后才会创建 Machine：

```bash
bash scripts/init.sh
bash scripts/init.sh --apply
```

向导可选择 Ubuntu 版本、基础工具包和 Codex CLI 安装方式。详见[初始化向导](scripts/README.md)。创建后使用 `orb -m <machine>` 进入 Machine；认证、模型配置与桌面客户端连接需自行设置。`<machine>` 替换为实际 Machine 名称。

## 设计与使用

- [架构与协作](docs/architecture.md)：角色、任务契约、共享工作区与验收。
- [环境与安全边界](docs/environment.md)：SSH、文件共享、网络与运行维护。
- [配置示例](config/README.md)：Codex 用户指令与模型供应商配置。
- [External Agent Skill](skills/external-agent-codexbox/SKILL.md)：可按客户端能力调整的委派指引，任务契约使用 [agent-task-prompting](skills/agent-task-prompting/SKILL.md)。

默认 OrbStack 集成可访问宿主文件并可能使用宿主 SSH agent；Linux 环境不自动构成安全沙箱。启用共享与远程执行前，应结合实际权限和数据敏感度评估风险。不要将凭据、登录态、会话或个人配置放入仓库。

## 验证

```bash
bash -n scripts/init.sh tests/test-init.sh
bash tests/test-init.sh
```

测试模拟 OrbStack 命令，不创建 Machine、不安装软件。实际安装、客户端连接、模型调用和断连恢复需要在自己的环境中分别验证。

本仓库尚未指定开源许可证；使用、修改和分发权限以仓库后续明确的许可证为准。
