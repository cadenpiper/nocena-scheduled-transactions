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

        let monthlyFuture = getCurrentBlock().timestamp + 2592000.0
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
    }
}
