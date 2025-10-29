import "ChallengeTransactionHandler"
import "FlowTransactionScheduler"

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Save handler if not already present
        if signer.storage.borrow<&AnyResource>(from: ChallengeTransactionHandler.HandlerStoragePath) == nil {
            let handler <- ChallengeTransactionHandler.createHandler()
            signer.storage.save(<-handler, to: ChallengeTransactionHandler.HandlerStoragePath)
        }
        
        // Create authorized capability for scheduler
        let _ = signer.capabilities.storage.issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(ChallengeTransactionHandler.HandlerStoragePath)
        
        // Create public capability
        let publicCap = signer.capabilities.storage.issue<&ChallengeTransactionHandler.Handler>(ChallengeTransactionHandler.HandlerStoragePath)
        signer.capabilities.publish(publicCap, at: ChallengeTransactionHandler.HandlerPublicPath)
        
        log("Challenge handler initialized")
    }
}
