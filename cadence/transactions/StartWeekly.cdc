import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"
import "FlowToken"
import "FungibleToken"
import "NocenaChallengeHandler"

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
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

        let weeklyFuture = getCurrentBlock().timestamp + 604800.0
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
    }
}
