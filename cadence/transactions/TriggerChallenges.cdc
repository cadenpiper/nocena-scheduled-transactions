import "ChallengeScheduler"

transaction {
    prepare(signer: auth(Storage) &Account) {
        // Trigger all challenge types (daily, weekly, monthly)
        ChallengeScheduler.triggerDailyChallenge()
        log("Daily challenge triggered")
        
        ChallengeScheduler.triggerWeeklyChallenge()
        log("Weekly challenge triggered")
        
        ChallengeScheduler.triggerMonthlyChallenge()
        log("Monthly challenge triggered")
    }
}
