import Foundation

enum HomeRouteContext: Equatable {
    case normal
    case missedWake
}

enum AppRoute: Equatable {
    case setup
    case home(HomeRouteContext)
    case bedtimePreparation
    case wakeConfirmation
}
