import SwiftUI
import RealmSwift

struct BuisnessView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userVM = UserViewModel.shared
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""

    var avatarImage: Image {
        if let logoData = userVM.currentUser?.logo, let logoImage = UIImage(data: logoData) {
            return Image(uiImage: logoImage)
        } else {
            return Image("emptyAvatar")
        }
    }

    // Синхронизируем данные при открытии
    func loadUserFields() {
        name = userVM.currentUser?.name ?? ""
        email = userVM.currentUser?.email ?? ""
        phone = userVM.currentUser?.phone != nil ? String(userVM.currentUser!.phone!) : ""
        address = userVM.currentUser?.address ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom NavBar
            ZStack {
                Color(.systemGray6)
                    .frame(height: 56)
                    .cornerRadius(0)
                    .shadow(color: Color(.systemGray4).opacity(0.10), radius: 1, x: 0, y: 1)
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Text("Business")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                    Spacer()
                    Spacer().frame(width: 32)
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 56)

            Spacer().frame(height: 40)

            // Фото: квадратное со скругленными краями
            Button(action: {
                showImagePicker = true
            }) {
                avatarImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(.systemGray4), lineWidth: 2)
                    )
                    .shadow(color: Color(.systemGray4).opacity(0.18), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 24)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                guard let image = newImage,
                      let data = image.jpegData(compressionQuality: 0.9),
                      let currentUser = userVM.currentUser else { return }
                let realm = userVM.realm
                try? realm.write {
                    currentUser.logo = data
                }
                userVM.currentUser = currentUser
            }

            // Business Name
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Business Name")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.systemGray))
                    TextField("Business Name", text: $name, onCommit: {
                        if let currentUser = userVM.currentUser {
                            let realm = userVM.realm
                            try? realm.write {
                                currentUser.name = name
                            }
                            userVM.currentUser = currentUser
                        }
                    })
                    .font(.system(size: 17))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.systemGray))
                    TextField("Email", text: $email, onCommit: {
                        if let currentUser = userVM.currentUser {
                            let realm = userVM.realm
                            try? realm.write {
                                currentUser.email = email
                            }
                            userVM.currentUser = currentUser
                        }
                    })
                    .font(.system(size: 17))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Phone")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.systemGray))
                    TextField("Phone", text: $phone, onCommit: {
                        if let currentUser = userVM.currentUser {
                            let realm = userVM.realm
                            try? realm.write {
                                currentUser.phone = Int(phone)
                            }
                            userVM.currentUser = currentUser
                        }
                    })
                    .font(.system(size: 17))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Address")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.systemGray))
                    TextField("Address", text: $address, onCommit: {
                        if let currentUser = userVM.currentUser {
                            let realm = userVM.realm
                            try? realm.write {
                                currentUser.address = address
                            }
                            userVM.currentUser = currentUser
                        }
                    })
                    .font(.system(size: 17))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 32)
            .onAppear {
                loadUserFields()
            }

            Spacer()
        }
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}
