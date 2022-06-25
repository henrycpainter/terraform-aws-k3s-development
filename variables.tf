variable "use_spot_instance" {
  type        = bool
  default     = true
  description = "Whether to use spot instance. These are cheaper but will have less persistence."
}

variable "server_image_id" {
  type        = string
  default     = null
  description = "AMI to use for k3s server instances. If unprovided will fetch latest ubuntu."
}

variable "ssh_keys" {
  type        = list(string)
  default     = []
  description = "SSH keys to inject into instances"
}

variable "name" {
  type        = string
  default     = "k3s-demo"
  description = "Name for deployment"
}

variable "letsencrypt_environment" {
  type        = string
  default     = "production"
  description = "LetsEncrypt environment to use ('production' or 'staging')"
}

variable "letsencrypt_email" {
  type        = string
  default     = "none@none.com"
  description = "LetsEncrypt email address to use"
}

variable "domain" {
  type    = string
  default = "eng.rancher.space"
}

variable "r53_domain" {
  type        = string
  default     = ""
  description = "DNS domain for Route53 zone (defaults to domain if unset)"
}

variable "server_instance_types" {
  type        = list(string)
  default     = ["t4g.small"]
  description = "Possible types of instance to use."
}

variable "server_instance_ssh_user" {
  type        = string
  default     = "ubuntu"
  description = "Username for sshing into instances"
}

variable "certmanager_version" {
  type        = string
  default     = "1.5.4"
  description = "Version of cert-manager to install"
}

variable "vpc_id" {
  type        = string
  description = "The vpc id that should be used"
}

variable "public_subnets" {
  default     = []
  type        = list(any)
  description = "List of public subnet ids. Requires just 1."
}

variable "install_k3s_version" {
  default     = "1.24.1+k3s1"
  type        = string
  description = "Version of K3S to install"
}

variable "k3s_cluster_secret" {
  default     = null
  type        = string
  description = "Override to set k3s cluster registration secret"
}

variable "extra_server_security_groups" {
  default     = []
  type        = list(any)
  description = "Additional security groups to attach to k3s server instances"
}

variable "install_certmanager" {
  default     = false
  type        = bool
  description = "Boolean that defines whether or not to install Cert-Manager"
}

variable "server_k3s_exec" {
  default     = null
  type        = string
  description = "exec args to pass to k3s server"
}

variable "use_route53" {
  default     = true
  type        = bool
  description = "Configures whether to use route_53 DNS or not"
}
variable "subdomain" {
  default     = null
  type        = string
  description = "subdomain to host k3s on, instead of using `var.name`"
}

variable "server_volume_type" {
  default     = "gp3"
  description = "Volume Type for K3S Server nodes"
  type        = string
}