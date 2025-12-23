# AWS SSM Fleet Ops Toolkit (PowerShell)

Production-style PowerShell tooling for fleet operations using AWS Systems Manager (SSM): discover managed instances, run remote commands at scale, and export audited results.

This repo includes a **Mock Mode** so the workflow is runnable without an AWS account. The AWS path is implemented with the same structure and cmdlets you’d use in production.

---

## Why this exists

Fleet operations often degrade into one-off scripts, manual clicking, and inconsistent logs. This toolkit standardizes:

- Target selection (tags / filters)
- Command execution (SSM Run Command)
- Result collection and export (JSON/CSV)
- Repeatable operational workflows

---

## Features

- List SSM managed instances by tag and status
- Send Run Command to a target set
- Fetch per-instance command results
- Export run artifacts to `reports/`
- Mock Mode for local demo + Pester tests

---

## Requirements

### PowerShell
- PowerShell 7 recommended (works on Windows/macOS/Linux)

### AWS Mode (optional)
If you later connect an AWS account:
- AWS Tools for PowerShell module (`AWS.Tools.SSM`, `AWS.Tools.EC2`)
- Instances must be SSM managed
- IAM permissions (minimum):
  - `ssm:SendCommand`
  - `ssm:GetCommandInvocation`
  - `ssm:ListCommandInvocations`
  - `ssm:DescribeInstanceInformation`
  - `ec2:DescribeInstances` (if discovering via EC2 tags)

---

## Quick Start (Mock Mode)

### 1) List instances
```powershell
./scripts/Get-FleetInstances.ps1 -Mode Mock -TagKey Environment -TagValue Lab
