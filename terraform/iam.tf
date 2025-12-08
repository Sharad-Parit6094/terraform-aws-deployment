# IAM role used by ECS tasks (execution role)
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project}-${var.environment}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Policy allowing secretsmanager GetSecretValue only (least privilege)
data "aws_iam_policy_document" "secrets_read" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_secrets_policy" {
  name   = "${var.project}-${var.environment}-secrets-policy"
  policy = data.aws_iam_policy_document.secrets_read.json
}

resource "aws_iam_role_policy_attachment" "attach_secrets" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}
