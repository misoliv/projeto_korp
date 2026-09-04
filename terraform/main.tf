terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.29"
    }
  }
}

# ============================================================
# PROVIDER
# ============================================================

provider "oci" {
  config_file_profile = "DEFAULT"
}

# ============================================================
# VARIÁVEIS
# ============================================================

variable "tenancy_ocid" {
  description = "OCID da tenancy OCI"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID do compartment onde os recursos serão criados"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Caminho da chave publica usada para acessar a VM"
  type        = string
  default     = "~/.ssh/projeto-korp-oci.pub"
}

# ============================================================
# AVAILABILITY DOMAIN
# ============================================================

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# ============================================================
# IMAGEM ORACLE LINUX 9
# ============================================================

data "oci_core_images" "oracle_linux_9" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.E2.1.Micro"

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

# ============================================================
# VCN
# ============================================================

resource "oci_core_vcn" "projeto_korp_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = "10.10.0.0/16"

  display_name = "projeto-korp-terraform-vcn"
  dns_label    = "projetokorp"
}

# ============================================================
# INTERNET GATEWAY
# ============================================================

resource "oci_core_internet_gateway" "projeto_korp_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.projeto_korp_vcn.id

  display_name = "projeto-korp-terraform-igw"
  enabled      = true
}

# ============================================================
# ROUTE TABLE
# ============================================================

resource "oci_core_route_table" "projeto_korp_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.projeto_korp_vcn.id

  display_name = "projeto-korp-terraform-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.projeto_korp_igw.id
  }
}

# ============================================================
# SECURITY LIST
# ============================================================

resource "oci_core_security_list" "projeto_korp_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.projeto_korp_vcn.id

  display_name = "projeto-korp-terraform-security-list"

  # Permite trafego de saida
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH - porta 22
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP - porta 80
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 80
      max = 80
    }
  }
}

# ============================================================
# SUBNET PUBLICA
# ============================================================

resource "oci_core_subnet" "projeto_korp_subnet" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.projeto_korp_vcn.id

  cidr_block = "10.10.1.0/24"

  display_name = "projeto-korp-terraform-subnet"
  dns_label    = "public"

  route_table_id = oci_core_route_table.projeto_korp_route_table.id

  security_list_ids = [
    oci_core_security_list.projeto_korp_security_list.id
  ]

  prohibit_public_ip_on_vnic = false
}

# ============================================================
# COMPUTE INSTANCE
# ============================================================

resource "oci_core_instance" "projeto_korp_instance" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  display_name = "projeto-korp-terraform"
  shape        = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    subnet_id        = oci_core_subnet.projeto_korp_subnet.id
    assign_public_ip = true
    hostname_label   = "korpvm"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux_9.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
  }
}

# ============================================================
# OUTPUTS
# ============================================================

output "availability_domain" {
  description = "Availability Domain utilizado"
  value       = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

output "oracle_linux_image" {
  description = "Imagem Oracle Linux utilizada"
  value       = data.oci_core_images.oracle_linux_9.images[0].display_name
}

output "vcn_name" {
  description = "Nome da VCN criada"
  value       = oci_core_vcn.projeto_korp_vcn.display_name
}

output "instance_name" {
  description = "Nome da VM"
  value       = oci_core_instance.projeto_korp_instance.display_name
}

output "public_ip" {
  description = "IP publico da VM"
  value       = oci_core_instance.projeto_korp_instance.public_ip
}