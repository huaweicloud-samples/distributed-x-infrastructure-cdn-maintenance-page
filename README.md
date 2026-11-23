# distributed-x-infrastructure-cdn-maintenance-page · 基于华为云 CDN 的按 URI 维护模式

[![License: MIT No Attribution](https://img.shields.io/badge/License-MIT--No--Attribution-green.svg)](LICENSE)
![ Huawei Cloud ](https://img.shields.io/badge/cloud-HuaweiCloud-ff0000) ![ Terraform ](https://img.shields.io/badge/IaC-Terraform-7B42BC) ![ CDN ](https://img.shields.io/badge/service-CDN-orange)

## 1. 简介 / Overview

### 简介


在 CDN 边缘对指定 URI 返回「维护中」页面（HTTP 503），其余请求正常回源。维护开关、URI 规则、维护页内容均可在**不重新部署**的情况下调整，适用于电商大促、版本发布等需要按路径临时拦截的场景。



核心能力：

- 按 URI 规则（支持 `*` 通配）返回维护页

- 切换维护模式仅改环境变量，免重部署

- 维护页携带完整安全响应头（HSTS / CSP / X-Frame-Options 等）

---

## 2. 目录

- [1. 简介 / Overview](#1-简介--overview)
- [2. 目录](#2-目录)
- [3. 架构图](#3-架构图)
- [4. 方案亮点](#4-方案亮点)
- [5. 涉及云服务](#5-涉及云服务)
- [6. 前置条件](#6-前置条件)
- [7. 快速开始](#7-快速开始)
- [8. 分步部署](#8-分步部署)
- [9. 使用方法 / 验证](#9-使用方法--验证)
- [10. 清理资源](#10-清理资源)
- [11. 详细说明](#11-详细说明)
- [12. 依赖](#12-依赖)
- [13. FAQ / 故障排除](#13-faq--故障排除)
- [14. 贡献指南](#14-贡献指南)
- [15. 许可证](#15-许可证)
- [16. 联系方式 / 维护者](#16-联系方式--维护者)


```

.

├── docs/ # 实践文档

│ ├── architecture.md

│ ├── deployment-guide.md

├── infra/ # Terraform

│ ├── main.tf

│ ├── variables.tf

│ └── outputs.tf

├── src/functions/maintenance-edge/index.js # 边缘函数代码

└── README.md

```



- CDN 边缘函数模板类型、事件结构、规则关联以控制台实际为准。

---

## 3. 架构图

- **CDN**：加速域名，触发边缘函数、回源。

- **FunctionGraph（CDN 边缘函数）**：客户端请求阶段读取环境变量，命中则返回 503 维护页。

- **OBS（可选）**：演示源站，生产可替换为自有业务源站。

---

## 4. 方案亮点

- **按 URI 粒度**：支持通配 `*` 规则，仅拦截指定路径，其余请求正常。

- **免重部署切换**：维护开关通过环境变量调整，保存即生效，无需重新部署。

- **安全响应头**：维护页携带完整安全头（HSTS / CSP / X-Frame-Options 等）。

---

## 5. 涉及云服务

- CDN（内容分发网络）

- FunctionGraph（CDN 边缘函数）

- OBS（对象存储服务）

---

## 6. 前置条件

- 华为云账号（已实名认证）

- 自有**可验证所有权**的域名（默认 `outside_mainland_china`，**免备案**；仅面向中国大陆用户才需 ICP 备案）

- Terraform ≥ 1.5

- 华为云访问密钥 AK/SK（在本地运行环境中配置）

---

## 7. 快速开始

```bash

export TF_VAR_hw_access_key="<HW_ACCESS_KEY>"

export TF_VAR_hw_secret_key="<HW_SECRET_KEY>"

export TF_VAR_acceleration_domain="your-domain.example.com" # 自有可验证域名即可；默认 outside_mainland_china，免备案



cd infra

terraform init

terraform validate

terraform apply

```

部署后在 CDN 控制台将 `maintenance-edge-<suffix>` 关联为「客户端请求」阶段边缘函数（详见部署指导书）。

---

## 8. 分步部署

1. 在 `infra/` 目录执行 `terraform init` 初始化 provider。

2. 设置 `TF_VAR_hw_access_key` / `TF_VAR_hw_secret_key` 环境变量。

3. 执行 `terraform validate` 校验语法。

4. 执行 `terraform apply` 部署 CDN 域名、边缘函数、OBS 源站。

5. 在 CDN 控制台将函数 `maintenance-edge-<suffix>` 关联为「客户端请求」阶段边缘函数。

6. 配置加速域名 CNAME 解析。

---

## 9. 使用方法 / 验证

### 使用方法


1. 默认 `MAINTENANCE_ENABLE=0`：访问任意路径返回正常源站页面。

2. 改为 `1` 并保存：访问 `/shop/123` 返回 **503 + 维护页**；其它路径仍正常。

3. 改 `APPLIED_URI=/api/*`：验证 `/api/*` 进入维护。

部署完成后请按本节步骤自行验证，确认业务功能可用，方可视为交付完成。

---

## 10. 清理资源

```bash

cd infra

terraform destroy

```

调试完毕及时执行上述命令，确认相关资源已释放，避免残留。

---

## 11. 详细说明

| 变量 | 含义 | 默认 |

|---|---|---|

| `MAINTENANCE_ENABLE` | 总开关 `0/1` | `0` |

| `APPLIED_URI` | 命中 URI 规则 | `/shop/*` |

| `MAINTENANCE_PAGE` | 维护页 HTML | 见 `infra/main.tf` |

---

## 12. 依赖

- 华为云 CDN、FunctionGraph、OBS 服务

- Terraform 官方及 huaweicloud provider

---

## 13. FAQ / 故障排除

### FAQ


**Q：边缘函数为何不在 Terraform 中直接关联 CDN？**

A：CDN 控制台关联边缘函数存在模板类型/事件结构差异，Terraform 配置需手工在控制台确认后回填，调试期建议先控制台关联。



**Q：默认区域是否需要 ICP 备案？**

A：`outside_mainland_china` 区域免备案；仅当域名面向中国大陆用户时才需 ICP 备案。

---

## 14. 贡献指南

欢迎提交 Issue 与 PR，请遵循仓库内现有目录与风格。

---

## 15. 许可证

本实践采用 **MIT No Attribution** 许可证，详见仓库根目录 [`LICENSE`](LICENSE) 文件。


本实践以 MIT-0 许可证发布。

---

## 16. 联系方式 / 维护者
| 项 | 内容 |
|---|---|
| **创建者** | [dgc-git](https://github.com/dgc-git) |
| **维护者** | [dgc-git](https://github.com/dgc-git) |
| **联系方式** | GitHub Issues / PR（见[第 14 节](#14-贡献指南)） |
