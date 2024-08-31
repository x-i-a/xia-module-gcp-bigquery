terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

locals {
  module_name = coalesce(var.module_name, basename(path.module))
  dataset_cfgs = { for file in fileset(var.config_dir, "**/*.yaml") :
      trimsuffix(basename(file), ".yaml") => yamldecode(file("${var.config_dir}/${file}"))
  }
}

resource "google_bigquery_dataset" "app_datasets" {
  for_each = local.dataset_cfgs

  dataset_id          = each.value["dataset_id"]
  description         = each.value["description"]
  friendly_name       = each.value["friendly_name"]
  location            = each.value["location"]
  delete_contents_on_destroy = each.value["delete_contents_on_destroy"]
}
