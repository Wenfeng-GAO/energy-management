import SwiftUI

struct AppSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(SpacingTokens.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(ColorTokens.warmWhite)
    }
}

extension View {
    func appSurface() -> some View {
        modifier(AppSurface())
    }
}
