import "NocenaChallengeHandler"
import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"
import "FlowToken"
import "FungibleToken"

transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Create handler and manager if they don't exist
        if signer.storage.borrow<&NocenaChallengeHandler.Handler>(from: /storage/NocenaChallengeHandler) == nil {
            let handler <- NocenaChallengeHandler.createHandler()
            signer.storage.save(<-handler, to: /storage/NocenaChallengeHandler)
            
            let cap = signer.capabilities.storage.issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(/storage/NocenaChallengeHandler)
        }
        
        if !signer.storage.check<@{FlowTransactionSchedulerUtils.Manager}>(from: FlowTransactionSchedulerUtils.managerStoragePath) {
            let manager <- FlowTransactionSchedulerUtils.createManager()
            signer.storage.save(<-manager, to: FlowTransactionSchedulerUtils.managerStoragePath)
        }

        let manager = signer.storage.borrow<auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}>(from: FlowTransactionSchedulerUtils.managerStoragePath)!
        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)!

        let controllers = signer.capabilities.storage.getControllers(forPath: /storage/NocenaChallengeHandler)
        var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
        
        for controller in controllers {
            if let cap = controller.capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
                handlerCap = cap
                break
            }
        }

        // Schedule daily challenge
        let dailyFuture = getCurrentBlock().timestamp + 2.0
        let dailyEstimate = FlowTransactionScheduler.estimate(
            data: "daily",
            timestamp: dailyFuture,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000
        )
        let dailyFees <- vaultRef.withdraw(amount: dailyEstimate.flowFee ?? 0.0) as! @FlowToken.Vault
        
        manager.schedule(
            handlerCap: handlerCap!,
            data: "daily",
            timestamp: dailyFuture,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000,
            fees: <-dailyFees
        )

        // Schedule weekly challenge
        let weeklyFuture = getCurrentBlock().timestamp + 4.0
        let weeklyEstimate = FlowTransactionScheduler.estimate(
            data: "weekly",
            timestamp: weeklyFuture,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000
        )
        let weeklyFees <- vaultRef.withdraw(amount: weeklyEstimate.flowFee ?? 0.0) as! @FlowToken.Vault
        
        manager.schedule(
            handlerCap: handlerCap!,
            data: "weekly",
            timestamp: weeklyFuture,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000,
            fees: <-weeklyFees
        )

        // Schedule monthly challenge
        let monthlyFuture = getCurrentBlock().timestamp + 6.0
        let monthlyEstimate = FlowTransactionScheduler.estimate(
            data: "monthly",
            timestamp: monthlyFuture,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000
        )
        let monthlyFees <- vaultRef.withdraw(amount: monthlyEstimate.flowFee ?? 0.0) as! @FlowToken.Vault
        
        manager.schedule(
            handlerCap: handlerCap!,
            data: "monthly",
            timestamp: monthlyFuture,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000,
            fees: <-monthlyFees
        )

        log("Started all challenges - daily, weekly, monthly will self-reschedule")
        
        // Enable all challenges first
        NocenaChallengeHandler.startAll()
        
        // Emit initial events immediately
        NocenaChallengeHandler.emitInitialEvents()
    }
}
