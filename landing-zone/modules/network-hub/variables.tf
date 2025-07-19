# Variables for Network Hub
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "organization" {
  description = "Organization name"
  type        = string
}

variable "transit_gateway_config" {
  description = "Transit Gateway configuration"
  type = object({
    amazon_side_asn                 = number
    enable_auto_accept_shared_attachments = bool
    enable_default_route_table_association = bool
    enable_default_route_table_propagation = bool
  })
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_dx_gateway" {
  description = "Enable Direct Connect Gateway"
  type        = bool
  default     = false
}

variable "peer_transit_gateway_id" {
  description = "Peer Transit Gateway ID for cross-region connection"
  type        = string
  default     = null
}

variable "peer_transit_gateway_region" {
  description = "Peer Transit Gateway region"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}