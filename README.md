[![Startale](https://img.shields.io/badge/Made_with_%F0%9F%8D%8A_by-Startale-ff4e17?style=flat)](https://startale.com) [![License MIT](https://img.shields.io/badge/License-MIT-blue?&style=flat)](./LICENSE) [![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFBD10.svg)](https://getfoundry.sh/)

# Startale Smart Account Contracts 🚀

A modular smart account implementation compliant with ERC-4337 and ERC-7579 standards, built with Foundry.

## 📚 Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Core Components](#core-components)
- [Development](#development)
  - [Build](#build)
  - [Testing](#testing)
  - [Coverage](#coverage)
- [Deployment](#deployment)
- [Architecture](#architecture)
- [Security](#security)
- [License](#license)

## Features

<dl>
  <dt>ERC-4337 & ERC-7579 Compliance</dt>
  <dd>Full implementation of account abstraction standards with modular architecture.</dd>

  <dt>Modular Design</dt>
  <dd>Support for validators, executors, hooks, and fallback modules with easy extensibility.</dd>

  <dt>Factory Pattern</dt>
  <dd>Deterministic deployment of smart accounts with customizable initialization.</dd>

  <dt>Advanced Testing</dt>
  <dd>Comprehensive test suite including unit, integration, and property-based fuzzing tests.</dd>

  <dt>Gas Optimization</dt>
  <dd>Optimized for gas efficiency with support for both standard and IR-based compilation.</dd>

  <dt>Security Features</dt>
  <dd>Built-in security patterns including access control, module validation, and upgrade safety.</dd>
</dl>

## Getting Started

### Prerequisites

- Foundry (latest version)
- Node.js (v18.x or later) preferred: >= v23.7.0
- Yarn (or npm)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/startale/scs-aa-account-contracts.git
cd scs-aa-account-contracts
```

2. Install dependencies:
```bash
yarn install
git submodule update --init --recursive
```

3. Copy and configure environment variables:
```bash
cp .env.example .env
```

## Core Components

- **BaseAccount**: Core implementation of ERC-4337 account abstraction
- **StartaleSmartAccount**: Main smart account implementation with ERC-7579 compliance
- **ModuleManager**: Handles module installation, removal, and validation
- **Factory Contracts**: 
  - StartaleAccountFactory: Generic factory for custom deployments
  - EOAOnboardingFactory: Specialized factory for EOA-based accounts

## Development

### Build

Standard build:
```bash
yarn build
```

Optimized build (via IR):
```bash
yarn build:optimized
```

### Testing

Run all tests:
```bash
yarn test
```

Run specific test suites:
```bash
yarn test:unit        # Unit tests
yarn test:integration # Integration tests
yarn test:unit:deep   # Deep fuzzing tests
```

### Coverage

Generate coverage report:
```bash
yarn coverage
```

## Deployment

### Setup

1. Configure environment variables:
```bash
source .env
```

### Deploy

forge script script/DeployStartaleAccountFactoryCreate3.s.sol:DeployStartaleAccountFactoryCreate3 --rpc-url <RPC_URL> --broadcast --private-key <PRIVATE_KEY>
( and so on for other contracts)

```

## Architecture

The smart account implementation follows a modular architecture:

1. **Core Layer**
   - Base account abstraction
   - Module management
   - Storage management

2. **Module Layer**
   - Validators (e.g., ECDSA)
   - Executors
   - Hooks
   - Fallback handlers

3. **Factory Layer**
   - Deterministic deployment
   - Custom initialization
   - EOA onboarding

## Security

- ERC-7201 namespaced storage
- UUPS upgrade pattern
- Module validation and isolation
- Access control mechanisms

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## Reference 

<img src="https://raw.githubusercontent.com/defi-wonderland/brand/v1.0.0/external/solidity-foundry-boilerplate-banner.png" alt="wonderland banner" align="center" />
<br />

<div align="center"><strong>Start your next Solidity project with Foundry in seconds</strong></div>
<div align="center">A highly scalable foundation focused on DX and best practices</div>

<br />

## Export And Publish

Export TypeScript interfaces from Solidity contracts and interfaces providing compatibility with TypeChain. Publish the exported packages to NPM.

To enable this feature, make sure you've set the `NPM_TOKEN` on your org's secrets. Then set the job's conditional to `true`:

```yaml
jobs:
  export:
    name: Generate Interfaces And Contracts
    # Remove the following line if you wish to export your Solidity contracts and interfaces and publish them to NPM
    if: true
    ...
```

Also, remember to update the `package_name` param to your package name:

```yaml
- name: Export Solidity - ${{ matrix.export_type }}
  uses: defi-wonderland/solidity-exporter-action@1dbf5371c260add4a354e7a8d3467e5d3b9580b8
  with:
    # Update package_name with your package name
    package_name: "my-cool-project"
    ...


- name: Publish to NPM - ${{ matrix.export_type }}
  # Update `my-cool-project` with your package name
  run: cd export/my-cool-project-${{ matrix.export_type }} && npm publish --access public
  ...
```

You can take a look at our [solidity-exporter-action](https://github.com/defi-wonderland/solidity-exporter-action) repository for more information and usage examples.
