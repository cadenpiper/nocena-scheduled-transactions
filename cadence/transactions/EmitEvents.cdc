import "NocenaChallengeHandler"

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Enable all challenges
        NocenaChallengeHandler.startAll()
        
        // Emit immediate events for frontend testing
        NocenaChallengeHandler.emitInitialEvents()
        
        log("Emitted all challenge events immediately")
    }
}
