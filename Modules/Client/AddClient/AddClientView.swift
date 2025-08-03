import SwiftUI

struct AddClientView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddClientViewModel()
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @FocusState private var focusedField: Field?

    @State private var showContactPicker = false

    enum Field {
        case name
        case email
        case phone
        case address
    }

    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Text("New Client")
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                    Button(action: {
                        guard name.isEmpty == false else { return }
                        do {
                            try viewModel.saveClient(name: name, email: email, phone: phone, address: address)
                            dismiss()
                        } catch {
                            print("Ошибка сохранения клиента: \(error)")
                        }
                    }) {
                        Text("Save")
                            .font(.body)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)
                .frame(height: 44)

                VStack(spacing: 0) {
                    Button(action: {
                        showContactPicker = true
                    }) {
                        HStack {
                            Image("contact")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Import from Contacts")
                                .font(.body)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 10)
                    .sheet(isPresented: $showContactPicker) {
                        ContactPicker { contact in
                            viewModel.fillFields(
                                with: contact,
                                name: &name,
                                email: &email,
                                phone: &phone,
                                address: &address
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Name")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 2)
                            TextField("Enter name", text: $name)
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3))
                                )
                                .focused($focusedField, equals: .name)
                        }

                        Group {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 2)
                            TextField("Optional", text: $email)
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                                .background(Color.white)
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3))
                                )
                                .focused($focusedField, equals: .email)
                        }

                        Group {
                            Text("Phone")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 2)
                            TextField("Optional", text: $phone)
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                                .background(Color.white)
                                .cornerRadius(12)
                                .keyboardType(.phonePad)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3))
                                )
                                .focused($focusedField, equals: .phone)
                        }

                        Group {
                            Text("Adress")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 2)
                            TextField("Optional", text: $address)
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3))
                                )
                                .focused($focusedField, equals: .address)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(24)
                .padding(.top, 0)

                Spacer()
            }
            .background(Color(UIColor.systemGray6).ignoresSafeArea())
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
            .padding(.bottom, (focusedField == .address) ? keyboardHeight + 70 : 70)            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            .animation(.easeOut(duration: 0.25), value: focusedField)

            if focusedField == .address && keyboardHeight > 0 {
                Color(UIColor.systemGray6)
                    .frame(height: keyboardHeight)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            }

            VStack {
                Button(action: {
                    guard name.isEmpty == false else { return }
                    do {
                        try viewModel.saveClient(name: name, email: email, phone: phone, address: address)
                        dismiss()
                    } catch {
                        print("Ошибка сохранения клиента: \(error)")
                    }
                }) {
                    Text("Add Client")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                        .padding(.bottom, (focusedField == .address) ? keyboardHeight : 24)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color.clear)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
                if let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = frame.height
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
        }
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

#Preview {
    AddClientView()
}
