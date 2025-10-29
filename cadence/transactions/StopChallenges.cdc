import "ChallengeTransactionHandler"

transaction(challengeType: String) {
    prepare(signer: auth(Storage) &Account) {
        switch challengeType {
            case "daily":
                ChallengeTransactionHandler.stopDaily()
            case "weekly":
                ChallengeTransactionHandler.stopWeekly()
            case "monthly":
                ChallengeTransactionHandler.stopMonthly()
            case "all":
                ChallengeTransactionHandler.stopAll()
            default:
                panic("Invalid challenge type. Use: daily, weekly, monthly, or all")
        }
        
        log("Stopped ".concat(challengeType).concat(" challenges"))
    }
}
