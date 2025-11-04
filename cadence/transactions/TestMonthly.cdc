import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"
import "FlowToken"
import "FungibleToken"
import "NocenaChallengeHandler"

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Create handler if it doesn't exist
        if signer.storage.borrow<&NocenaChallengeHandler.Handler>(from: /storage/NocenaChallengeHandler) == nil {
            let handler <- NocenaChallengeHandler.createHandler()
            signer.storage.save(<-handler, to: /storage/NocenaChallengeHandler)
        }

        // Create capability if it doesn't exist
        if signer.capabilities.storage.getControllers(forPath: /storage/NocenaChallengeHandler).length == 0 {
            let handlerCap = signer.capabilities.storage.issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(/storage/NocenaChallengeHandler)
            signer.capabilities.publish(handlerCap, at: /public/NocenaChallengeHandler)
        }

        // Create manager if it doesn't exist
        if signer.storage.borrow<&{FlowTransactionSchedulerUtils.Manager}>(from: FlowTransactionSchedulerUtils.managerStoragePath) == nil {
            let manager <- FlowTransactionSchedulerUtils.createManager()
            signer.storage.save(<-manager, to: FlowTransactionSchedulerUtils.managerStoragePath)
        }

        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow FlowToken vault")

        let manager = signer.storage.borrow<auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}>(from: FlowTransactionSchedulerUtils.managerStoragePath)
            ?? panic("Could not borrow Manager")

        let controllers = signer.capabilities.storage.getControllers(forPath: /storage/NocenaChallengeHandler)
        var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
        
        for controller in controllers {
            if let cap = controller.capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
                handlerCap = cap
                break
            }
        }

        // Try just 1 day first
        let monthlyFuture = getCurrentBlock().timestamp + 86400.0 // 1 day
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

        log("Monthly challenge scheduled for 1 day")
    }
}
