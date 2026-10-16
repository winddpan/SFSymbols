import SwiftUI

struct SFSymbolTile: View {
    let scale: CGFloat
    let systemName: String
    let isSelected: Bool
    let selectedBackgroundColor: Color?
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.symbolBackgroundSetting) private var symbolBackgroundSetting
    @Environment(\.symbolPickerVariableValue) private var variableValue
    @Environment(\.symbolPickerVariableValueModeSetting) private var variableValueModeSetting
    private var preferredColorScheme: ColorScheme {
        switch symbolBackgroundSetting {
        case .default:
            colorScheme
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    var body: some View {
        BackgroundView(cornerRadius: cornerRadius)
            .overlay {
                if isSelected, let selectedBackgroundColor {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(selectedBackgroundColor)
                }
            }
            .overlay {
                GeometryReader { geometry in
                    Image(systemName: systemName, variableValue: variableValue)
                        .resizable()
                        .scaledToFit()
                        .modifier(SFSymbolStyleViewModifier())
                        .symbolVariableValueModeSetting(variableValueModeSetting)
                        .padding(geometry.size.width * 0.22)
                }
            }
            .colorScheme(preferredColorScheme)
    }
}

private extension SFSymbolTile {
    struct BackgroundView: View {
        let cornerRadius: CGFloat

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.background)
            }
        }
    }
}
