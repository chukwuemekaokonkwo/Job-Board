# Decentralized Job Board Smart Contract

A comprehensive blockchain-based employment platform built on the Stacks blockchain that enables transparent, trustless job posting and application management.

## Overview

This smart contract creates a decentralized job marketplace where employers can post job opportunities, manage applications, and facilitate hiring processes without intermediaries. Job seekers can browse listings, submit applications with cover letters, and track their application status in a transparent, immutable environment.

## Features

### For Employers
- **Job Posting Management**: Create, modify, and deactivate job postings
- **Application Tracking**: View and manage candidate applications
- **Status Updates**: Update application statuses (pending, accepted, rejected, under consideration)
- **Application Metrics**: Track total applications received per posting

### For Job Seekers
- **Browse Jobs**: Access all active job postings
- **Submit Applications**: Apply with personalized cover letters
- **Track Status**: Monitor application progress
- **Transparent Process**: Immutable record of all interactions

## Data Structures

### Job Postings
```clarity
{
  employer-principal: principal,
  position-title: (string-ascii 100),
  role-description: (string-ascii 1000),
  compensation-amount: uint,
  is-posting-active: bool,
  creation-block-height: uint,
  last-modification-height: uint
}
```

### Applications
```clarity
{
  cover-letter-content: (string-ascii 1000),
  current-application-status: (string-ascii 20),
  submission-block-height: uint
}
```

## Public Functions

### Job Posting Management

#### `create-new-job-posting`
Creates a new job posting with validation.

**Parameters:**
- `position-title` (string-ascii 100): Job title
- `role-description` (string-ascii 1000): Job description
- `compensation-amount` (uint): Compensation offered

**Returns:** Job posting ID

#### `modify-job-posting-details`
Updates an existing job posting (employer only).

**Parameters:**
- `posting-id` (uint): Job posting identifier
- `updated-position-title` (string-ascii 100): New job title
- `updated-role-description` (string-ascii 1000): New description
- `updated-compensation-amount` (uint): New compensation

#### `deactivate-job-posting`
Deactivates a job posting (employer only).

**Parameters:**
- `posting-id` (uint): Job posting identifier

### Application Management

#### `submit-candidate-application`
Submits a job application with cover letter.

**Parameters:**
- `posting-id` (uint): Target job posting ID
- `cover-letter-content` (string-ascii 1000): Cover letter text

#### `update-candidate-application-status`
Updates application status (employer only).

**Parameters:**
- `posting-id` (uint): Job posting ID
- `candidate-principal` (principal): Applicant's address
- `new-status` (string-ascii 20): New status value

**Valid Status Values:**
- `"pending-review"`
- `"accepted"`
- `"rejected"`
- `"under-consideration"`

## Read-Only Functions

### `get-job-posting-information`
Retrieves complete job posting details.

### `get-candidate-application-details`
Gets application information for a specific candidate.

### `get-total-job-postings-count`
Returns total number of job postings created.

### `get-posting-application-statistics`
Gets application count for a specific job posting.

### `is-job-posting-active`
Checks if a job posting is currently active.

### `verify-employer-ownership`
Verifies if an address owns a specific job posting.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u1 | `err-invalid-compensation-amount` | Invalid compensation amount |
| u2 | `err-posting-not-found` | Job posting not found |
| u3 | `err-posting-inactive` | Job posting is inactive |
| u4 | `err-unauthorized-access` | Unauthorized access attempt |
| u5 | `err-duplicate-application-submission` | Duplicate application |
| u6 | `err-invalid-posting-identifier` | Invalid posting ID |
| u7 | `err-invalid-status-transition` | Invalid status value |
| u8 | `err-invalid-input-parameters` | Invalid input parameters |

## Usage Examples

### Creating a Job Posting
```clarity
(contract-call? .job-board create-new-job-posting
  "Software Engineer"
  "Full-stack developer position with 3+ years experience required"
  u100000)
```

### Submitting an Application
```clarity
(contract-call? .job-board submit-candidate-application
  u1
  "I am excited to apply for this position. My experience includes...")
```

### Updating Application Status
```clarity
(contract-call? .job-board update-candidate-application-status
  u1
  'SP1234567890ABCDEF
  "accepted")
```

## Security Features

- **Access Control**: Only employers can modify their job postings and update application statuses
- **Input Validation**: Comprehensive validation for all inputs
- **Duplicate Prevention**: Prevents multiple applications from the same candidate
- **Immutable Records**: All interactions are permanently recorded on the blockchain