import SwiftUI

public struct ColorSymbolPickerView: View {
    @Binding var selectedColor: Color?
    @Binding var selectedSFSymbol: String?
    @Environment(\.displayScale) private var displayScale

    @State private var firstSelectedColor: Color?
    @State private var searchText = ""
    @State private var categoryFilter: SFSymbolCategoryFilter = .all
    @State private var symbols: SFSymbols?
    @State private var loadError: Error?
    @State private var categoryFilterHeight: CGFloat = 0

    private var showsCategoryFilter: Bool {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var colors: [Color] {
        let baseColors: [Color] = [.red, .orange, .yellow, .green, .mint, .teal,
                                   .cyan, .blue, .indigo, .purple, .pink, .brown, .gray]
        if let firstSelectedColor, !baseColors.contains(firstSelectedColor) {
            return [firstSelectedColor] + baseColors
        }
        return baseColors
    }

    public init(selectedColor: Binding<Color?>, selectedSFSymbol: Binding<String?>) {
        _selectedColor = selectedColor
        _selectedSFSymbol = selectedSFSymbol
    }

    public var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedColor != nil ? AnyShapeStyle(selectedColor!) : AnyShapeStyle(BackgroundStyle.background))
                .frame(width: 44, height: 44)
                .overlay {
                    if let selectedSFSymbol {
                        Image(systemName: selectedSFSymbol)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(10)
                    }
                }
                .padding(.bottom, 8)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 28))], spacing: 6) {
                ForEach(colors.indices, id: \.self) { index in
                    Button {
                        selectedColor = colors[index]
                    } label: {
                        Circle()
                            .fill(colors[index])
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if selectedColor == colors[index] {
                                    Image(systemName: "checkmark")
                                        .font(.body.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)

            ZStack {
                if let symbols {
                    SFSymbolPickerGrid(
                        selection: $selectedSFSymbol,
                        symbols: symbols.symbols,
                        categoryFilter: categoryFilter,
                        searchText: searchText,
                        selectedBackgroundColor: selectedColor,
                        configuration: .init(
                            preferredItemSize: CGSize(width: 38, height: 38),
                            itemSpacing: 6,
                            itemCornerRadius: 8
                        )
                    )
                    .contentMargins(.vertical, 1, for: .scrollContent)
                    .contentMargins(.horizontal, 1, for: .scrollContent)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let symbols {
                SFSymbolCategoryFilterPicker(
                    categories: symbols.categories.displayable,
                    selection: $categoryFilter
                )
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newValue in
                    categoryFilterHeight = newValue
                }
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.background)
                }
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator, lineWidth: 1 / displayScale))
                .transition(.opacity.animation(.linear(duration: 0.15)))
            }

            SearchField(searchText: $searchText)
        }
        .padding()
        .sfSymbolPickerRenderingMode(.hierarchical)
        .sfSymbolPickerForegroundStyle(.primary, .blue, .gray)
        .frame(width: 300, height: 486)
        .background {
            Rectangle()
                .fill(.background.secondary)
                .ignoresSafeArea()
        }
        .task {
            if firstSelectedColor == nil {
                firstSelectedColor = self.selectedColor
            }
            do {
                symbols = try await SFSymbols()
            } catch {
                loadError = error
            }
        }
    }
}

private struct SearchField: View {
    @Binding var searchText: String

    @Environment(\.displayScale) private var displayScale
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.placeholder)
            TextField("Search", text: $searchText, prompt: Text("Search"))
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    isFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .tint(.secondary)
            }
        }
        .focused($isFocused)
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.background)
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator, lineWidth: 1 / displayScale))
    }
}

@available(iOS 26, macOS 26, watchOS 26, *)
@available(visionOS, unavailable)
private struct GlassEffectBackgroundView: View {
    var body: some View {
        Color.clear
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct RegularBackgroundView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
#if os(watchOS)
            .fill(regularMaterial)
#else
            .fill(.bar)
#endif
            .shadow(color: .black.opacity(0.1), radius: 4)
    }
}

private struct SearchFieldBackgroundViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, visionOS 26, macOS 26, *) {
#if os(visionOS)
            content.background(Capsule().fill(.background.secondary))
#elseif os(macOS)
            content.glassEffect(.regular.tint(Color(nsColor: .controlBackgroundColor)), in: Capsule())
#elseif canImport(UIKit)
            content.glassEffect(.regular.tint(Color(uiColor: .secondarySystemBackground)), in: Capsule())
#else
            content.background(Capsule().fill(.background.secondary))
#endif
        } else {
            content.background(Capsule().fill(.background.secondary))
        }
    }
}

public extension View {
    func colorSymbolPicker(
        isPresented: Binding<Bool>,
        selectedColor: Binding<Color?>,
        selectedSymbol: Binding<String?>
    ) -> some View {
        modifier(
            ColorSymbolPickerViewModifier(
                isPresented: isPresented,
                selectedColor: selectedColor,
                selectedSymbol: selectedSymbol
            )
        )
    }
}

private struct ColorSymbolPickerViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    var selectedColor: Binding<Color?>
    var selectedSymbol: Binding<String?>

    func body(content: Content) -> some View {
        content.popover(isPresented: $isPresented, arrowEdge: .top) {
            ColorSymbolPickerView(selectedColor: selectedColor,
                                  selectedSFSymbol: selectedSymbol)
        }
    }
}

private struct ColorSymbolPickerViewDemo: View {
    @State private var selectedColor: Color? = Color(red: 0.35, green: 0.45, blue: 0.65)
    @State private var selectedSymbol: String?
    @State private var show = false

    var body: some View {
        Button {
            show = true
        } label: {
            Text("xxx")
        }
        .colorSymbolPicker(isPresented: $show, selectedColor: $selectedColor, selectedSymbol: $selectedSymbol)
    }
}

#Preview {
    ColorSymbolPickerViewDemo()
}
