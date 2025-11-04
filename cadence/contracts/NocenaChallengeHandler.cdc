import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"
import "FlowToken"
import "FungibleToken"

access(all) contract NocenaChallengeHandler {

    // Control flags
    access(all) var dailyEnabled: Bool
    access(all) var weeklyEnabled: Bool
    access(all) var monthlyEnabled: Bool
    
    init() {
        self.dailyEnabled = true
        self.weeklyEnabled = true
        self.monthlyEnabled = true
    }
    
    access(all) fun stopDaily() { self.dailyEnabled = false }
    access(all) fun stopWeekly() { self.weeklyEnabled = false }
    access(all) fun stopMonthly() { self.monthlyEnabled = false }
    access(all) fun stopAll() { 
        self.dailyEnabled = false
        self.weeklyEnabled = false
        self.monthlyEnabled = false
    }

    access(all) fun startAll() { 
        self.dailyEnabled = true
        self.weeklyEnabled = true
        self.monthlyEnabled = true
    }

    access(all) fun emitInitialEvents() {
        emit TriggerDailyChallenge(timestamp: getCurrentBlock().timestamp)
        emit TriggerWeeklyChallenge(timestamp: getCurrentBlock().timestamp)
        emit TriggerMonthlyChallenge(timestamp: getCurrentBlock().timestamp)
    }

    // Events
    access(all) event TriggerDailyChallenge(timestamp: UFix64)
    access(all) event TriggerWeeklyChallenge(timestamp: UFix64)
    access(all) event TriggerMonthlyChallenge(timestamp: UFix64)

    access(all) resource Handler: FlowTransactionScheduler.TransactionHandler {
        access(FlowTransactionScheduler.Execute) fun executeTransaction(id: UInt64, data: AnyStruct?) {
            // Emit challenge event based on data
            if let challengeType = data as? String {
                switch challengeType {
                    case "daily":
                        if NocenaChallengeHandler.dailyEnabled {
                            emit TriggerDailyChallenge(timestamp: getCurrentBlock().timestamp)
                        }
                    case "weekly":
                        if NocenaChallengeHandler.weeklyEnabled {
                            emit TriggerWeeklyChallenge(timestamp: getCurrentBlock().timestamp)
                        }
                    case "monthly":
                        if NocenaChallengeHandler.monthlyEnabled {
                            emit TriggerMonthlyChallenge(timestamp: getCurrentBlock().timestamp)
                        }
                }
                log("Challenge executed (id: ".concat(id.toString()).concat(") type: ").concat(challengeType))
            }

            // Only reschedule if still enabled
            var shouldReschedule = false
            if let challengeType = data as? String {
                switch challengeType {
                    case "daily":
                        shouldReschedule = NocenaChallengeHandler.dailyEnabled
                    case "weekly":
                        shouldReschedule = NocenaChallengeHandler.weeklyEnabled
                    case "monthly":
                        shouldReschedule = NocenaChallengeHandler.monthlyEnabled
                }
            }

            if !shouldReschedule {
                log("Challenge type disabled, not rescheduling")
                return
            }

            // Schedule next execution with production intervals
            var delay: UFix64 = 5.0
            if let challengeType = data as? String {
                switch challengeType {
                    case "daily": 
                        delay = 86400.0    // 24 hours
                    case "weekly": 
                        delay = 604800.0   // 7 days  
                    case "monthly": 
                        delay = 2592000.0  // 30 days
                }
            }
            let future = getCurrentBlock().timestamp + delay
            let priority = FlowTransactionScheduler.Priority.Medium
            let executionEffort: UInt64 = 5000

            let estimate = FlowTransactionScheduler.estimate(
                data: data,
                timestamp: future,
                priority: priority,
                executionEffort: executionEffort
            )

            let vaultRef = NocenaChallengeHandler.account.storage
                .borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
                ?? panic("missing FlowToken vault")
            let fees <- vaultRef.withdraw(amount: estimate.flowFee ?? 0.0) as! @FlowToken.Vault

            let manager = NocenaChallengeHandler.account.storage
                .borrow<auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}>(from: FlowTransactionSchedulerUtils.managerStoragePath)
                ?? panic("Could not borrow Manager")

            let controllers = NocenaChallengeHandler.account.capabilities.storage.getControllers(forPath: /storage/NocenaChallengeHandler)
            var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
            
            for controller in controllers {
                if let cap = controller.capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
                    handlerCap = cap
                    break
                }
            }

            if handlerCap != nil {
                manager.schedule(
                    handlerCap: handlerCap!,
                    data: data,
                    timestamp: future,
                    priority: priority,
                    executionEffort: executionEffort,
                    fees: <-fees
                )
            } else {
                destroy fees
            }
        }

        access(all) view fun getViews(): [Type] {
            return [Type<StoragePath>(), Type<PublicPath>()]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<StoragePath>():
                    return /storage/NocenaChallengeHandler
                case Type<PublicPath>():
                    return /public/NocenaChallengeHandler
                default:
                    return nil
            }
        }
    }

    access(all) fun createHandler(): @Handler {
        return <- create Handler()
    }
}
