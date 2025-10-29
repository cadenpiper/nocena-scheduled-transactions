import "FlowTransactionScheduler"
import "ChallengeTransactionHandler"
import "ChallengeScheduler"
import "FlowToken"
import "FungibleToken"

transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get the entitled capability
        var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
        
        let controllers = signer.capabilities.storage.getControllers(forPath: ChallengeTransactionHandler.HandlerStoragePath)
        for controller in controllers {
            if let cap = controller.capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
                handlerCap = cap
                break
            }
        }
        
        if handlerCap == nil {
            panic("Challenge handler execute capability not found. Run InitChallengeHandler first.")
        }
        
        let currentTime = getCurrentBlock().timestamp
        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow FlowToken vault")
        
        // Generate initial challenges immediately
        ChallengeScheduler.triggerDailyChallenge()
        ChallengeScheduler.triggerWeeklyChallenge()
        ChallengeScheduler.triggerMonthlyChallenge()
        
        // Schedule daily challenge (24 hours)
        let dailyFees <- vaultRef.withdraw(amount: 1.0) as! @FlowToken.Vault
        let dailyScheduled <- FlowTransactionScheduler.schedule(
            handlerCap: handlerCap!,
            data: "daily",
            timestamp: currentTime + 86400.0,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000,
            fees: <-dailyFees
        )
        
        // Schedule weekly challenge (7 days)
        let weeklyFees <- vaultRef.withdraw(amount: 1.0) as! @FlowToken.Vault
        let weeklyScheduled <- FlowTransactionScheduler.schedule(
            handlerCap: handlerCap!,
            data: "weekly",
            timestamp: currentTime + 604800.0,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000,
            fees: <-weeklyFees
        )
        
        // Schedule monthly challenge (30 days)
        let monthlyFees <- vaultRef.withdraw(amount: 1.0) as! @FlowToken.Vault
        let monthlyScheduled <- FlowTransactionScheduler.schedule(
            handlerCap: handlerCap!,
            data: "monthly",
            timestamp: currentTime + 2592000.0,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000,
            fees: <-monthlyFees
        )
        
        log("Generated initial challenges and scheduled future ones:")
        log("Daily: ID ".concat(dailyScheduled.id.toString()).concat(" (24 hours)"))
        log("Weekly: ID ".concat(weeklyScheduled.id.toString()).concat(" (7 days)"))
        log("Monthly: ID ".concat(monthlyScheduled.id.toString()).concat(" (30 days)"))
        
        destroy dailyScheduled
        destroy weeklyScheduled
        destroy monthlyScheduled
    }
}
