terraform {
  required_providers {
    basistheory = {
      source  = "basis-theory/basistheory"
      version = ">= 2.0.0"
    }
  }
}

variable "BT_API_URL" {}
variable "BT_MANAGEMENT_API_KEY" {}

provider "basistheory" {
  api_url = var.BT_API_URL
  api_key = var.BT_MANAGEMENT_API_KEY
}

resource "basistheory_reactor" "test_reactor" {
  name = "Test Reactor"
  code = file("reactor.js")
  configuration = {
    FILENAME: "hello.txt"
  }
}

resource "basistheory_application" "backend" {
  name = "Backend"
  type = "private"
  permissions = ["reactor:invoke"]
}

resource "basistheory_application_key" "backend_key" {
  application_id = basistheory_application.backend.id
}

output "reactor_id" {
  value = basistheory_reactor.test_reactor.id
}

output "bt_private_key" {
  // ⚠️ DO NOT expose API keys in pipeline outputs. This is for local testing only.
  value = nonsensitive(basistheory_application_key.backend_key.key)
}
