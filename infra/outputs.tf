output "function_name" {
  description = "边缘函数名称"
  value       = huaweicloud_fgs_function.maintenance.name
}

output "function_urn" {
  description = "边缘函数 URN（在 CDN 控制台关联时使用）"
  value       = huaweicloud_fgs_function.maintenance.urn
}

output "cdn_domain" {
  description = "CDN 加速域名"
  value       = huaweicloud_cdn_domain.cdn.name
}

output "origin_bucket" {
  description = "演示源站 OBS 桶"
  value       = huaweicloud_obs_bucket.origin.bucket
}

output "enable_maintenance" {
  description = "开启维护模式的运维动作"
  value       = "FunctionGraph 控制台 -> 函数 maintenance-edge-${local.suffix} -> 配置 -> 用户数据 -> 将 MAINTENANCE_ENABLE 改为 1 -> 保存（生效需数秒）"
}

output "disable_maintenance" {
  description = "关闭维护模式的运维动作"
  value       = "FunctionGraph 控制台 -> 函数 maintenance-edge-${local.suffix} -> 配置 -> 用户数据 -> 将 MAINTENANCE_ENABLE 改为 0 -> 保存（生效需数秒）"
}
