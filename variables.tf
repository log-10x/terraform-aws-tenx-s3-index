variable "tenx_s3_index_user_supplied_tags" {
  description = "Tags supplied by the user to populate to all generated resources"
  type        = map(string)
  default     = {}
}

variable "tenx_s3_index_name" {
  description = "Set the name of the lambda function, defaults to 'tenx-s3-index-engine'"
  type        = string
  default     = "tenx-s3-index-engine"
}

variable "tenx_s3_index_lambda_image_version" {
  description = "Set the version of the docker image to use for this lambda, defaults to 'latesl'"
  type        = string
  default     = "latest"
}

variable "tenx_s3_index_lambda_mem" {
  description = "Set the memory size of the lambda function, defaults to 2048mb"
  type        = number
  default     = 2048
}

variable "tenx_s3_index_logs_retention_days" {
  description = "Set the CloudWatch logs retention days policy of the lambda function, defaults to 7"
  type        = number
  default     = 7
}

variable "tenx_s3_index_source_bucket_name" {
  description = "Name of S3 bucket from which objects will be read"
  type        = string

  validation {
    condition     = length(var.tenx_s3_index_source_bucket_name) != 0
    error_message = "tenx_s3_index_source_bucket_name can't be empty"
  }
}

variable "tenx_s3_index_source_bucket_filter_prefix" {
  description = "Prefix filter for objects to work on from source bucket"
  type        = string
  default     = ""
}

variable "tenx_s3_index_source_bucket_filter_suffix" {
  description = "Suffix filter for objects to work on from source bucket"
  type        = string
  default     = ""
}

variable "tenx_s3_index_create_source_bucket" {
  description = "Whether to create the source bucket or not"
  type        = bool
  default     = false
}

variable "tenx_s3_index_dest_bucket_name" {
  description = "Name of S3 bucket into which indexed data will be written. Defaults to 'source bucket' if omitted"
  type        = string
  default     = ""
}

variable "tenx_s3_index_create_dest_bucket" {
  description = "Whether to create the dest bucket or not"
  type        = bool
  default     = false
}

variable "tenx_s3_index_license_key" {
  description = "L1x account license key"
  type        = string
  sensitive   = true
  default     = "NO-LICENSE"
}

variable "tenx_s3_index_options" {
  description = "Set the options map to pass into the lambda each execution."
  type        = map(any)
  default     = {}
}
