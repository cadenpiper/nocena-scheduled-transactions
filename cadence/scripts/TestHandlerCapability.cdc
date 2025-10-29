import "ChallengeTransactionHandler"

access(all) fun main(address: Address): Bool {
    let account = getAccount(address)
    let cap = account.capabilities.get<&ChallengeTransactionHandler.Handler>(
        ChallengeTransactionHandler.HandlerPublicPath
    )
    
    return cap.check()
}
