- [� Terraform Basics — Minimal Notes](#-terraform-basics--minimal-notes)
  - [📁 Terraform File Structure](#-terraform-file-structure)
  - [🟦 Provider](#-provider)
    - [Types](#types)
    - [Versioning](#versioning)
    - [Constraints](#constraints)
  - [🟩 Resource](#-resource)
  - [🟧 Data Source](#-data-source)
  - [🟦 Lambda Packaging (archive\_file)](#-lambda-packaging-archive_file)
    - [Structure](#structure)
    - [Package Code → ZIP](#package-code--zip)
    - [Use ZIP in Lambda](#use-zip-in-lambda)
  - [🟨 State File (`terraform.tfstate`)](#-state-file-terraformtfstate)
  - [🟪 Variables](#-variables)
  - [🟫 Outputs](#-outputs)

---
# 📘 Terraform Basics — Minimal Notes

## 📁 Terraform File Structure

```
.
└── main.tf
    ├── terraform {}   → providers
    ├── provider {}    → auth / region
    ├── resource {}    → resources to create
    ├── data {}        → Read-only info from cloud e.g ami_id
    ├── variable {}    → inputs
    └── output {}      → outputs
```

---
## 🟦 Provider

- Talks to cloud APIs
- Required in every config
- Installed via: `terraform init`

### Types

→ **Official** (AWS, Azure, GCP) | **Partner** | **Community**

### Versioning

→ Two versions: Terraform CLI + Provider  
→ Pin versions to avoid breakage

### Constraints

`=`, `!=`, `<`, `<=`, `>=`, `>`, `~>`

Examples:

- `~> 6.7.0` → 6.7.x
- `~> 1.0` → 1.x.x (not 2.0)

**Block**

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

---

## 🟩 Resource

→ The **actual infrastructure** Terraform creates.

Examples: S3, VPC, EC2

```hcl
resource "aws_s3_bucket" "mybucket" {
  bucket = "omi-demo-bucket"
}
```

---

## 🟧 Data Source

→ Read-only lookups
→ Fetch info, don’t create

Example:

```hcl
data "aws_ami" "latest" {
  most_recent = true
  owners      = ["amazon"]
}
```

---

## 🟦 Lambda Packaging (archive_file)

### Structure

```
.
├── main.tf
└── lambda/
    └── handler.py
```

### Package Code → ZIP

```hcl
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}
```

### Use ZIP in Lambda

```hcl
resource "aws_lambda_function" "my_lambda" {
  function_name = "demo-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}
```

---

## 🟨 State File (`terraform.tfstate`)

→ Terraform’s memory  
→ Stores IDs, attributes  

Must be:
- **Protected**
- **Not edited manually**
- **Stored remotely** (S3 + DynamoDB lock recommended)

---

## 🟪 Variables

→ Avoid hardcoding

```hcl
variable "region" {
  default = "us-east-1"
}
```

---

## 🟫 Outputs

→ Print useful info

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}
```
