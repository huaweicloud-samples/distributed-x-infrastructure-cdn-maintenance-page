terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

provider "huaweicloud" {
  region     = var.hw_region
  access_key = var.hw_access_key
  secret_key = var.hw_secret_key
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  suffix = var.name_suffix != "" ? var.name_suffix : random_id.suffix.hex

  # 维护页 HTML（参数说明：maintenance_page 键）
  maintenance_html = <<-EOT
    <!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Maintenance</title><style>body{font-family:Arial,sans-serif;background:#f4f4f4;margin:0;display:flex;justify-content:center;align-items:center;min-height:100vh}.c{text-align:center;background:#fff;padding:40px;border-radius:10px;box-shadow:0 4px 6px rgba(0,0,0,.1);max-width:600px}h1{color:#333;margin-bottom:20px}p{color:#666;font-size:18px}</style></head><body><div class="c"><h1>Site Under Maintenance</h1><p>We are performing scheduled maintenance. We will be back shortly.</p><p>Thank you for your patience.</p></div></body></html>
  EOT

  # OBS 桶访问域名（源站）。如需用自己的业务源站，把 huaweicloud_cdn_domain 的 sources.origin 改成你的源站。
  origin_domain = format("%s.obs.%s.myhuaweicloud.com", "maintenance-demo-origin-${local.suffix}", var.hw_region)
}

# ---------- 演示源站：OBS 桶 + 一个普通首页（可替换为真实源站）----------
resource "huaweicloud_obs_bucket" "origin" {
  bucket = "maintenance-demo-origin-${local.suffix}"
  acl    = "public-read" # 演示源站公开读，CDN 方可回源；生产可改为 private 并配置 CDNAccessPrivateOBS 委托
  tags = {
    Purpose = "cdn-maintenance-demo-origin"
  }
}

resource "huaweicloud_obs_bucket_object" "index" {
  bucket       = huaweicloud_obs_bucket.origin.bucket
  key          = "index.html"
  content      = "<!DOCTYPE html><html><body><h1>Normal Site</h1><p>This is the normal origin page.</p></body></html>"
  content_type = "text/html"
}

# ---------- FunctionGraph 边缘函数（CDN 边缘函数模板）----------
# 将 Node.js 源码打成 zip 供 fgs_function 使用
data "archive_file" "edge_fn" {
  type        = "zip"
  output_path = "${path.module}/.build/maintenance-edge.zip"
  source {
    content  = file("${path.module}/../src/functions/maintenance-edge/index.js")
    filename = "index.js"
  }
}

resource "huaweicloud_fgs_function" "maintenance" {
  name        = "maintenance-edge-${local.suffix}"
  app         = "maintenance_demo" # 函数分组名（app name），缺省时 API 报 FSS.1027；须字母开头、小写/数字/下划线
  runtime     = "Node.js18.15"
  handler     = "index.handler"
  memory_size = 128
  timeout     = 3
  code_type   = "zip"
  func_code   = filebase64(data.archive_file.edge_fn.output_path)

  # 维护配置包含开关、命中规则、维护页三个键；切换维护模式只需把 MAINTENANCE_ENABLE 改为 1 并保存（无需重部署 CDN）。
  # FunctionGraph 非 HTTP 函数通过 user_data（JSON 字符串）承载配置；代码中用 context.getUserData('KEY') 读取。
  user_data = jsonencode({
    MAINTENANCE_ENABLE = var.maintenance_enabled ? "1" : "0"
    APPLIED_URI        = "/shop/*"
    MAINTENANCE_PAGE   = local.maintenance_html
  })

  # 🔧 验证项（见 deployment-guide.md）：huaweicloud_fgs_function 无「CDN 边缘函数」模板参数；
  # 本资源只创建普通事件函数，CDN 边缘能力在 CDN 控制台「函数管理」关联时指定（阶段=客户端请求）。
}

# ---------- CDN 加速域名 ----------
resource "huaweicloud_cdn_domain" "cdn" {
  name = var.acceleration_domain
  type = "web" # 网站加速
  service_area = var.service_area

  sources {
    active      = 1
    origin      = local.origin_domain
    origin_type = "obs_bucket"
  }

  # 缓存配置：维护响应必须不缓存，正常页面可按需缓存
  # 🔧 验证项：边缘函数（客户端请求阶段）关联。若本资源暂不支持在 Terraform 内声明边缘函数规则，
  #   请在 CDN 控制台「边缘函数」中添加规则：选择 huaweicloud_fgs_function.maintenance，阶段=客户端请求。
}
