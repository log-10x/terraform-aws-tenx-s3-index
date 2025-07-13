locals {
  tags = merge(var.tenx_s3_index_user_supplied_tags, {
    terraform-module         = "tenx-s3-index"
    terraform-module-version = "v0.1.0"
    managed-by               = "tenx-terraform"
  })

  dest_bucket_name = coalesce(var.tenx_s3_index_dest_bucket_name, var.tenx_s3_index_source_bucket_name)
  need_dest_bucket = local.dest_bucket_name != var.tenx_s3_index_source_bucket_name
}

module "tenx_s3_index" {
  source  = "log-10x/tenx-lambda/aws"
  version = "0.1.0"

  tenx_lambda_name                = var.tenx_s3_index_name
  tenx_lambda_image_version       = var.tenx_s3_index_lambda_image_version
  tenx_lambda_mem                 = var.tenx_s3_index_lambda_mem
  tenx_lambda_description         = "10x s3 indexer lambda"
  tenx_lambda_license_key         = var.tenx_s3_index_license_key
  tenx_lambda_logs_retention_days = var.tenx_s3_index_logs_retention_days

  tenx_lambda_user_supplied_tags = local.tags

  tenx_lambda_app     = "@apps/cloud/streamer/index"
  tenx_lambda_options = var.tenx_s3_index_options
}

resource "aws_s3_bucket" "source_bucket" {
  count  = var.tenx_s3_index_create_source_bucket ? 1 : 0
  bucket = var.tenx_s3_index_source_bucket_name
}

resource "aws_lambda_permission" "allow_bucket_trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.tenx_s3_index.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.tenx_s3_index_source_bucket_name}"
}

resource "aws_s3_bucket_notification" "s3_index_trigger" {
  bucket = var.tenx_s3_index_source_bucket_name

  lambda_function {
    lambda_function_arn = module.tenx_s3_index.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.tenx_s3_index_source_bucket_filter_prefix
    filter_suffix       = var.tenx_s3_index_source_bucket_filter_suffix
  }

  depends_on = [aws_lambda_permission.allow_bucket_trigger]
}

data "aws_iam_policy_document" "s3_source_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::${var.tenx_s3_index_source_bucket_name}",
      "arn:aws:s3:::${var.tenx_s3_index_source_bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_source_bucket_access_policy" {
  name        = "tenx_S3_Index_${module.tenx_s3_index.lambda_function_name}_access_to_${var.tenx_s3_index_source_bucket_name}"
  description = "Policy to grant 10x indexer lambda permissions to the s3 source bucket"

  policy = data.aws_iam_policy_document.s3_source_bucket_access.json
}

resource "aws_iam_role_policy_attachment" "s3_source_bucket_access_policy_attachment" {
  role       = module.tenx_s3_index.lambda_role_name
  policy_arn = aws_iam_policy.s3_source_bucket_access_policy.arn
}

resource "aws_s3_bucket" "dest_bucket" {
  count  = (var.tenx_s3_index_create_dest_bucket && local.need_dest_bucket) ? 1 : 0
  bucket = local.dest_bucket_name
}

data "aws_iam_policy_document" "s3_dest_bucket_access" {
  count = local.need_dest_bucket ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::${local.dest_bucket_name}",
      "arn:aws:s3:::${local.dest_bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_dest_bucket_access_policy" {
  count = local.need_dest_bucket ? 1 : 0

  name        = "tenx_S3_Index_${module.tenx_s3_index.lambda_function_name}_access_to_${local.dest_bucket_name}"
  description = "Policy to grant 10x indexer lambda permissions to the s3 dest bucket"

  policy = data.aws_iam_policy_document.s3_dest_bucket_access[0].json
}

resource "aws_iam_role_policy_attachment" "s3_dest_bucket_access_policy_attachment" {
  count = local.need_dest_bucket ? 1 : 0

  role       = module.tenx_s3_index.lambda_role_name
  policy_arn = aws_iam_policy.s3_dest_bucket_access_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "lambda_insights" {
  role       = module.tenx_s3_index.lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}
