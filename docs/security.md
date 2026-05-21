# 安全与隐私规约

> **核心原则：任何密钥、token、密码、私有 URL 都不能进入 git 仓库。**

本文说明 aidle-skills 的安全约定。所有贡献者、二次开发者请务必遵守。

## 用户级配置统一放在 `~/.aidle/`

所有 skill 需要的密钥与隐私配置**只应**存在于用户家目录：

```
~/.aidle/
├── config.env     # 所有 skill 共享的 KEY=VALUE 配置
└── repo           # 仓库绝对路径（aidle meta-skill 用）
```

仓库内已通过 `.gitignore` 排除 `.aidle/` 目录。

### 创建配置

```bash
mkdir -p ~/.aidle
cp examples/aidle-config.env.example ~/.aidle/config.env
chmod 600 ~/.aidle/config.env
# 然后编辑 ~/.aidle/config.env 填入真实值
```

### 读取优先级

skill 脚本应遵循统一的读取顺序：

1. 当前进程环境变量（最高，便于临时覆盖）
2. `~/.aidle/config.env`（持久化默认值）
3. 各 AI 工具的兼容配置（如 Codex 的 `~/.codex/auth.json`）

## `.gitignore` 覆盖范围

已排除：

| 类别 | 模式 |
| --- | --- |
| 环境变量文件 | `.env`, `.env.*`, `*.env`（保留 `*.env.example`） |
| 认证 / 凭证 | `auth.json`, `credentials.json`, `secrets.json`, `secrets/`, `*.secret(s)` |
| 证书与私钥 | `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.crt`, `*.cer`, `*.jks`, `*.keystore` |
| SSH 密钥 | `id_rsa*`, `id_ed25519*`, `known_hosts` |
| 云厂商凭证 | `.aws/`, `.gcp/`, `.azure/` |
| 本仓库专属 | `.aidle/` |

如果你的新 skill 引入了新的敏感文件类型，请同步更新 `.gitignore`。

## 编写 skill 的安全约定

写新 skill 时，务必遵守：

1. **不要硬编码任何密钥**到脚本、SKILL.md、README 中
2. **示例值用明显占位符**：`sk-xxxxxxxx`、`<your-token-here>`，不要写形似真实 key 的字符串
3. **从配置层读取**：env > `~/.aidle/config.env` > 各工具兼容路径
4. **可覆盖的 BASE_URL**：避免把私有 API URL 写死
5. **报错信息不泄漏 key**：永远不要在日志中 echo `$API_KEY`
6. **临时文件用 `mktemp`**：避免响应体落到固定路径
7. **设置 `chmod 600`**：脚本若自行写入配置文件，权限要收紧

## CI 自动扫描

仓库启用 **gitleaks** 作为 PR / push 必跑检查，扫描提交内容中潜在的密钥。

PR 触发 CI 失败时，请：

1. 移除疑似密钥的字符串
2. 改用占位符（如 `sk-xxxxxxxx`）
3. 重新 push

## 如果不小心提交了真实密钥

⚠️ **不要只删除文件再 commit**——历史里依旧能查到。

正确做法：

1. **立即作废该密钥**（在对应平台 revoke + 重新签发）
2. 用 [`git filter-repo`](https://github.com/newren/git-filter-repo) 或 [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) 重写历史
3. 强制推送：`git push --force-with-lease`
4. 通知所有协作者重新 clone（旧 clone 仍含泄漏历史）
5. 审计该 key 在泄漏期间是否被滥用

发现他人提交的密钥？请通过私下渠道联系维护者，不要在公开 issue 中再次曝光。

## 推荐工具

- [`pre-commit`](https://pre-commit.com/) + [`gitleaks`](https://github.com/gitleaks/gitleaks)：本地提交前自动扫描
- [`trufflehog`](https://github.com/trufflesecurity/trufflehog)：更激进的密钥扫描
- [`direnv`](https://direnv.net/)：项目级环境变量隔离（搭配 `.envrc` + `.gitignore`）
