terraform {
  required_version = "~> 1.3"

  backend "s3" {
    endpoint = "nyc3.digitaloceanspaces.com"
    region   = "us"
    acl      = "private"
    bucket   = "jlindsey-personal-tf"
    key      = "cv.tfstate"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.25"
    }

    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.13"
    }
  }
}

provider "digitalocean" {}

provider "tailscale" {
  tailnet = "jlindsey.github"
}
