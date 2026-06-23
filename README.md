This repo is to different terraform code in Dmytros personal AWS account.
The code is not intended to be used by anyone else, and is not production ready. It is just a playground for me to learn terraform and AWS.

Bootstrap backend resources before using the remote S3 backend:

- Run locally: `./scripts/bootstrap-backend.sh`
- Or trigger the GitHub Actions workflow: `.github/workflows/bootstrap-backend.yml`

CI
--
This repository includes a GitHub Actions workflow that runs `terraform fmt -check` and `terraform validate` on pushes and PRs: `.github/workflows/terraform-ci.yml`.
