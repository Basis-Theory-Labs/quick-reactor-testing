# 🔬 Quick Reactor Testing with Terraform

This repository provides a fast and minimal setup for testing [Basis Theory Reactors](https://developers.basistheory.com/docs/concepts/what-are-reactors) using Terraform.

## 🚀 What This Project Does

- Deploys a Reactor to your Basis Theory tenant using Terraform
- Provides a sample `reactor.js` to zip and return `hello.txt`
- Helps you test the setup with a single `curl` command

## 🧩 Prerequisites

- A [Basis Theory](https://www.basistheory.com) account
- Terraform installed on your machine
- Node.js environment (used by your Reactor script)

## 🔐 Authentication Setup

1. **Create a Management Application**  
   You need an API key with `reactor:*` permissions.

   👉 [Click here to create an application using the Customer Portal](https://portal.basistheory.com/applications/create?permissions=reactor%3Acreate&permissions=reactor%3Aread&permissions=reactor%3Aupdate&permissions=reactor%3Adelete&type=management&name=Terraform)

2. **Configure Terraform variables**
   ```sh
   cp terraform.tfvars.example terraform.tfvars
   # Paste your Management API key in terraform.tfvars under BT_MANAGEMENT_API_KEY

## ⚙️ Installation
Initialize your Terraform workspace:

```shell
terraform init
```

## 🛠️ Customize the Reactor
Modify the behavior in `reactor.js`. Update `main.tf` if you want to change the reactor configuration or add more.

📦 Deploy
Apply your Terraform configuration:

```shell
terraform apply
```

You’ll receive output variables like `reactor_id` and `bt_private_key`.

## 🧪 Test the Reactor
Use the output values from terraform apply in the following curl command to [invoke the Reactor](https://developers.basistheory.com/docs/api/reactors/#invoke-a-reactor):

```shell
curl -L 'https://api.basistheory.com/reactors/<REACTOR_ID>/react' \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H 'BT-API-KEY: <BT_PRIVATE_KEY>' \
-d '{ "args": { "contents": "hello world!" }}'
```
