// 华为云 CDN 边缘函数（FunctionGraph 事件函数，关联至 CDN「客户端请求」阶段）
// 能力：读取函数配置中的维护参数，对命中 applied_uri 的请求直接返回 503 维护页，
//       其余请求放行回源（return event.request 即继续走 CDN 回源）。
//
// 实现要点（已按华为云官方文档确认）：
//   - 配置读取：非 HTTP 函数用 context.getUserData('KEY')，配置写在函数 user_data（JSON 字符串）
//   - 切换维护模式 = 更新 MAINTENANCE_ENABLE（0/1），无需重部署 CDN
//   - 响应头格式：简单键值对 { 'content-type': 'text/html' }
//   - 事件结构：event.request.uri / event.request.headers（字段名以 CDN 控制台「事件结构」为准；
//     本函数仅依赖 event.request.uri，鲁棒性较好，headers 的具体形态不影响主逻辑）

exports.handler = async (event, context) => {
  const enable = (context.getUserData('MAINTENANCE_ENABLE') || "0").trim();
  const requestUri = event.request && event.request.uri ? event.request.uri : "";

  if (enable === "1") {
    const appliedUri = context.getUserData('APPLIED_URI') || "";
    let matched = false;

    if (appliedUri) {
      // 把 /shop/* 这类通配转成正则：* -> .*，/ -> \/
      const pattern = appliedUri.replace(/\*/g, ".*").replace(/\//g, "\\/");
      const regex = new RegExp("^" + pattern + "$");
      matched = regex.test(requestUri);
    }

    if (matched) {
      const maintenancePage =
        context.getUserData('MAINTENANCE_PAGE') ||
        "<!DOCTYPE html><html><body><h1>Site Under Maintenance</h1></body></html>";

      // FunctionGraph 响应头用简单键值对格式
      return {
        statusCode: 503,
        statusDescription: "Service Unavailable",
        headers: {
          "content-type": "text/html;charset=UTF-8",
          "cache-control": "no-store",
          "retry-after": "3600",
          "strict-transport-security": "max-age=31536000; includeSubDomains",
          "x-content-type-options": "nosniff",
          "x-frame-options": "SAMEORIGIN",
          "x-xss-protection": "1; mode=block",
          "referrer-policy": "strict-origin-when-cross-origin",
          "content-security-policy": "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'"
        },
        body: maintenancePage
      };
    }
  }

  // 未开启维护，或当前 URI 不匹配 -> 放行回源
  return event.request;
};
