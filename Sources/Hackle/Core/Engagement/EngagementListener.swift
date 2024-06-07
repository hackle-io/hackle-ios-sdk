import Foundation

protocol EngagementListener {
    func onEngagement(engagement: Engagement, user: User, timestamp: Date)
}
