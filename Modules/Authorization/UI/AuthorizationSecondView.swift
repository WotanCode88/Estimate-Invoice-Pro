import SwiftUI
import PhotosUI

struct AuthorizationSecondView: View {
    @ObservedObject var viewModel: AuthorizationViewModel
    let coordinator: LaunchCoordinator

    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var logoImage: UIImage?
    @State private var isImagePickerPresented = false

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
                Spacer()
                VStack(spacing: 24) {
                    Text("Tell us about\nyour business")
                        .multilineTextAlignment(.center)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 16) {
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
                    viewModel.setEmail(email.isEmpty ? nil : email)
                    viewModel.setPhone(phone.isEmpty ? nil : phone)
                    viewModel.setAddress(address.isEmpty ? nil : address)
                    coordinator.finishAuthorization()
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
        .onChange(of: logoImage) { newImage in
            if let img = newImage {
                viewModel.setLogo(img)
            }
        }
        .onAppear {
            email = viewModel.user.email ?? ""
            phone = viewModel.user.phone.map { String($0) } ?? ""
            address = viewModel.user.address ?? ""
            if let logoData = viewModel.user.logo, let img = UIImage(data: logoData) {
                logoImage = img
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - ImagePicker Wrapper

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
