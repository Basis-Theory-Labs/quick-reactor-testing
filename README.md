# 🔬 Quick Reactor Testing with Terraform

This repository provides a fast and minimal setup for testing [Basis Theory Reactors](https://developers.basistheory.com/docs/concepts/what-are-reactors) in your [Test Tenant](https://developers.basistheory.com/docs/api/test-tenants) using Terraform.

Test Tenants run in a dedicated testing environment, fully isolated from production infrastructure — ideal for development, integration testing, and load testing. All Test Tenant traffic uses the `https://api.test.basistheory.com` base URL, which this repo is configured with out of the box.

> ⚠️ **The Test environment is not PCI compliant.** Only use synthetic, non-production data when testing. Never store real consumer data in a Test Tenant. If you need PCI-grade testing, contact Basis Theory support about a Production Tenant.

## 🚀 What This Project Does

- Deploys **two** Reactors to your Basis Theory Test Tenant using Terraform — one per [runtime](https://developers.basistheory.com/docs/concepts/runtimes/)
- Both Reactors compute the **same** HMAC-SHA256 digest, so you can compare the runtimes apples-to-apples
- Helps you test each one with a single `curl` command

## 🧩 The Two Runtimes

Basis Theory Reactors run on one of two [runtimes](https://developers.basistheory.com/docs/concepts/runtimes/). This repo demonstrates both by computing the **same HMAC-SHA256** two ways:

| | Runtime | Dependency | Notes |
|---|---|---|---|
| [`node-bt/`](./node-bt) | `node-bt` (default, Node 16) | [`crypto-js`](https://www.npmjs.com/package/crypto-js) | Only a **curated whitelist** of npm packages is available ([see the list](https://developers.basistheory.com/docs/concepts/runtimes/node-bt)). Provisions synchronously. |
| [`node22/`](./node22) | `node22` (Node 22) | [`js-sha256`](https://www.npmjs.com/package/js-sha256) | Install **any** npm package via the `dependencies` map. `js-sha256` is _not_ on the node-bt whitelist, so this only works on `node22`. Provisions **asynchronously**. |

HMAC-SHA256 is a defined algorithm, so both libraries return a **byte-identical digest** for the same input — the only difference is which runtime and dependency produced it.

> ℹ️ **The two runtimes use different code contracts.** node22 is not a drop-in for node-bt:
>
> | | node-bt | node22 |
> |---|---|---|
> | **Handler input** | `req` — read `req.args.message`, `req.configuration.HMAC_KEY` | `event` — read `event.req.args.message`, `event.configuration.HMAC_KEY` |
> | **Response** | `return { raw: { ... } }` | `return { res: { body: { ... }, statusCode: 200 } }` |
>
> Compare [`node-bt/reactor.js`](./node-bt/reactor.js) and [`node22/reactor.js`](./node22/reactor.js) to see both. A node22 handler that throws (e.g. wrong destructuring) surfaces as a `502 Bad Gateway`, not a structured error — so match the contract exactly.

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

## 🛠️ Customize the Reactors
Each runtime lives in its own directory with its own `reactor.js` and `package.json`:

- `node-bt/reactor.js` — uses the curated `crypto-js`
- `node22/reactor.js` — uses the non-curated `js-sha256`

Edit `main.tf` to change the runtime configuration (dependencies, resources, timeout) or add more Reactors.

To edit and test a Reactor's code locally, install its dependencies inside its directory:

```shell
cd node-bt && yarn   # or: cd node22 && yarn
```

> The local `package.json`/`yarn.lock` are only for local editing and testing. At deploy time, `node-bt` uses its curated packages directly, and `node22` installs the dependencies declared in the `runtime { dependencies }` block of `main.tf`.

> 💡 If your Reactor or Proxy calls out to third-party APIs (PSPs, your own services, etc.), allowlist the Test environment's outbound IPs. See [IP Addresses](https://developers.basistheory.com/docs/api/ip-addresses).

## 📦 Deploy
Apply your Terraform configuration:

```shell
terraform apply
```

You'll receive output variables `node_bt_reactor_id`, `node22_reactor_id`, and `bt_private_key`.

> ⏳ The `node22` Reactor provisions **asynchronously**, so it may take a moment to become invocable after `apply`. The `node-bt` Reactor is ready synchronously.

## 🧪 Test the Reactors
Use the output values from `terraform apply` to [invoke each Reactor](https://developers.basistheory.com/docs/api/reactors/#invoke-a-reactor). The request body is the same for both:

```shell
# node-bt (crypto-js)
curl -L 'https://api.test.basistheory.com/reactors/<NODE_BT_REACTOR_ID>/react' \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H 'BT-API-KEY: <BT_PRIVATE_KEY>' \
-d '{ "args": { "message": "hello world!" }}'

# node22 (js-sha256)
curl -L 'https://api.test.basistheory.com/reactors/<NODE22_REACTOR_ID>/react' \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H 'BT-API-KEY: <BT_PRIVATE_KEY>' \
-d '{ "args": { "message": "hello world!" }}'
```

Both responses carry the **same** `digest`. The payloads are wrapped differently because of the runtime contracts above — node-bt returns it under `raw`, node22 returns the `res.body` directly:

```json
// node-bt
{ "raw": { "runtime": "node-bt", "digest": "4c6859526fcd72c0972e657f203d472a88fedb14a51fe6384d8ee54dd25cc721" } }

// node22
{ "runtime": "node22", "digest": "4c6859526fcd72c0972e657f203d472a88fedb14a51fe6384d8ee54dd25cc721" }
```

You can verify the expected digest yourself:

```shell
printf 'hello world!' | openssl dgst -sha256 -hmac 'super-secret-test-key'
```

## 🏭 Using a Production Tenant

This repo targets the Test environment by default. To run against a Production Tenant instead, override the API URL in `terraform.tfvars` and use a Management key from your Production Tenant:

```hcl
BT_API_URL = "https://api.basistheory.com"
```

Remember to also use `https://api.basistheory.com` in the invoke `curl` above.

> ⚠️ **Do not output API keys in Production.** This repo's `bt_private_key` output prints the private application key in plain text (via `nonsensitive()`) for quick local testing — acceptable in a Test Tenant, but never in Production. Before applying against a Production Tenant, remove the `bt_private_key` output from `main.tf` (or drop the `nonsensitive()` wrapper so Terraform redacts it), and retrieve the key from the [Customer Portal](https://portal.basistheory.com/) or a secrets manager instead. Plain-text outputs end up in terminal logs, CI logs, and state files.
