# magpie for fnOS

把 [magpie](https://github.com/yetone/magpie)（多 Agent 统一的本地模型网关）打包成飞牛 fnOS 原生应用。

- 上游项目：https://github.com/yetone/magpie
- 上游开发者：yetone
- 本仓库只提供 fnOS 打包（第三方，`source=thirdparty`）

## 下载安装

在 [Releases](https://github.com/YUNXI-fi/magpie-fnos/releases) 下载对应架构的包：

| 架构 | 文件 |
|------|------|
| x86_64 | `magpie-<版本>-fnos-x86.fpk` |
| ARM64 | `magpie-<版本>-fnos-arm64.fpk` |

```bash
appcenter-cli install-fpk magpie-0.1.4407-fnos-x86.fpk
```

安装时会要求填写一段 16–64 位的访问密钥（字母、数字及 `. _ ~ -`），请自行保存。

本应用依赖应用商店的 **Bun**（`install_dep_apps=bunjs`）。插件运行时直接复用该 Bun（实测 1.3.9 可用），不会再像官方镜像那样在首次使用时从 GitHub 下载运行时。

## 使用

- 网页界面：`http://<设备地址>:3430`
- 首次登录：`http://<设备地址>:3430/?k=<安装时填写的密钥>`，浏览器记住 400 天；之后点桌面图标直接进入
- 模型网关：`http://127.0.0.1:3425`，供运行在本机的 Agent 使用（默认只监听回环地址，不对外暴露）

数据与配置保存在应用的 `TRIM_PKGVAR` 目录（`/var/apps/magpie/var`，实际落在 `/vol1/@appdata/magpie`），升级后保留；网页密钥落盘在其中的 `web.key`。

应用以专用系统用户 **magpie** 运行（`config/privilege` 中写的是 `run-as: package`，fnOS 会映射为以 appname 命名的专用用户），排障时请以此为准。

## 构建

依赖：`curl`、`git`、`tar`、`fnpack`（脚本会自动下载到缓存）以及各发行版自带的 `base64`/`sed`。

```bash
bash packaging/build.sh
```

产物输出到 `dist/fnos-x86/` 与 `dist/fnos-arm64/`，不上传、不入库。

可用环境变量：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PKG_VERSION` | `0.1.4407` | 应用包版本，用于覆盖安装/升级 |
| `MAGPIE_VERSION` | `0.1.4405` | 上游二进制版本 |
| `MAGPIE_CACHE` | `~/.cache/magpie-fpk` | 下载缓存目录（不写入仓库） |

升级上游：

```bash
MAGPIE_VERSION=0.1.45xx PKG_VERSION=0.1.4408 bash packaging/build.sh
```

## 目录结构

```
packaging/
├── build.sh              # 双架构构建
├── manifest              # 应用元数据（端口 3430、入口、平台、依赖 bunjs）
├── ICON.PNG / ICON_256.PNG
├── app/ui/config         # 桌面入口
├── app/ui/images/        # 入口图标
├── cmd/                  # 生命周期脚本，main 负责启停、PID 管理与 Bun 解析
├── config/               # privilege（run-as=package，实际用户为 magpie）、resource
└── wizard/install        # 安装时收集网页访问密钥
dist/                     # 构建产物（已忽略）
```
