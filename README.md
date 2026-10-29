# QcSdkAnalysis

QC 海外 iOS SDK 的分析与归因模块，以预编译静态 XCFramework 通过 Swift Package Manager（SPM）分发，不提供业务实现源码。

## 环境要求

- iOS 17.0 或以上，使用支持 Swift 6.2 的完整 Xcode。
- 当前制品覆盖 iOS 真机 arm64 和模拟器 arm64，不包含 Intel 模拟器 x86_64。
- App / Unity 实际链接 SDK 的 Target 必须满足相同最低系统要求。

## 模块依赖

| 类型 | 自动带入的产品 |
|---|---|
| 自有模块 | `QcSdkCore` |
| 官方第三方 | `AdjustSdk`、`ThinkingDataCore`、`ThinkingSDK` |

依赖关系和版本以分发 `Package.swift` 为准。无需手动重复添加这些产品；多个功能包使用同一 Core 仓库和兼容的 Core exact 版本。不要把各模块的版本号相同理解为可以忽略依赖约束。

## 在 Xcode 中集成

1. 选择 **File → Add Package Dependencies…**，输入：

   ```text
   https://github.com/YuFengChen77/QcSdkAnalysis.git
   ```

2. 在本仓库 Releases 中选择所需的已发布版本，Dependency Rule 使用 **Exact Version**。
3. 选择 **QcSdkAnalysis** 产品，将 Add to Target 设为实际使用 SDK 的 App Target；Unity 通常为 `UnityFramework`。
4. 在该 Target 的 **Build Settings → Other Linker Flags** 保留原有值并添加：

   ```text
   $(inherited) -ObjC
   ```

5. 确认最低部署版本为 iOS 17.0 或以上，编译并运行。

SPM 自动下载 Release 中的 XCFramework ZIP、校验 checksum 并链接；不要再手动拖入同一 Framework。只有 README、尚无有效 tag / Package.swift / Release ZIP 的仓库还不能作为已发布 SDK 接入。

## 接入验证

下面仅验证模块可导入、反射类保留，不发起真实业务：

```swift
import Foundation
import QcSdkCore
import QcSdkAnalysis

precondition(NSClassFromString("QcSdkAnalysis.QcAnalysisManager") != nil)
```

`-ObjC` 缺失可能使只通过类名访问的实现被裁掉。业务通过 SDK 公开入口调用，不直接依赖内部实现类；通过编译和反射检查后，仍需完成本模块配置及业务联调。

## 分析配置与接入

本模块组织 Adjust、ThinkingData 的官方 SPM 产品，通过 Core 的现有分析抽象关联 SDK 事件；不需要手工拷贝旧的 ThinkingData 本地 ZIP 或重复初始化厂商 SDK。

按项目实际配置准备宿主 Info.plist：

| 配置项 | 用途 |
|---|---|
| `adjust_app_token` | Adjust 应用 Token |
| `adjust_link_token` | 使用 Adjust Link 时的配置 |
| `td_analytics_app_id` | ThinkingData 项目 App ID |
| `td_analytics_auto_collect_event` | 现有实现支持的自动采集事件配置，按项目约定填写 |
| `td_analytics_debug_mode` | 可选调试模式；正式发布前确认未使用测试专用模式 |

自动采集配置使用以下编号，以 `_` 分隔，例如 `1_2_3`：

| 编号 | 事件 |
|---|---|
| `1` | App Install |
| `2` | App Start |
| `3` | App End |
| `4` | View Screen |
| `5` | App Click |

未配置有效编号时不会由该配置开启自动采集。调试模式当前识别 `DEBUG` 和 `DEBUG_ONLY`，其他值沿用普通模式；正式环境不要保留测试专用配置。事件是否采集仍需遵循宿主的实际初始化和隐私流程。

沿用 Core 的启动、初始化、用户和游戏事件上报流程，不新增另一条业务会话链路。如需使用 `QcAnalysisManager` 暴露的 Adjust delegate、ThinkingData handler / properties，应在分析初始化前配置，并遵循公开 API 的线程约束。

- 统计启用、隐私同意、ATT 和自动采集按项目实际设计联调；最小集成示例不主动发送真实事件。
- 上报地址沿用 SDK 的现有配置，不能仅靠填写 App ID 判断服务端链路已通。
- 模块带有自身的 `PrivacyInfo.xcprivacy`，通过 SPM 资源 bundle 交付；不要在集成时删除。
- 正式发布应检查归因回调、登录 / 退出后的用户关联、自动事件配置和重复初始化。
- SDK 产品版本以当前 manifest 为准；从旧本地 ThinkingData 方案迁移时还需重新验证业务事件。

## 启动与生命周期

将 SDK 的启动事件合并进宿主已有 AppDelegate：`QcSdkApi.shared.application(_:didFinishLaunchingWithOptions:)`。它负责基础准备和插件发现，不能替代业务 `sdkInit`。沿用 `QcSdkApi.shared.sdkInit(...)` 及现有 delegate；初始化成功后再调用需要初始化结果的业务 API。

涉及 URL 回跳时，普通 App / Unity 转发 `QcSdkApi.shared.application(_:open:options:)`，Scene 宿主转发 `QcSdkApi.shared.scene(_:openURLContexts:)`。保留其他 SDK 的已有处理，按宿主实际入口转发，避免重复初始化和丢失回跳。Unity 宿主通过既有桥接管理器统一转发时，不要再重复调用同一条 Core 链路。

## 资源与分发目录

```text
Package.swift
README.md
QcSdkAnalysis/
├── Sources/
│   └── Dependencies.swift
└── Resources/
```

`Sources/Dependencies.swift` 只组织导入，不包含业务实现；辅助 target 为 `QcSdkAnalysisSupport`。接入方选择和导入的仍是 `QcSdkAnalysis`，不需要额外选择 Support 产品。本模块的资源由 SPM 处理成 `QcSdkAnalysis_QcSdkAnalysisSupport.bundle`，包括当前声明的资源与隐私文件；不需要手工复制。

Xcode 左侧未显示 XCFramework 不代表下载失败，文件通常位于工程 DerivedData 的 `SourcePackages/artifacts`。以包解析、Target 产品链接、构建和运行结果确认接入；不要为显示节点重复手动集成。

## 更新版本

1. 在 **PROJECT → 工程名 → Package Dependencies** 找到 `QcSdkAnalysis`，修改 Exact Version 为新的已发布版本。
2. 等待解析下载，必要时执行 **File → Packages → Resolve Package Versions**。
3. 核对其他模块的 Core exact 要求兼容，重新编译并联调。

无需删除依赖、手动替换 Framework 或改 import。已发布版本的 tag、提交、ZIP 和 checksum 固定；出现 `does not match previously recorded value` 或 checksum 冲突时联系维护者使用新版本，不关闭校验。

## 注意事项

- 自有 SDK 为静态链接，不重复同时集成手动 Framework 和 SPM 产品，不手工将自有静态 Framework 设置为 Embed & Sign。第三方若含动态依赖，由最终 App 正常嵌入和签名。
- 包解析与反射检查不代表业务验收完成；仍需验证归因、用户关联、事件上报及隐私配置。
- SDK 的资源和公开 `.swiftinterface` / Objective-C 头文件可以查看，但不包含业务实现源码。
- 不将 Client Secret、服务端密钥、授权 token 或内部日志提交到公开仓库。
- Core 通用集成和业务配置另见 [QcSdkCore README](https://github.com/YuFengChen77/QcSdkCore#readme)。

本文件在开发仓库的 `QcSdkAnalysis/README.md` 维护，生成分发包时自动复制；依赖声明仍以根 `Package.swift` 和本次发布清单为准。
