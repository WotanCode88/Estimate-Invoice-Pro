import SwiftUI

struct PersonalAuthorizationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var businessName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var logoImage: UIImage?
    @State private var isImagePickerPresented = false
    @StateObject private var viewModel = PersonalAuthorizationViewModel()

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
                .onTapGesture { hideKeyboard() }
                .gesture(
                    DragGesture(minimumDistance: 16, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.height > 0 { hideKeyboard() }
                        }
                )
            VStack(spacing: 0) {
                // Custom NavBar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("Authorization")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 8)
                .padding(.top)
                .background(Color(.systemBackground))
                .zIndex(1)

                Spacer()
                VStack(spacing: 24) {
                    Text("Tell us about\nyour business")
                        .multilineTextAlignment(.center)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Business Name")
                            .font(.headline)
                            .foregroundColor(.gray)
                        TextField("Enter business name", text: $businessName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        Text("Your email")
                            .font(.headline)
                            .foregroundColor(.gray)
                        TextField("Optional", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        Text("Phone")
                            .font(.headline)
                            .foregroundColor(.gray)
                        TextField("Optional", text: $phone)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        Text("Address")
                            .font(.headline)
                            .foregroundColor(.gray)
                        TextField("Optional", text: $address)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        Text("Logo")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            if let logoImage = logoImage {
                                Image(uiImage: logoImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            } else {
                                VStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    Text("Upload logo")
                                        .foregroundColor(.blue)
                                }
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .sheet(isPresented: $isImagePickerPresented) {
                            ImagePicker(image: $logoImage)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                Spacer()
                Button(action: {
                    guard businessName.isEmpty == false else { return }
                    viewModel.setName(businessName)
                    viewModel.setEmail(email.isEmpty ? nil : email)
                    viewModel.setPhone(phone.isEmpty ? nil : phone)
                    viewModel.setAddress(address.isEmpty ? nil : address)
                    viewModel.setLogo(logoImage)
                    viewModel.saveToRealm()
                    dismiss()
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
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            let model = viewModel.userStruct
            businessName = model.name
            email = model.email ?? ""
            phone = model.phone.map { String($0) } ?? ""
            address = model.address ?? ""
            if let logoData = model.logo, let img = UIImage(data: logoData) {
                logoImage = img
            }
        }
        .onChange(of: logoImage) { newImage in
            viewModel.setLogo(newImage)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    PersonalAuthorizationView()
}
