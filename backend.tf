# ==============================================================================
# Той самий бакет/DynamoDB-таблиця і той самий key ("terraform.tfstate"), що
# й на гілці lesson-7 — це один і той самий проєкт, що просто розростається
# новими модулями (jenkins, argo_cd) від уроку до уроку, а не паралельний
# незалежний стек. Якщо стейт lesson-7 вже існує в цьому бакеті/ключі,
# `terraform apply` тут просто ДОДАСТЬ нові ресурси до нього.
#
# Якщо застосовуєш з нуля (без lesson-7) — спершу пройди bootstrap:
# закоментуй блок нижче, `terraform init`, `terraform apply
# -target=module.s3_backend`, тоді розкоментуй і `terraform init
# -migrate-state`. Детальніше — у README.md.
# ==============================================================================

terraform {
  backend "s3" {
    bucket         = "REPLACE-WITH-YOUR-STATE-BUCKET-NAME"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
