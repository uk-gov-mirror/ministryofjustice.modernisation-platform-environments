data "archive_file" "github_workflow_trigger" {
  output_path = "${path.module}/build/github-workflow-trigger.zip"
  source_file = "${path.module}/lambda/handler.py"
  type        = "zip"
}
