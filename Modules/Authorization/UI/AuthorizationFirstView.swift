import SwiftUI

struct AuthorizationFirstView: View {
    @State private var businessName: String = ""
    @ObservedObject var viewModel: AuthorizationViewModel
    let coordinator: LaunchCoordinator
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    Text("Enter your business name")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 8)
                    
                    Text("You can change it later in Settings")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                TextField("Your business name", text: $businessName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                
                Button(action: {
                    guard businessName.isEmpty == false else { return }
                    viewModel.setName(businessName)
                    coordinator.showAutorizationSecondView()
                }) {
                    Text("Continue")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                if keyboardHeight == 0 {
                    Spacer()
                }
            }
            .offset(y: keyboardHeight == 0 ? 0 : -keyboardHeight/4)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        }
        .onAppear { self.startKeyboardObserving() }
        .onDisappear { self.stopKeyboardObserving() }
    }

    // MARK: - Keyboard Handling

    private func startKeyboardObserving() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation {
                    self.keyboardHeight = frame.height
                }
            }
        }
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation {
                self.keyboardHeight = 0
            }
        }
    }

    private func stopKeyboardObserving() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}
