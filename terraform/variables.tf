variable "region" {
  type = string
}

variable "public_key_path" {
  type = string
}
variable "ssh_key_path" {
  type = string
}

variable "servers" {
  type = map(object({
    ami           = string
    instance_type = string
    os_group    = string
    ssh_user    = string
    python_path = string
    
  }))
}