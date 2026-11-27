# HW5: Terraform for AWS

[GoIT assignment](https://www.edu.goit.global/uk/learn/28179789/32217374/35554222/homework)

This lab defines an S3 state backend, a VPC and a private ECR repository. Local checks, five mocked-provider tests and real AWS deployment passed. Remote state and DynamoDB locking were verified. All 28 lab resources were then removed and cleanup was checked through AWS APIs.

## Structure

```text
lesson-5/
  main.tf                  # Provider and three module calls
  backend.tf               # S3 backend; bucket supplied during init
  outputs.tf               # Backend, network and ECR outputs
  variables.tf             # Expected account ID and unique bucket name
  versions.tf              # Terraform and provider versions
  backend.hcl.example      # Non-secret backend example
  terraform.tfvars.example # Non-secret resource input example
  modules/
    s3-backend/             # Bucket, versioning, encryption and lock table
    vpc/                    # VPC, six subnets, gateways and routes
    ecr/                    # Image repository, scanning and access policy
  tests/lab.tftest.hcl      # Tests using a mocked AWS provider
```

## Modules

1. `s3-backend` creates a private, encrypted S3 bucket with versioning and a DynamoDB table. The table has a String partition key named `LockID`. Outputs show the S3 URL and table name. The bucket policy rejects unencrypted HTTP requests.
2. `vpc` creates `10.0.0.0/16`, three public and three private subnets across `eu-north-1a`, `eu-north-1b` and `eu-north-1c`. Public routes use an Internet Gateway. Private routes share one NAT Gateway in the first public subnet. This reduces the lab size but has one point of failure and can cause cross-zone traffic charges.
3. `ecr` creates a private repository with scan on push and immutable image tags. Its policy allows image push/pull actions for the current AWS account. IAM permissions are still required, including `ecr:GetAuthorizationToken` for login. No cross-account access is added.

The root provider and backend require the expected account ID. Use only a separate personal or course account. All resources use `eu-north-1`, the Region assigned to the personal Free-plan project. The LMS shows `us-west-2` as an example; the required resource structure is kept in Stockholm. Do not use an existing bucket or lock table from another project.

## Local checks without AWS

Use Terraform 1.17.2. The AWS provider is pinned to 6.74.0. Run from `lesson-5/`:

```bash
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
```

In the Ubuntu course VM, the CLI is in `$HOME/hw5-tools/terraform`. Add it to the current shell with `export PATH="$HOME/hw5-tools:$PATH"` before using the commands above.

The test file uses `mock_provider "aws"`. Its `command = apply` runs against fake provider data and does not create AWS resources. It checks state protection, routing, duplicate zones, ECR access and root module outputs. These tests do not verify real AWS permissions, network traffic, remote state or locking.

`terraform init -backend=false` downloads providers and prepares local validation. It does not create the S3 bucket or configure a working remote backend.

## Before real AWS use

An AWS account, AWS CLI and an authenticated profile named `devops-course` are required. Use a temporary console-based login with AWS CLI 2.32.0 or later. On a remote terminal, run `aws login --remote --profile devops-course --region eu-north-1` and follow the official sign-in flow. Keep credentials out of source files and chat.

```bash
export AWS_PROFILE=devops-course
aws sts get-caller-identity --query Account --output text
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

Edit both files. Replace the sample account ID with the account returned by STS. Set the same globally unique bucket name in both files. The `000000000000` value is a placeholder, not a real account to use.

Review AWS pricing and the exact plan before creating resources. NAT Gateway, its public IPv4 address, storage and requests may create charges. Free Tier credits do not prove that this lab is free for your account.

## First deployment: create the backend first

Terraform must open its backend before it can create resources. A new bucket cannot store the state that creates that same bucket. Use local state for the first backend setup:

```bash
mv backend.tf backend.tf.disabled
terraform init
terraform plan -target=module.s3_backend -out=bootstrap.tfplan
terraform show bootstrap.tfplan
terraform apply bootstrap.tfplan
```

Apply only after reviewing the plan and account. The target is used only for this first backend setup. The bucket and table now exist, while the state is still local.

Restore the backend file and move that same state to S3:

```bash
mv backend.tf.disabled backend.tf
terraform init -migrate-state -backend-config=backend.hcl
terraform state list
terraform plan -out=lesson-5.tfplan
terraform show lesson-5.tfplan
terraform apply lesson-5.tfplan
terraform output
```

Confirm the state copy when Terraform asks. Check that the bucket name in `backend.hcl` matches `terraform.tfvars`. The full plan must keep the existing backend resources and add the network and ECR resources. Do not continue if it proposes an unexpected replacement.

DynamoDB locking is deprecated in current Terraform. It is kept here because the assignment requires it and Terraform 1.17 supports it. New projects can use S3 lockfiles. A deprecation warning is expected when initializing this backend.

## Checks after a real apply

1. Run `terraform plan`. Expect no changes.
2. Check the remote state object `lesson-5/terraform.tfstate` and S3 versioning in the AWS console.
3. Verify DynamoDB locking with two sessions holding the same state lock. Record the second session's lock error. A configured table alone does not prove locking works.
4. Check all six subnet route-table links, the Internet Gateway and the NAT Gateway status in AWS.
5. Check ECR scan on push and its repository policy. Actual image scanning needs a pushed image and a supported image format.

Do not mark these checks passed until they have been run in AWS.

## Cleanup

The state bucket must remain available until state has moved back to local storage. Run in the same initialized directory with the same account and `terraform.tfvars`:

```bash
mv backend.tf backend.tf.disabled
terraform init -migrate-state
terraform state list
test -s terraform.tfstate
terraform plan -destroy -out=destroy.tfplan
terraform show destroy.tfplan
```

Confirm the state copy and verify that the local state contains this lab's resources. Review the destroy plan before deleting anything. For this disposable lab bucket, `force_destroy = true` permits deletion of all stored objects and versions. Use it only for this lab, after state migration.

After approval of the exact destroy plan:

```bash
terraform apply destroy.tfplan
mv backend.tf.disabled backend.tf
```

`terraform destroy` is the interactive alternative to planning with `-destroy` and applying the saved plan. Do not run it while this same bucket still holds the active remote state. If ECR contains images, remove only the lab images after review before destroying the repository.

After cleanup, verify that the NAT Gateway and Elastic IP are gone and that all lab resources were removed. A later fresh deployment must start with backend setup again. Keep local state, saved plans and `.terraform/` out of Git and shared ZIPs.

## Verification status

Verified on 27 November 2026 in Ubuntu 24.04.4 LTS ARM64, with Terraform 1.17.2 and AWS provider 6.74.0:

- `terraform init -backend=false` downloaded the provider signed by HashiCorp.
- `terraform fmt -check -recursive` passed.
- `terraform validate` passed.
- `terraform test` passed all 5 mocked-provider runs.
- STS confirmed the expected personal account, and AWS returned the three Stockholm availability zones.
- A real full plan proposed 28 creates, 0 updates and 0 deletes. The separate initial backend plan proposed 6 creates.
- The first apply created 6 backend resources. State was moved to S3, then the second apply created the remaining 22 resources.
- All 20 read-only AWS checks passed. They covered the expected account, 28 managed resources, encrypted and versioned S3 state, the lock table, subnet routes, gateways and ECR settings.
- Two real plans tested DynamoDB locking. The first held the state lock. The second failed with `Error acquiring the state lock` and `ConditionalCheckFailedException`. The first finished with no changes and released the lock normally.
- State was moved back to local storage with the same lineage and all 28 resources. The reviewed destroy plan contained exactly 28 deletes, with no creates or updates.
- Cleanup removed all 28 resources. All 17 cleanup checks passed, including released Elastic IP, deleted NAT Gateway, missing lab services and zero managed resources in local state.

The provider lock file is included. The run used a personal Free-plan project in Stockholm. No plan upgrade was performed. From the approved run start to completed deletion took about 17 minutes. Estimated fixed NAT and IPv4 charges are about USD 0.051, plus small request and storage charges. Final metered charges are not confirmed because billing can be delayed.

Network routes were checked through AWS APIs. No EC2 instance or end-to-end network traffic test was run. ECR scan on push was enabled, but no image was pushed and no image scan was tested. Private logs, resource IDs, account inputs and state are excluded from this repository and the submission ZIP.

## References

- [Terraform S3 backend and locking](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Backend setup and partial configuration](https://developer.hashicorp.com/terraform/language/backend)
- [Mocked-provider tests](https://developer.hashicorp.com/terraform/language/tests/mocking)
- [AWS NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Console-based temporary CLI login](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html)
- [AWS Regions assigned to new project accounts](https://docs.aws.amazon.com/accounts/latest/reference/sign-up-for-aws.html)
