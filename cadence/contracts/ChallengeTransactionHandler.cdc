import "FlowTransactionScheduler"
import "ChallengeScheduler"
import "FlowToken"
import "FungibleToken"

access(all) contract ChallengeTransactionHandler {
    access(all) let HandlerStoragePath: StoragePath
    access(all) let HandlerPublicPath: PublicPath
    
    // Control flags stored in contract account
    access(all) var dailyEnabled: Bool
    access(all) var weeklyEnabled: Bool
    access(all) var monthlyEnabled: Bool
    
    init() {
        self.HandlerStoragePath = /storage/ChallengeTransactionHandler
        self.HandlerPublicPath = /public/ChallengeTransactionHandler
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
    
    access(all) resource Handler: FlowTransactionScheduler.TransactionHandler {
        access(FlowTransactionScheduler.Execute) fun executeTransaction(id: UInt64, data: AnyStruct?) {
            let challengeType = data as! String
            
            switch challengeType {
                case "daily":
                    if ChallengeTransactionHandler.dailyEnabled {
                        ChallengeScheduler.triggerDailyChallenge()
                        self.reschedule(challengeType: "daily", interval: 86400.0) // 24 hours
                    }
                case "weekly":
                    if ChallengeTransactionHandler.weeklyEnabled {
                        ChallengeScheduler.triggerWeeklyChallenge()
                        self.reschedule(challengeType: "weekly", interval: 604800.0) // 7 days
                    }
                case "monthly":
                    if ChallengeTransactionHandler.monthlyEnabled {
                        ChallengeScheduler.triggerMonthlyChallenge()
                        self.reschedule(challengeType: "monthly", interval: 2592000.0) // 30 days
                    }
            }
        }
        
        access(self) fun reschedule(challengeType: String, interval: UFix64) {
            let account = ChallengeTransactionHandler.account
            let vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
                ?? panic("Could not borrow FlowToken vault")
            
            let fees <- vaultRef.withdraw(amount: 1.0) as! @FlowToken.Vault
            
            let controllers = account.capabilities.storage.getControllers(forPath: ChallengeTransactionHandler.HandlerStoragePath)
            var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
            
            for controller in controllers {
                if let cap = controller.capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
                    handlerCap = cap
                    break
                }
            }
            
            let scheduled <- FlowTransactionScheduler.schedule(
                handlerCap: handlerCap!,
                data: challengeType,
                timestamp: getCurrentBlock().timestamp + interval,
                priority: FlowTransactionScheduler.Priority.Medium,
                executionEffort: 1000,
                fees: <-fees
            )
            
            destroy scheduled
        }
        
        access(all) view fun getViews(): [Type] {
            return [Type<StoragePath>(), Type<PublicPath>()]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<StoragePath>():
                    return ChallengeTransactionHandler.HandlerStoragePath
                case Type<PublicPath>():
                    return ChallengeTransactionHandler.HandlerPublicPath
                default:
                    return nil
            }
        }
    }
    
    access(all) fun createHandler(): @Handler {
        return <- create Handler()
    }
}
