import SwiftUI
#if os(macOS)
import AppKit
#endif

public struct SFSymbolCategoryFilterPicker: View {
    private let categories: [SFSymbolCategory]
    @Binding private var selection: SFSymbolCategoryFilter

    @State private var didScrollToSelection = false
    private var filters: [SFSymbolCategoryFilter] {
        [.all] + categories.map { .category($0) }
    }

    public init(
        categories: [SFSymbolCategory],
        selection: Binding<SFSymbolCategoryFilter>
    ) {
        self.categories = categories
        _selection = selection
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(filters) { filter in
                        Button {
                            selection = filter
                        } label: {
                            filter.image
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary.opacity(selection == filter ? 1 : 0.8))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        .id(filter)
                        .tint(.primary)
                        .frame(width: 35, height: 35)
                        .anchorPreference(
                            key: CategoryFilterItemBoundsKey.self,
                            value: .bounds
                        ) { [filter: $0] }
                    }
                }
                .backgroundPreferenceValue(CategoryFilterItemBoundsKey.self) { anchors in
                    GeometryReader { proxy in
                        if let anchor = anchors[selection] {
                            let rect = proxy[anchor]
                            SelectionIndicator()
                                .frame(width: 28, height: 28)
                                .position(x: rect.midX, y: rect.midY)
                                .animation(.snappy(duration: 0.18), value: selection)
                        }
                    }
                }
#if os(macOS)
                .modifier(CategoryFilterMouseDragSupport())
#endif
            }
            .onChange(of: selection, initial: true) { _, newSelection in
                if !didScrollToSelection {
                    didScrollToSelection = true
                    proxy.scrollTo(newSelection, anchor: .center)
                }
            }
        }
        .scrollIndicators(.never)
        .frame(height: 35)
        .coordinateSpace(name: "CategoryFilterPicker")
        .selectionSensoryFeedback(trigger: selection)
    }
}

#if os(macOS)
private struct CategoryFilterMouseDragSupport: ViewModifier {
    @State private var reference = ScrollViewReference()
    @GestureState private var dragStartOrigin: CGPoint?

    func body(content: Content) -> some View {
        content
            .background(ScrollViewReaderView(reference: reference))
            .contentShape(.rect)
            .highPriorityGesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .global)
                    .updating($dragStartOrigin) { value, origin, _ in
                        guard let scrollView = reference.scrollView,
                              let documentView = scrollView.documentView,
                              abs(value.translation.width) > abs(value.translation.height)
                        else {
                            return
                        }
                        let clipView = scrollView.contentView
                        let start = origin ?? clipView.bounds.origin
                        origin = start
                        let maxOffset = max(0, documentView.bounds.width - clipView.bounds.width)
                        let offset = start.x - value.translation.width
                        clipView.scroll(to: CGPoint(x: min(max(0, offset), maxOffset), y: start.y))
                        scrollView.reflectScrolledClipView(clipView)
                    }
            )
    }

    @MainActor
    final class ScrollViewReference {
        weak var scrollView: NSScrollView?
    }

    struct ScrollViewReaderView: NSViewRepresentable {
        let reference: ScrollViewReference

        func makeNSView(context: Context) -> ReaderView {
            let view = ReaderView()
            view.reference = reference
            return view
        }

        func updateNSView(_ nsView: ReaderView, context: Context) {}

        final class ReaderView: NSView {
            var reference: ScrollViewReference?

            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                reference?.scrollView = window == nil ? nil : enclosingScrollView
            }

            override func hitTest(_ point: NSPoint) -> NSView? {
                nil
            }
        }
    }
}
#endif

private extension SFSymbolCategoryFilterPicker {
    struct SelectionIndicator: View {
        @Environment(\.colorScheme) private var colorScheme
        private var selectionIndicatorColor: Color {
            switch colorScheme {
            case .dark:
                .white.opacity(0.15)
            case .light:
                // swiftlint:disable:next fallthrough
                fallthrough
            @unknown default:
                .black.opacity(0.1)
            }
        }

        var body: some View {
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(selectionIndicatorColor)
                .allowsHitTesting(false)
        }
    }
}

private nonisolated struct CategoryFilterItemBoundsKey: PreferenceKey {
    static let defaultValue: [SFSymbolCategoryFilter: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [SFSymbolCategoryFilter: Anchor<CGRect>],
        nextValue: () -> [SFSymbolCategoryFilter: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { $1 }
    }
}
