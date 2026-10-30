# 配置示例

这些示例是可选的起点，不由初始化向导自动应用。请结合自己的 Codex CLI 版本、模型供应商和安全要求调整；示例中的设置不是本项目运行的前提。

- [AGENTS.md.example](AGENTS.md.example)：Machine 中 Codex 用户级指令示例，对应 `~/.codex/AGENTS.md`。语言、职责和环境假设可按需修改。
- [config.toml.example](config.toml.example)：DeepSeek 模型供应商配置示例，对应 `~/.codex/config.toml`。模型、配置字段和客户端兼容性以 [DeepSeek 的 Codex 接入文档](https://api-docs.deepseek.com/zh-cn/quick_start/agent_integrations/codex)及所用版本为准；按该文档准备模型目录文件。

使用前先检查已有配置并按需合并，避免覆盖已有的 MCP、项目授权或其他设置。不要提交填写了真实密钥的文件；凭据、登录态和个人配置应保存在受控环境中。`config/local/`、`config/config.toml` 和 `config/AGENTS.md` 已加入 `.gitignore`，但忽略规则不能代替提交前的内容检查。
