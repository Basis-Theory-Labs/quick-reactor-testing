terraform {
  required_providers {
    basistheory = {
      source  = "basis-theory/basistheory"
      version = "~> 5.2"
    }
  }
}

variable "BT_API_URL" {
  description = "Basis Theory API base URL. Defaults to the Test Tenant environment."
  default     = "https://api.test.basistheory.com"
}

variable "BT_MANAGEMENT_API_KEY" {
  description = "Management API key from your Test Tenant (contains _test_)."
  sensitive   = true
}

provider "basistheory" {
  api_url = var.BT_API_URL
  api_key = var.BT_MANAGEMENT_API_KEY
}

# node-bt runtime (default): HMAC-SHA256 via the curated `crypto-js` dependency.
# node-bt only allows a curated whitelist of npm packages, so no `dependencies` are declared.
resource "basistheory_reactor" "node_bt_reactor" {
  name = "HMAC Reactor (node-bt)"
  code = file("node-bt/reactor.js")
  configuration = {
    HMAC_KEY = "super-secret-test-key"
  }
  runtime {
    image = "node-bt"
  }
}

# node22 runtime: same HMAC-SHA256, but via `js-sha256` — a popular npm package that is NOT on
# the node-bt whitelist. node22 lets you install any dependency via the `dependencies` map.
resource "basistheory_reactor" "node22_reactor" {
  name = "HMAC Reactor (node22)"
  code = file("node22/reactor.js")
  configuration = {
    HMAC_KEY = "super-secret-test-key"
  }
  runtime {
    image     = "node22"
    timeout   = 30
    resources = "standard"
    dependencies = {
      "js-sha256" = "0.11.1"
    }
  }
}

# A single backend application can invoke both reactors.
resource "basistheory_application" "backend" {
  name        = "Backend"
  type        = "private"
  permissions = ["reactor:invoke"]
}

resource "basistheory_application_key" "backend_key" {
  application_id = basistheory_application.backend.id
}

output "node_bt_reactor_id" {
  value = basistheory_reactor.node_bt_reactor.id
}

output "node22_reactor_id" {
  value = basistheory_reactor.node22_reactor.id
}

output "bt_private_key" {
  // ⚠️ DO NOT expose API keys in pipeline outputs. This is for local testing only.
  value = nonsensitive(basistheory_application_key.backend_key.key)
}
