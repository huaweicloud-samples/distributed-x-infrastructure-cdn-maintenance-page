# 架构说明：基于华为云 CDN 的按 URI 维护模式

## 1. 目标
在 CDN 边缘对指定 URI 路径返回「维护中」页面（HTTP 503），其余请求正常回源；维护开关、URI 规则、维护页内容均可**不重新部署**即可调整。

## 2. 组件
| 组件 | 华为云服务 | 职责 |
|---|---|---|
| 边缘函数 | **FunctionGraph（CDN 边缘函数模板）** | 在「客户端请求」阶段读取配置，命中规则则返回 503 维护页，否则放行回源 |
| 加速域名 | **CDN（内容分发网络）** | 接管客户端请求、执行边缘函数、回源取正常内容 |
| 源站（可选） | **OBS 桶** | 演示用正常页面；生产可替换为自有业务源站 |

## 3. 架构图
```
客户端请求
│
▼
┌──────────────────┐
│ CDN 加速域名 │
│ (阶段:客户端请求) │
└──────────────────┘
│ 触发边缘函数规则
▼
┌──────────────────────────────┐
│ FunctionGraph 边缘函数 │
│ 读环境变量: │
│ MAINTENANCE_ENABLE=0/1 │
│ APPLIED_URI=/shop/* │
│ MAINTENANCE_PAGE=<html> │
└──────────────────────────────┘
│ │
命中(enable=1 未命中 / enable=0
且 URI 匹配) │
│ │
▼ ▼
返回 503 维护页 回源 OBS / 业务源站
(含安全响应头) 返回正常内容
```

## 4. 配置项（环境变量）
| 变量 | 含义 | 示例 |
|---|---|---|
| `MAINTENANCE_ENABLE` | 总开关，`1` 开启维护模式，`0` 关闭 | `0` |
| `APPLIED_URI` | 命中即展示维护页的 URI 规则，支持 `*` 通配 | `/shop/*` |
| `MAINTENANCE_PAGE` | 维护页 HTML（建议 ≤ 数 KB） | 见 `infra/main.tf` 中 `maintenance_html` |

## 5. 行为说明
- 边缘函数在「客户端请求」阶段执行：若开关为 `1` 且请求 URI 匹配 `APPLIED_URI`，直接返回 503 + 维护页（含 HSTS、X-Content-Type-Options、X-Frame-Options、CSP 等安全头），**不回源**。
- 其余情况返回 `event.request`，CDN 正常回源取内容。
- URI 匹配把 `*` 转 `.*` 做正则（例如 `/shop/*`），需整段匹配。

## 6. 安全响应头
维护页响应固定携带：`cache-control: no-store`、`retry-after: 3600`、`strict-transport-security`、`x-content-type-options: nosniff`、`x-frame-options: SAMEORIGIN`、`x-xss-protection`、`referrer-policy`、`content-security-policy`。
