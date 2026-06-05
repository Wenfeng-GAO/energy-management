import SwiftUI

struct AppSurface: ViewModifier {
    var background: Color = ColorTokens.warmWhite

    func body(content: Content) -> some View {
        ZStack(alignment: .topLeading) {
            background.ignoresSafeArea()
            content
                .padding(.horizontal, 22)
                .padding(.top, 28)
                .padding(.bottom, 58)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension View {
    func appSurface(background: Color = ColorTokens.warmWhite) -> some View {
        modifier(AppSurface(background: background))
    }
}
