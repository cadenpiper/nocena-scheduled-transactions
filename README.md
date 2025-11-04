# Nocena Challenge Scheduler - Cadence Smart Contracts

Cadence smart contracts for Nocena's decentralized challenge scheduling system using Flow blockchain's scheduled transactions as a replacement for traditional cron jobs.

## Purpose

This repository contains the smart contracts that power Nocena's automated challenge generation system. Instead of relying on centralized cron jobs, these contracts use Flow's scheduled transactions to emit challenge events at regular intervals, ensuring reliable, decentralized automation.

## Architecture

- **NocenaChallengeHandler**: Self-rescheduling contract that emits timed challenge events and manages scheduling
- **Event-Driven**: Blockchain events trigger challenge generation in the Nocena application
- **Decentralized**: No dependency on external infrastructure or cron jobs

## Features

- ✅ **Decentralized Automation**: No dependency on centralized infrastructure
- ✅ **Self-Rescheduling**: Automatically reschedules after each execution using Flow's scheduled transactions
- ✅ **Multiple Challenge Types**: Daily, weekly, and monthly challenge generation
- ✅ **Granular Control**: Start/stop individual challenge types or all challenges
- ✅ **Immediate Events**: Emits initial events when starting for instant frontend feedback
- ✅ **Cost Effective**: Minimal FLOW token cost per execution

## Challenge Types & Intervals

### Testing/Development
- **Daily**: 15 seconds
- **Weekly**: 30 seconds  
- **Monthly**: 45 seconds

### Production (Ready to Deploy)
- **Daily**: 86400 seconds (24 hours)
- **Weekly**: 604800 seconds (7 days)
- **Monthly**: 2592000 seconds (30 days)

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

1. **Deploy Contract**
   ```bash
   # Deploy to testnet
   flow project deploy --network testnet

   # Deploy to mainnet  
   flow project deploy --network mainnet
   ```

2. **Start All Challenges**
   ```bash
   flow transactions send cadence/transactions/StartChallenges.cdc \
     --network testnet --signer testnet-account
   ```

### Management

#### Stop Challenges
```bash
# Stop all challenges
flow transactions send cadence/transactions/StopChallenges.cdc \
  --network testnet --signer testnet-account \
  --args-json '[{"type":"String","value":"all"}]'

# Stop specific challenge type
flow transactions send cadence/transactions/StopChallenges.cdc \
  --network testnet --signer testnet-account \
  --args-json '[{"type":"String","value":"daily"}]'
```

#### Monitor Events
```bash
# Monitor daily challenges
flow events get A.{CONTRACT_ADDRESS}.NocenaChallengeHandler.TriggerDailyChallenge \
  --network testnet --last 10

# Monitor weekly challenges  
flow events get A.{CONTRACT_ADDRESS}.NocenaChallengeHandler.TriggerWeeklyChallenge \
  --network testnet --last 10

# Monitor monthly challenges
flow events get A.{CONTRACT_ADDRESS}.NocenaChallengeHandler.TriggerMonthlyChallenge \
  --network testnet --last 10
```

## Integration with Nocena

The Nocena application listens for these blockchain events:

- `A.{CONTRACT_ADDRESS}.NocenaChallengeHandler.TriggerDailyChallenge`
- `A.{CONTRACT_ADDRESS}.NocenaChallengeHandler.TriggerWeeklyChallenge`
- `A.{CONTRACT_ADDRESS}.NocenaChallengeHandler.TriggerMonthlyChallenge`

When these events are emitted, the application automatically generates new challenges for users.

## How It Works

1. **Initialization**: `StartChallenges.cdc` creates handler, enables all challenge types, and emits initial events
2. **Scheduling**: Three scheduled transactions are created (daily, weekly, monthly) with different start times
3. **Execution**: Each scheduled transaction executes, emits its challenge event, and reschedules itself
4. **Self-Rescheduling**: Handler automatically schedules the next execution using Flow's scheduled transactions
5. **Stop Control**: Challenge types can be individually disabled to prevent rescheduling

## Project Structure

```
├── cadence/
│   ├── contracts/
│   │   └── NocenaChallengeHandler.cdc       # Main challenge scheduling contract
│   └── transactions/
│       ├── StartChallenges.cdc              # Initialize and start all challenges
│       ├── StopChallenges.cdc               # Stop individual or all challenges
│       └── TimeTravel.cdc                   # Emulator testing utility
├── flow.json                                # Flow project configuration
└── README.md
```

## Development & Testing

### Emulator Testing
```bash
# Start emulator
flow emulator start

# Deploy to emulator
flow project deploy --network emulator

# Start challenges
flow transactions send cadence/transactions/StartChallenges.cdc \
  --network emulator --signer emulator-account

# Advance blocks for testing (emulator only)
flow transactions send cadence/transactions/TimeTravel.cdc \
  --network emulator --signer emulator-account \
  --args-json '[{"type":"UInt64","value":"20"}]'
```

### Key Features Tested
- ✅ **Self-rescheduling**: Challenges automatically continue at specified intervals
- ✅ **Stop mechanism**: Individual challenge types can be stopped and restarted
- ✅ **Initial events**: Immediate event emission when starting challenges
- ✅ **Multiple intervals**: Different timing for daily/weekly/monthly challenges

## Security

- Only contract deployer can start/stop challenges
- Scheduled transactions are immutable once created (cannot be cancelled)
- FlowToken fees required for each execution
- Handler capabilities are properly scoped and secured

## Resources

- [Flow Documentation](https://developers.flow.com/)
- [Scheduled Transactions Guide](https://developers.flow.com/build/advanced-concepts/scheduled-transactions)
- [Flow CLI Reference](https://developers.flow.com/tools/flow-cli)
