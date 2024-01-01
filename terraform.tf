terraform {
  backend "gcs" {
    bucket = "tf-states-terenowe-info"
    prefix = "terraform/state"
  }
}
