# distributed-x-infrastructure-cdn-maintenance-page

[![License: MIT No Attribution](https://img.shields.io/badge/License-MIT--No--Attribution-green.svg)](LICENSE)
![ Huawei Cloud ](https://img.shields.io/badge/cloud-HuaweiCloud-ff0000) ![ Terraform ](https://img.shields.io/badge/IaC-Terraform-7B42BC) ![ CDN ](https://img.shields.io/badge/service-CDN-orange)

## 1. Overview

### Introduction

Return a "maintenance in progress" page (HTTP 503) at the CDN edge for selected URIs, while all other requests continue to the origin. The maintenance switch, URI rules, and maintenance page content can all be adjusted **without redeployment**, which suits scenarios such as promotional events and version releases that require temporary path-level interception.

Core capabilities:

- Return the maintenance page according to URI rules (supporting `*` wildcards)
- Switch maintenance mode by changing environment variables only, with no redeployment
- The maintenance page carries a full set of security response headers (HSTS / CSP / X-Frame-Options, etc.)

---

## 2. Table of Contents

- [1. Overview](#1-overview)
- [2. Table of Contents](#2-table-of-contents)
- [3. Architecture Diagram](#3-architecture-diagram)
- [4. Highlights](#4-highlights)
- [5. Cloud Services Used](#5-cloud-services-used)
- [6. Prerequisites](#6-prerequisites)
- [7. Quick Start](#7-quick-start)
- [8. Step-by-Step Deployment](#8-step-by-step-deployment)
- [9. Usage / Verification](#9-usage--verification)
- [10. Cleanup](#10-cleanup)
- [11. Detailed Explanation](#11-detailed-explanation)
- [12. Dependencies](#12-dependencies)
- [13. FAQ / Troubleshooting](#13-faq--troubleshooting)
- [14. Contributing](#14-contributing)
- [15. License](#15-license)
- [16. Contact / Maintainers](#16-contact--maintainers)


```
.
├── docs/ # practice documentation
│ ├── architecture.md
│ ├── deployment-guide.md
├── infra/ # Terraform
│ ├── main.tf
│ ├── variables.tf
│ └── outputs.tf
├── src/functions/maintenance-edge/index.js # edge function code
└── README.md
```

- CDN edge function template types, event structures, and rule associations are subject to the actual console.

---

## 3. Architecture Diagram

- **CDN**: acceleration domain that triggers the edge function and fetches from the origin.
- **FunctionGraph (CDN edge function)**: reads environment variables during the client-request phase and returns the 503 maintenance page on a match.
- **OBS (optional)**: demo origin, replaceable with your own business origin in production.

---

## 4. Highlights

- **URI-level granularity**: supports wildcard `*` rules, intercepting only the specified paths while other requests continue normally.
- **Switch without redeployment**: the maintenance switch is adjusted through environment variables and takes effect as soon as it is saved.
- **Security response headers**: the maintenance page carries a full set of security headers (HSTS / CSP / X-Frame-Options, etc.).

---

## 5. Cloud Services Used

- CDN (Content Delivery Network)
- FunctionGraph (CDN edge function)
- OBS (Object Storage Service)

---

## 6. Prerequisites

- A Huawei Cloud account (identity verified)
- A domain you own with verifiable ownership (defaults to `outside_mainland_china`, no filing required; ICP filing is needed only when the domain serves users in mainland China)
- Terraform >= 1.5
- Huawei Cloud access keys AK/SK (configured in the local runtime environment)

---

## 7. Quick Start

```bash
export TF_VAR_hw_access_key="<HW_ACCESS_KEY>"
export TF_VAR_hw_secret_key="<HW_SECRET_KEY>"
export TF_VAR_acceleration_domain="your-domain.example.com" # any domain you own and can verify; defaults to outside_mainland_china, no filing required

cd infra
terraform init
terraform validate
terraform apply
```

After deployment, associate `maintenance-edge-<suffix>` as the edge function for the "Client Request" phase in the CDN console (see the deployment guide).

---

## 8. Step-by-Step Deployment

1. In the `infra/` directory, run `terraform init` to initialize the provider.
2. Set the `TF_VAR_hw_access_key` / `TF_VAR_hw_secret_key` environment variables.
3. Run `terraform validate` to check the syntax.
4. Run `terraform apply` to deploy the CDN domain, edge function, and OBS origin.
5. In the CDN console, associate the function `maintenance-edge-<suffix>` as the edge function for the "Client Request" phase.
6. Configure the CNAME resolution for the acceleration domain.

---

## 9. Usage / Verification

### Usage

1. With the default `MAINTENANCE_ENABLE=0`, any path returns the normal origin page.
2. Change it to `1` and save: `/shop/123` returns **503 + the maintenance page**, while other paths remain normal.
3. Change `APPLIED_URI=/api/*` and verify that `/api/*` enters maintenance mode.

After deployment, follow these steps to verify that the business functionality works before considering the delivery complete.

---

## 10. Cleanup

```bash
cd infra
terraform destroy
```

Run the command above promptly after debugging, and confirm that the related resources have been released so that nothing remains.

---

## 11. Detailed Explanation

| Variable | Meaning | Default |
|---|---|---|
| `MAINTENANCE_ENABLE` | Master switch `0/1` | `0` |
| `APPLIED_URI` | Matching URI rule | `/shop/*` |
| `MAINTENANCE_PAGE` | Maintenance page HTML | See `infra/main.tf` |

---

## 12. Dependencies

- Huawei Cloud CDN, FunctionGraph, and OBS services
- Official Terraform and the huaweicloud provider

---

## 13. FAQ / Troubleshooting

### FAQ

**Q: Why isn't the edge function associated with the CDN directly in Terraform?**
A: Associating an edge function in the CDN console involves differences in template types and event structures, so the Terraform configuration must be filled in after manual confirmation in the console. During debugging, associate it in the console first.

**Q: Is ICP filing required for the default region?**
A: The `outside_mainland_china` region does not require filing; ICP filing is needed only when the domain serves users in mainland China.

---

## 14. Contributing

Issues and PRs are welcome. Please follow the existing directory structure and style in the repository.

---

## 15. License

This practice is licensed under **MIT No Attribution**; see the [`LICENSE`](LICENSE) file in the repository root.

This practice is released under the MIT-0 License.

---

## 16. Contact / Maintainers
| Item | Content |
|---|---|
| **Creator** | [dgc-git](https://github.com/dgc-git) |
| **Maintainer** | [dgc-git](https://github.com/dgc-git) |
| **Contact** | GitHub Issues / PR (see [Section 14](#14-contributing)) |
