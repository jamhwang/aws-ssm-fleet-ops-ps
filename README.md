# AWS SSM Fleet Ops Toolkit (PowerShell)

Production-style PowerShell tooling for fleet operations modeled after **AWS Systems Manager (SSM)** workflows.  
Discover managed instances, generate and track Run Command executions, and export **audit-friendly results**.

This repository includes a **Mock Mode** so the full workflow is runnable **without an AWS account**.  
The AWS path is **planned** and follows the same structure and cmdlets you would use in production.

---

## Why this exists

Fleet operations often degrade into one-off scripts, manual console clicks, and inconsistent logs.  
This toolkit demonstrates a **repeatable, testable approach** to fleet operations:

- Deterministic target selection (tags / filters)
- Explicit command execution records
- Structured result collection
- Exportable artifacts for audit and review
- Clear separation of logic vs. CLI entrypoints

The goal is not a one-off script, but a **maintainable operational pattern**.

---

## Features

- List SSM-managed instances by tag
- Generate a Run Command request (Mock Mode)
- Fetch per-instance command results
- Export run artifacts to JSON and CSV
- Mock Mode for local development and demos
- Pester tests validating behavior

---

## Requirements

### PowerShell
- PowerShell 7+ recommended  
- Works on Windows, macOS, and Linux

### AWS Mode (planned)
If/when connected to an AWS account, the intended implementation uses:

- AWS Tools for PowerShell  
  - `AWS.Tools.SSM`
  - `AWS.Tools.EC2`
- Instances must be SSM-managed
- Minimum IAM permissions:
  - `ssm:SendCommand`
  - `ssm:GetCommandInvocation`
  - `ssm:ListCommandInvocations`
  - `ssm:DescribeInstanceInformation`
  - `ec2:DescribeInstances` (if discovering via EC2 tags)

---

## Quick Start (Mock Mode)

Mock Mode runs the full workflow locally using JSON fixtures under `mocks/`.

### 1) List target instances

```powershell
./scripts/Get-FleetInstances.ps1 -Mode Mock -TagKey Environment -TagValue Lab
