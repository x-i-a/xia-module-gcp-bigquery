locals {
  project = yamldecode(file(var.project_file))
  module_name = substr(basename(path.module), 9, length(basename(path.module)) - 9)
  landscape = yamldecode(file(var.landscape_file))
  applications = yamldecode(file(var.applications_file))
  project_prefix = local.project["project_prefix"]
  environment_dict = local.landscape["environments"]
  application_list = lookup(lookup(local.landscape["modules"], local.module_name, {}), "applications", [])
}

locals {
  all_role_attribution = toset(flatten([
    for env_name, env in local.environment_dict : [
      for app_name in local.application_list : {
        app_name          = app_name
        env_name          = env_name
        project_id        = "${local.project_prefix}${env_name}"
      }
    ]
  ]))
}

locals {
  module_name = coalesce(var.module_name, substr(basename(path.module), 9, length(basename(path.module)) - 9))

  landscape = var.landscape
  applications = var.applications
  settings = lookup(local.landscape, "settings", {})
  cosmos_name = local.settings["cosmos_name"]
  realm_name = local.settings["realm_name"]
  foundation_name = local.settings["foundation_name"]
  environment_dict = var.environment_dict

  app_to_activate = lookup(var.module_app_to_activate, local.module_name, [])
  app_configuration = { for k, v in var.app_env_config : k => v if contains(local.app_to_activate, v["app_name"]) }
}


resource "google_project_service" "bigquery_api" {
  for_each = local.environment_dict

  project     = var.gcp_projects[each.key]["project_id"]
  service = "bigquery.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_iam_custom_role" "gcp_module_dataset_deployer_role" {
  for_each = local.environment_dict

  project     = var.gcp_projects[each.key]["project_id"]
  role_id     = "gcpModuleDatasetDeployer"
  title       = "GCP Bigquery Dataset Deployer Role"
  description = "GCP Bigquery Dataset Deployer Role"
  permissions = [
    "bigquery.datasets.create",
    "bigquery.datasets.get",
    "bigquery.datasets.update",
    "bigquery.datasets.delete"
  ]
}

resource "google_project_iam_member" "gcp_module_table_dataset_role_member" {
  for_each = app_configuration

  project = var.gcp_projects[each.value["env_name"]]["project_id"]
  role    = google_project_iam_custom_role.gcp_module_dataset_deployer_role[each.value["env_name"]].id
  member  = "serviceAccount:wip-${each.value["app_name"]}-sa@${var.gcp_projects[each.value["env_name"]]["project_id"]}.iam.gserviceaccount.com"

  depends_on = [google_project_iam_custom_role.gcp_module_dataset_deployer_role]
}