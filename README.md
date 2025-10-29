# Nocena Challenge Scheduler - Cadence Smart Contracts

Cadence smart contracts for Nocena's decentralized challenge scheduling system using Flow blockchain's scheduled transactions as a replacement for traditional cron jobs.

## Purpose

This repository contains the smart contracts that power Nocena's automated challenge generation system. Instead of relying on centralized cron jobs, these contracts use Flow's scheduled transactions to emit challenge events at regular intervals, ensuring reliable, decentralized automation.

## Architecture

- **ChallengeScheduler**: Core contract that emits timed challenge events
- **ChallengeTransactionHandler**: Manages scheduled execution and automatic rescheduling
- **Event-Driven**: Blockchain events trigger challenge generation in the Nocena application

## Features

- ✅ **Decentralized Automation**: No dependency on centralized infrastructure
- ✅ **Continuous Scheduling**: Automatically reschedules after each execution
- ✅ **Multiple Intervals**: Daily, weekly, and monthly challenge generation
- ✅ **Granular Control**: Stop individual or all scheduled challenges
- ✅ **Cost Effective**: ~1 FLOW token per execution

## Setup Guide

### Prerequisites

1. Install Flow CLI: https://developers.flow.com/tools/flow-cli/install
2. Create Flow account (see Account Creation section below)
3. Fund account with FLOW tokens

### Account Creation

#### For Testnet:
```bash
# Generate new key pair
flow keys generate

# Create account on testnet using the generated public key
flow accounts create --key YOUR_PUBLIC_KEY --network testnet

# Add account to flow.json (replace with your actual address and private key)
flow config add-account testnet-account --address YOUR_ADDRESS --key YOUR_PRIVATE_KEY --network testnet
```

### Deployment

1. **Configure flow.json**
   ```bash
   # Update the account address in flow.json with your account details
   ```

2. **Deploy Contracts**
   ```bash
   # Deploy to testnet
   flow project deploy --network testnet

   # Deploy to mainnet  
   flow project deploy --network mainnet
   ```

3. **Initialize Handler**
   ```bash
   flow transactions send cadence/transactions/InitChallengeHandler.cdc \
     --network testnet --signer your-account
   ```

4. **Schedule Challenges**
   ```bash
   # Production intervals (24h, 7d, 30d)
   flow transactions send cadence/transactions/ScheduleChallenges.cdc \
     --network testnet --signer your-account \
     --args-json '[
       {"type":"UFix64","value":"86400.0"},
       {"type":"UFix64","value":"604800.0"},
       {"type":"UFix64","value":"2592000.0"}
     ]'
   ```

### Management

#### Stop Scheduling
```bash
# Stop all challenges
flow transactions send cadence/transactions/StopChallenges.cdc \
  --network testnet --signer your-account \
  --args-json '[{"type":"String","value":"all"}]'

# Stop specific challenge type
flow transactions send cadence/transactions/StopChallenges.cdc \
  --network testnet --signer your-account \
  --args-json '[{"type":"String","value":"daily"}]'
```

#### Monitor Events
```bash
flow events get A.{CONTRACT_ADDRESS}.ChallengeScheduler.TriggerDailyChallenge \
  --network testnet --last 10
```

## Integration with Nocena

The Nocena application listens for these blockchain events:

- `A.{CONTRACT_ADDRESS}.ChallengeScheduler.TriggerDailyChallenge`
- `A.{CONTRACT_ADDRESS}.ChallengeScheduler.TriggerWeeklyChallenge`
- `A.{CONTRACT_ADDRESS}.ChallengeScheduler.TriggerMonthlyChallenge`

When these events are emitted, the application automatically generates new challenges for users.

## Configuration

### Scheduling Intervals

**Production:**
- Daily: 86400 seconds (24 hours)
- Weekly: 604800 seconds (7 days)  
- Monthly: 2592000 seconds (30 days)

**Testing:**
- Daily: 5 seconds
- Weekly: 10 seconds
- Monthly: 15 seconds

## Project Structure

```
├── cadence/
│   ├── contracts/
│   │   ├── ChallengeScheduler.cdc          # Core scheduling contract
│   │   └── ChallengeTransactionHandler.cdc # Execution handler
│   ├── scripts/
│   │   ├── CheckScheduler.cdc              # Query scheduler status
│   │   ├── GetChallengeStats.cdc           # Get execution statistics
│   │   └── TestHandlerCapability.cdc       # Test handler setup
│   └── transactions/
│       ├── InitChallengeHandler.cdc        # Initialize handler
│       ├── ScheduleChallenges.cdc          # Start scheduling
│       └── StopChallenges.cdc              # Stop scheduling
├── flow.json                               # Flow project configuration
└── README.md
```

## Security

- Only contract owner can stop scheduling
- Scheduled transactions are immutable once created
- FlowToken fees required for each execution
- Handler capabilities are properly scoped and secured

## Resources

- [Flow Documentation](https://developers.flow.com/)
- [Scheduled Transactions Guide](https://developers.flow.com/build/advanced-concepts/scheduled-transactions)
- [Flow CLI Reference](https://developers.flow.com/tools/flow-cli)
