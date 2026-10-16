import SwiftUI
import SFSymbols

struct ContentView: View {
    private enum Example: Hashable {
        case modalPicker
        case embeddedPicker
    }

    @State private var selection: Example?
    @State private var selectedColor: Color? = Color(red: 0.35, green: 0.45, blue: 0.65)

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    NavigationLink("Modal Picker", value: Example.modalPicker)
                } footer: {
                    Text("Present a picker modally or in a popover from a simple row.")
                }
                Section {
                    NavigationLink("Embedded Picker", value: Example.embeddedPicker)
                } footer: {
                    Text("Embed the picker inside a form or detail screen to pick an icon inline.")
                }
            }
            .navigationTitle("Examples")
        } detail: {
            switch selection {
            case .modalPicker:
                ModalPickerDemoView()
            case .embeddedPicker:
                ColorSymbolPickerViewDemo()
            case nil:
                Text("Select an example.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
#if os(macOS)
            selection = .modalPicker
#endif
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
    ContentView()
}
