provider "google" {
  alias = "google-dataset"
}

module "gcp_module_dataset" {
  providers = {
    google = google.google-dataset
  }

  source = "../../modules/gcp-module-dataset"

  config_dir = "../../../config/gcp/datasets"
  landscape = local.landscape
  environment_dict = local.environment_dict
}
