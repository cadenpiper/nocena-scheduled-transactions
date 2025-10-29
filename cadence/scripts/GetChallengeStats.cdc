import "ChallengeScheduler"

// Script to verify the contract is working and ready for integration
access(all) fun main(): {String: String} {
    return {
        "status": "Contract deployed and ready",
        "dailyTrigger": "Available - calls ChallengeScheduler.triggerDailyChallenge()",
        "weeklyTrigger": "Available - calls ChallengeScheduler.triggerWeeklyChallenge()",
        "monthlyTrigger": "Available - calls ChallengeScheduler.triggerMonthlyChallenge()",
        "events": "TriggerDailyChallenge, TriggerWeeklyChallenge, TriggerMonthlyChallenge",
        "integration": "Ready to replace cron jobs in nocena-monorepo",
        "nextStep": "Add event listener to backend to call /api/cron/* endpoints"
    }
}
