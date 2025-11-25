# CertifyStack - Digital Certificate Verification System

A blockchain-based certificate and badge system that verifies educational competencies using smart contracts.

## Features

- Digital certificate issuance on blockchain
- Cryptographic verification of credentials
- Authorized issuer management
- Certificate revocation capabilities
- Expiry date tracking

## Smart Contract Functions

### Public Functions

- `issue-certificate` - Issue a new digital certificate
- `revoke-certificate` - Revoke an existing certificate
- `add-issuer` - Authorize a new certificate issuer (owner only)
- `remove-issuer` - Remove issuer authorization (owner only)

### Read-Only Functions

- `get-certificate` - Retrieve certificate details
- `verify-certificate` - Verify certificate validity and status
- `get-recipient-certificates` - Get all certificates for a recipient
- `is-authorized-issuer` - Check issuer authorization status
- `get-certificate-count` - Get total certificates issued

## Usage

Authorized educational institutions can issue verifiable certificates to students. Anyone can verify the authenticity and validity of certificates on-chain.

## Technology Stack

- Stacks Blockchain
- Clarity Smart Contracts