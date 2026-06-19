import SwiftUI

struct ExplorerCopyButton: View {

    private let isEnabled: Bool
    private let action: () -> Void

    @State private var isCopied = false
    @State private var resetTask: Task<Void, Never>?

    init(isEnabled: Bool = true, action: @escaping () -> Void) {
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: copy) {
            ZStack {
                Image(systemName: "doc.on.doc")
                    .opacity(isCopied ? 0 : 1)
                    .scaleEffect(isCopied ? 0.82 : 1)
                    .foregroundColor(isEnabled ? .blue : Color.explorerSecondaryText)

                Image(systemName: "checkmark")
                    .opacity(isCopied ? 1 : 0)
                    .scaleEffect(isCopied ? 1 : 0.82)
                    .foregroundColor(.green)
            }
            .font(.system(size: 14, weight: .medium))
            .frame(width: 14, height: 14)
            .fixedSize()
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.18), value: isCopied)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .onDisappear {
            resetTask?.cancel()
        }
    }

    private func copy() {
        guard isEnabled else {
            return
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            isCopied = true
        }
        action()

        resetTask?.cancel()
        resetTask = Task {
            do {
                try await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isCopied = false
                    }
                }
            } catch {
                // cancelled
            }
        }
    }
}

#Preview {
    ExplorerCopyButton(isEnabled: true) {
        
    }
}
