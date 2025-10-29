access(all) contract ChallengeScheduler {
    
    // Events that your backend can listen for
    access(all) event TriggerDailyChallenge()
    access(all) event TriggerWeeklyChallenge()
    access(all) event TriggerMonthlyChallenge()
    
    // Simple functions to emit events
    access(all) fun triggerDailyChallenge() {
        emit TriggerDailyChallenge()
    }
    
    access(all) fun triggerWeeklyChallenge() {
        emit TriggerWeeklyChallenge()
    }
    
    access(all) fun triggerMonthlyChallenge() {
        emit TriggerMonthlyChallenge()
    }
}
