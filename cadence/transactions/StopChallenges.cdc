import "NocenaChallengeHandler"

transaction(challengeType: String) {
    prepare(signer: auth(Storage) &Account) {
        switch challengeType {
            case "daily":
                NocenaChallengeHandler.stopDaily()
            case "weekly":
                NocenaChallengeHandler.stopWeekly()
            case "monthly":
                NocenaChallengeHandler.stopMonthly()
            case "all":
                NocenaChallengeHandler.stopAll()
            default:
                panic("Invalid challenge type. Use: daily, weekly, monthly, or all")
        }
        
        log("Stopped ".concat(challengeType).concat(" challenges"))
    }
}
