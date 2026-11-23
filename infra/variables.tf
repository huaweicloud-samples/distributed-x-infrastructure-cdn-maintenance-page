variable "hw_region" {
  description = "华为云区域，部署前按需修改"
  type        = string
  default     = "cn-north-4"
}

variable "hw_access_key" {
  description = "华为云 AK，从本地环境变量 HW_ACCESS_KEY 读取，不保存明文"
  type        = string
  sensitive   = true
}

variable "hw_secret_key" {
  description = "华为云 SK，从本地环境变量 HW_SECRET_KEY 读取，不保存明文"
  type        = string
  sensitive   = true
}

variable "acceleration_domain" {
  description = "CDN 加速域名。需已在域名服务商配置指向 CDN CNAME，且在中国大陆区域需完成 ICP 备案"
  type        = string
}

variable "service_area" {
  description = "CDN 服务范围：mainland_china / outside_mainland_china / global。mainland_china 与 global 要求加速域名已在工信部备案（ICP）；outside_mainland_china 免备案，仅需自有可验证域名。本仓库为 demo，默认 outside_mainland_china（无需备案）。生产若面向中国大陆用户请改回 mainland_china 并完成 ICP 备案。"
  type        = string
  default     = "outside_mainland_china"
}

variable "name_suffix" {
  description = "资源名后缀，留空则自动生成随机后缀"
  type        = string
  default     = ""
}

variable "maintenance_enabled" {
  description = "维护模式默认开关。true = 部署后即进入维护（MAINTENANCE_ENABLE=1，CDN 命中 applied_uri 即返回 503）；false = 默认正常服务（MAINTENANCE_ENABLE=0）。无论默认值如何，都可在 FunctionGraph 控制台「配置 → 用户数据」里随时改 MAINTENANCE_ENABLE 切换，无需重部署 CDN。"
  type        = bool
  default     = false
}
