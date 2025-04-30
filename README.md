# Nebula Token (NBLA)

A modern, secure, and feature-rich fungible token implementation for the Stacks blockchain ecosystem.

## Overview

Nebula Token (NBLA) is a comprehensive fungible token implementation built on Stacks using the Clarity language. It combines best practices for security, flexibility, and governance to create a robust foundation for decentralized applications and Web3 services.

## Key Features

### Core Functionality
- ✅ Full SIP-010 compatibility
- ✅ Precision decimal support (6 decimals)
- ✅ Atomic transfers with built-in safeguards
- ✅ Comprehensive event logging system

### Security Features
- 🔒 Time-bounded approvals
- 🔒 Contract freeze/unfreeze capability
- 🔒 Address blocking for risk mitigation
- 🔒 Overflow protection
- 🔒 Self-transfer prevention

### Governance & Utility
- 🏛️ Built-in voting power tracking
- 🏛️ Token vaulting mechanism
- 🏛️ Admin controls with transfer capability
- 🏛️ Supply control with maximum cap

## Technical Details

| Parameter | Value |
|-----------|-------|
| **Name** | Nebula Token |
| **Symbol** | NBLA |
| **Decimals** | 6 |
| **Maximum Supply** | 1,000,000,000,000,000 (1 trillion) |
| **Contract Language** | Clarity |

## Smart Contract Architecture

The Nebula Token contract is organized into several logical sections:

1. **Core Token Definition**: Fundamental token parameters and data structures
2. **Administrative Functions**: Contract control and privileged operations
3. **Token Operations**: Standard token functionality (transfer, approve, etc.)
4. **Vault Management**: Special locking mechanisms for tokens
5. **Query Functions**: Read-only functions for contract state

## User Functions

### Basic Token Operations

```clarity
;; Transfer tokens to another user
(contract-call? .nebula-token transfer u1000000 'SP2CBFR35C1F114YJK2HG975RXVN6617RFGYZH93E)

;; Approve a spender with time-bounded permission
;; Approve 500 tokens for 144 blocks (approximately 1 day)
(contract-call? .nebula-token approve u500000 'SP1P72Z3704VMT3DMHPP2CB8TGQWGDBHD3RPR9GZS (+ block-height u144))

;; Burn tokens to reduce supply
(contract-call? .nebula-token burn u100000)
```

### Vault Management

```clarity
;; Lock tokens in a vault for 30 days (4320 blocks)
(contract-call? .nebula-token vault-tokens u5000000 u4320)

;; Release tokens from vault (only works after time period)
(contract-call? .nebula-token release-vault)
```

### Administrative Functions

```clarity
;; Contract setup (only for admin)
(contract-call? .nebula-token setup "Nebula Token" "NBLA" u6)

;; Transfer admin control (only for current admin)
(contract-call? .nebula-token set-admin 'SP3FBR8CC4D3ST7HHRPRDBFX7Z6SGV2QZGBAY34WR)

;; Freeze token operations in emergency (only for admin)
(contract-call? .nebula-token freeze)

;; Block problematic address (only for admin)
(contract-call? .nebula-token block-address 'SP2JK59HG3VP4K1HXHHGME2QSWNK8NE53H3FMQDWH)
```

## Error Codes

Nebula Token provides clear error codes for all operations:

| Error Code | Description |
|------------|-------------|
| `ACCESS-DENIED` | Caller lacks permission for operation |
| `BALANCE-TOO-LOW` | Insufficient balance for operation |
| `INVALID-PARAMETER` | Parameter validation failed |
| `RECIPIENT-ERROR` | Invalid recipient specified |
| `SPENDER-ERROR` | Invalid spender specified |
| `ARITHMETIC-ERROR` | Math operation failed (e.g., overflow) |
| `CONTRACT-FROZEN` | Contract is currently frozen |
| `ALREADY-SETUP` | Contract already initialized |
| `NOT-SETUP` | Contract not yet initialized |
| `USER-BLOCKED` | User address is blocked |
| `SUPPLY-LIMIT-REACHED` | Maximum token supply reached |
| `APPROVAL-EXPIRED` | Approval has expired |

## Events

The contract emits structured events for all major operations:

- `transfer`: Token transfers between users
- `issue`: New token minting
- `burn`: Token burning
- `approval`: Spending approvals
- `setup`: Contract initialization
- `admin-change`: Administrative control transfers
- `contract-freeze`/`contract-unfreeze`: Contract status changes
- `address-blocked`/`address-unblocked`: Address restriction changes
- `tokens-vaulted`/`vault-released`: Vault operations

## Development and Integration

### Local Testing

1. Install [Clarinet](https://github.com/hirosystems/clarinet)
2. Clone the repository
3. Run tests: `clarinet test`

### Deployment

```bash
# Deploy to testnet
clarinet deploy --testnet

# Deploy to mainnet (after thorough testing)
clarinet deploy --mainnet
```

### Integration Example

```javascript
// JavaScript integration example using @stacks/transactions
import { 
  makeContractCall,
  broadcastTransaction,
  AnchorMode,
  FungibleConditionCode,
  createAssetInfo
} from '@stacks/transactions';

// Transfer tokens
async function transferTokens(recipient, amount) {
  const txOptions = {
    contractAddress: 'SP2CBFR35C1F114YJK2HG975RXVN6617RFGYZH93E',
    contractName: 'nebula-token',
    functionName: 'transfer',
    functionArgs: [
      uintCV(amount),
      standardPrincipalCV(recipient)
    ],
    senderKey: 'your_private_key',
    validateWithAbi: true,
    network: 'mainnet',
    anchorMode: AnchorMode.Any,
  };
  
  const transaction = await makeContractCall(txOptions);
  const broadcastResponse = await broadcastTransaction(transaction);
  return broadcastResponse;
}
```

## Security Considerations

Nebula Token incorporates multiple security best practices:

- Time-limited approvals to reduce exposure
- Comprehensive input validation
- Protection against common smart contract attacks
- Pausable functionality for emergency scenarios
- Admin controls with ownership transfer capability

## Roadmap

- [ ] Multi-signature administrative controls
- [ ] Automated vesting schedules
- [ ] Enhanced governance mechanisms
- [ ] Token snapshots for airdrops
- [ ] Staking and reward mechanisms
- [ ] Cross-chain compatibility


## Disclaimer

This token contract is provided as-is. Users and implementers should perform their own security audits before deployment to production environments.