# 部署指导书：基于华为云 CDN 的按 URI 维护模式

## 0. 验证项核对结果（已按华为云官方文档核实）

| # | 验证项 | 结论（确切 Terraform 属性 / 现状） | 来源 |
|---|--------|-------------------------------|------|
| 1 | `huaweicloud_fgs_function` 是否暴露「CDN 边缘函数」模板开关 | **无该参数**。provider 资源无 `func_type`/`type` 之类的边缘模板开关。函数以普通**事件函数**创建，CDN 边缘身份在 CDN 控制台「函数管理」关联时指定。 | Terraform Registry / provider raw docs (`fgs_function.md`) |
| 2 | 边缘函数事件结构 `event.request.uri` | 事件对象为 `event.request.uri` / `event.request.headers`（字段名以 CDN 控制台「事件结构」为准）。**关键修正**：环境变量须用 `context.getUserData('KEY')` 读取（非 `context.env`/非 `process.env`）；响应头须用**简单键值对** `{ "content-type": "..." }` 格式。 | 华为云 FunctionGraph 环境变量文档 (`functiongraph_01_0154.html`)、事件函数响应示例 |
| 3 | `huaweicloud_cdn_domain` 能否声明「客户端请求」阶段规则 | **不支持**。该资源无任何边缘函数 / 触发器阶段参数（已核对全部顶层参数与 `configs` 下所有嵌套块）。边缘函数关联只能在 **CDN 控制台 → 域名管理 → 函数管理 → 添加阶段（客户端请求）** 完成。 | Terraform Registry / provider raw docs (`cdn_domain.md`)；CDN 边缘函数用户手册 (`functiongraph_01_0386.html`) |
| 4 | 加速域名是否需自有已备案域名 | **取决于服务范围**。`service_area = "mainland_china"` 或 `"global"` 时加速域名必须在工信部备案（ICP）；`outside_mainland_china`（国际加速）**免备案**，仅需自有可验证域名。本模板默认 `outside_mainland_china`（demo 免备案）。 | 华为云 CDN 约束与限制 / 域名准入要求 |

> Terraform 属性级修正（已应用到 `infra/`）：
> - 环境变量：`environment { ... }` → **`user_data = jsonencode({ ... })`**（fgs_function 唯一合法入口）
> - zip 代码：`func_code` 为 base64 时必须显式 `code_type = "zip"`
> - CDN 域名：补齐必填参数 **`service_area`**
> - 函数代码：`context.env.*` → **`context.getUserData('*')`**；响应头改为简单键值对
> - fgs_function 必须显式设 **`app`**（函数分组名：字母开头、小写/数字/下划线），缺省会报 `FSS.1027 Invalid app name`
> - **更新函数代码（PUT /code）会拒绝有效 zip**（报 `FSS.1011 zip: not a valid zip file`），但创建函数（POST）接受同一 zip。修改 `user_data`/代码后若 `apply` 原地更新失败，用 `terraform taint huaweicloud_fgs_function.maintenance` 再 `apply -target=huaweicloud_fgs_function.maintenance` 强制**重建**（走 POST 路径）即可绕过。
> - 维护开关：`MAINTENANCE_ENABLE` 默认来自变量 `maintenance_enabled`（默认 `false`）；想部署即开启维护，传 `TF_VAR_maintenance_enabled=true`。运行时切换改函数「配置 → 用户数据」里的 `MAINTENANCE_ENABLE`（0/1），无需重部署 CDN。

## 1. 前置条件
- 华为云账号（已实名认证）
- 自有**可验证所有权**的域名（在 DNS 添加 CNAME/TXT 记录即可）；**仅当 `service_area=mainland_china`/`global` 时才需 ICP 备案**。本仓库默认 `outside_mainland_china`，**免备案**，普通自有域名即可。
- 本地安装 Terraform ≥ 1.5，以及 huaweicloud provider（自动拉取）
- 华为云访问密钥 AK/SK（从控制台「我的凭证 → 访问密钥」创建），**仅在本地运行环境中配置，不写入文件**

## 2. 准备凭据（安全）
```bash
export HW_ACCESS_KEY="<HW_ACCESS_KEY>" # 真实值在本地配置，勿落盘
export HW_SECRET_KEY="<HW_SECRET_KEY>"
export TF_VAR_hw_access_key="$HW_ACCESS_KEY"
export TF_VAR_hw_secret_key="$HW_SECRET_KEY"
export TF_VAR_acceleration_domain="your-domain.example.com" # 你的加速域名
export TF_VAR_service_area="outside_mainland_china" # 默认即此值，免备案；仅面向大陆用户才改 mainland_china 并 ICP 备案
```

## 3. Terraform 部署
```bash
cd infra
terraform init
terraform validate # 语法校验
terraform plan # 预览资源
terraform apply # 建出 CDN 域名 + 边缘函数 + OBS 源站
```
> 若 `terraform validate` 报边缘函数模板/规则相关属性未支持，见第 4 节控制台补步骤。

## 4. 控制台补步骤（验证项，按环境核对）
> 以下为 Terraform 尚未暴露边缘函数能力时的兜底操作。

1. **将函数指定为 CDN 边缘函数**：登录 FunctionGraph 控制台 → 打开 `maintenance-edge-<suffix>` → 确认/切换为「CDN 边缘函数」模板（部分 region 在创建时选择，或通过 CDN 控制台关联时指定）。
2. **关联边缘函数规则**：CDN 控制台 → 域名管理 → 你的加速域名 → 边缘函数 → 添加规则：
- 函数：`maintenance-edge-<suffix>`
- 阶段：**客户端请求**
- 保存。
3. **配置 CNAME**：在域名服务商处添加 CNAME，指向 CDN 分配的 CNAME 域名，等待生效。

## 5. 使用方法与验证
- **关闭维护（默认）**：`MAINTENANCE_ENABLE=0` → 访问任意路径返回正常源站页面。
- **开启维护（仅 /shop/*）**：
- FunctionGraph 控制台 → 函数 → 配置 → 环境变量 → 将 `MAINTENANCE_ENABLE` 改为 `1` → 保存。
- 访问 `https://<你的加速域名>/shop/123` → 应返回 **503 + 维护页**。
- 访问首页或其它路径 → 仍返回正常页面。
- **修改命中路径**：把 `APPLIED_URI` 改为 `/api/*` 并保存，验证 `/api/*` 进入维护。
> 切换仅改环境变量、保存即生效，**无需重部署 CDN**。

## 6. 清理资源
```bash
cd infra && terraform destroy
```
> 执行后请在控制台确认相关资源已全部释放。
