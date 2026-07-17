# 🔬 Quick Reactor Testing with Terraform

This repository provides a fast and minimal setup for testing [Basis Theory Reactors](https://developers.basistheory.com/docs/concepts/what-are-reactors) in your [Test Tenant](https://developers.basistheory.com/docs/api/test-tenants) using Terraform.

Test Tenants run in a dedicated testing environment, fully isolated from production infrastructure — ideal for development, integration testing, and load testing. All Test Tenant traffic uses the `https://api.test.basistheory.com` base URL, which this repo is configured with out of the box.

> ⚠️ **The Test environment is not PCI compliant.** Only use synthetic, non-production data when testing. Never store real consumer data in a Test Tenant. If you need PCI-grade testing, contact Basis Theory support about a Production Tenant.

## 🚀 What This Project Does

- Deploys a Reactor to your Basis Theory Test Tenant using Terraform
- Provides a sample `reactor.js` to zip and return `hello.txt`
- Helps you test the setup with a single `curl` command

## 🧩 Prerequisites

- A [Basis Theory](https://www.basistheory.com) account with a **Test Tenant**
- Terraform installed on your machine
- Node.js environment (used by your Reactor script)

## 🔐 Authentication Setup

1. **Create a Management Application**
   You need an API key with `reactor:*` permissions, created **in your Test Tenant** (the key will contain `_test_`).

   👉 [Click here to create an application using the Customer Portal](https://portal.basistheory.com/applications/create?permissions=reactor%3Acreate&permissions=reactor%3Aread&permissions=reactor%3Aupdate&permissions=reactor%3Adelete&type=management&name=Terraform)

2. **Configure Terraform variables**
   ```sh
   cp terraform.tfvars.example terraform.tfvars
   # Paste your Management API key in terraform.tfvars under BT_MANAGEMENT_API_KEY
   ```

## ⚙️ Installation
Initialize your Terraform workspace:

```shell
terraform init
```

## 🛠️ Customize the Reactor
Modify the behavior in `reactor.js`. Update `main.tf` if you want to change the reactor configuration or add more.

> 💡 If your Reactor or Proxy calls out to third-party APIs (PSPs, your own services, etc.), allowlist the Test environment's outbound IPs. See [IP Addresses](https://developers.basistheory.com/docs/api/ip-addresses).

📦 Deploy
Apply your Terraform configuration:

```shell
terraform apply
```

You’ll receive output variables like `reactor_id` and `bt_private_key`.

## 🧪 Test the Reactor
Use the output values from terraform apply in the following curl command to [invoke the Reactor](https://developers.basistheory.com/docs/api/reactors/#invoke-a-reactor):

```shell
curl -L 'https://api.test.basistheory.com/reactors/<REACTOR_ID>/react' \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H 'BT-API-KEY: <BT_PRIVATE_KEY>' \
-d '{ "args": { "contents": "hello world!" }}'
```

## 🏭 Using a Production Tenant

This repo targets the Test environment by default. To run against a Production Tenant instead, override the API URL in `terraform.tfvars` and use a Management key from your Production Tenant:

```hcl
BT_API_URL = "https://api.basistheory.com"
```

Remember to also use `https://api.basistheory.com` in the invoke `curl` above.

> ⚠️ **Do not output API keys in Production.** This repo's `bt_private_key` output prints the private application key in plain text (via `nonsensitive()`) for quick local testing — acceptable in a Test Tenant, but never in Production. Before applying against a Production Tenant, remove the `bt_private_key` output from `main.tf` (or drop the `nonsensitive()` wrapper so Terraform redacts it), and retrieve the key from the [Customer Portal](https://portal.basistheory.com/) or a secrets manager instead. Plain-text outputs end up in terminal logs, CI logs, and state files.
