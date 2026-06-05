import Foundation

enum HomeRouteContext: Equatable {
    case normal
    case missedWake
}

enum AppRoute: Equatable {
    case setup
    case setupEdit
    case home(HomeRouteContext)
    case bedtimePreparation
    case sleepComplete
    case wakeConfirmation
    case wakeComplete
    case reports
}
