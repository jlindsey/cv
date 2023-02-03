data "digitalocean_domain" "jlindsey_me" {
  name = "jlindsey.me"
}

resource "digitalocean_project" "cv_project" {
  name        = "CV"
  purpose     = "Web Application"
  description = "CV junk"
  is_default  = false
  environment = "Production"
}

resource "digitalocean_ssh_key" "cv_key" {
  name       = "cv"
  public_key = file("${path.module}/cv.pub")
}

resource "digitalocean_tag" "cv_tag" {
  name = "cv"
}

resource "digitalocean_firewall" "cv" {
  name = "cv-web-server"
  tags = [digitalocean_tag.cv_tag.id]

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_volume" "cv_web_data" {
  region      = "nyc1"
  name        = "webdata"
  size        = 10
  description = "cv web server data"
}

resource "digitalocean_reserved_ip" "cv_ip" {
  droplet_id = digitalocean_droplet.cv_server.id
  region     = digitalocean_droplet.cv_server.region
}

locals {
  name   = "cv-web-server"
  image  = "debian-11-x64"
  size   = "s-1vcpu-512mb-10gb"
  region = "nyc1"
}

resource "null_resource" "tailnet_key_replacer" {
  triggers = {
    name              = local.name
    image             = local.image
    size              = local.size
    region            = local.region
    userdata_template = filemd5("${path.module}/cloudinit/cv.yaml.tmpl")
    tailscale_apt_key = filemd5("${path.module}/cloudinit/tailscale.key")
    docker_apt_key    = filemd5("${path.module}/cloudinit/docker.key")
    zshrc             = filemd5("${path.module}/cloudinit/zshrc")
    web_compose       = filemd5("${path.module}/cloudinit/docker-compose.yaml")
    caddyfile         = filemd5("${path.module}/cloudinit/Caddyfile")
  }
}

resource "tailscale_tailnet_key" "cv_server_key" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 600

  lifecycle {
    replace_triggered_by = [null_resource.tailnet_key_replacer]
  }
}

resource "digitalocean_droplet" "cv_server" {
  name              = local.name
  image             = local.image
  size              = local.size
  region            = local.region
  ssh_keys          = [digitalocean_ssh_key.cv_key.id]
  volume_ids        = [digitalocean_volume.cv_web_data.id]
  graceful_shutdown = true
  monitoring        = true
  tags              = [digitalocean_tag.cv_tag.id]

  user_data = templatefile("${path.module}/cloudinit/cv.yaml.tmpl", {
    tailscale_apt_key = jsonencode(file("${path.module}/cloudinit/tailscale.key"))
    docker_apt_key    = jsonencode(file("${path.module}/cloudinit/docker.key"))
    zshrc             = filebase64("${path.module}/cloudinit/zshrc")
    web_compose       = filebase64("${path.module}/cloudinit/docker-compose.yaml")
    caddyfile         = filebase64("${path.module}/cloudinit/Caddyfile")
    tailscale_key     = tailscale_tailnet_key.cv_server_key.key
  })
}

resource "digitalocean_project_resources" "droplet_project" {
  project   = digitalocean_project.cv_project.id
  resources = [digitalocean_droplet.cv_server.urn]
}

resource "digitalocean_record" "cv_jlindsey_me" {
  domain = data.digitalocean_domain.jlindsey_me.id
  type   = "A"
  name   = "cv"
  value  = digitalocean_reserved_ip.cv_ip.ip_address
  ttl    = 3600
}
