import SwiftUI
import RealmSwift

struct PersonalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPresentingSubscription = false
    @State private var isPresentingAuthorizationFullScreen = false
    @StateObject private var subscriptionVM = SubscriptionViewModel.shared

    @ObservedObject private var userVM = UserViewModel.shared
    @State private var reloadID = UUID()

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 24)

                    if userVM.users.isEmpty {
                        Spacer()
                        Text("No users found")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(userVM.users, id: \.self) { user in
                                    Button(action: {
                                        userVM.setCurrentUser(user)
                                        reloadID = UUID()
                                    }) {
                                        HStack(spacing: 14) {
                                            // Аватар пользователя
                                            if let logoData = user.logo, let image = UIImage(data: logoData) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 44, height: 44)
                                                    .clipShape(Circle())
                                            } else {
                                                Image("emptyAvatar")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 44, height: 44)
                                                    .clipShape(Circle())
                                            }

                                            Text(user.name)
                                                .font(.system(size: 17))
                                                .foregroundColor(.black)
                                            
                                            Spacer()
                                            
                                            if let current = userVM.currentUser, current._id == user._id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(Color.black)
                                                    .font(.system(size: 22))
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .frame(width: 350, alignment: .leading)
                                        .background(Color.white)
                                        .cornerRadius(14)
                                        .shadow(color: Color(.systemGray4).opacity(0.12), radius: 2, x: 0, y: 1)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                        }
                    }
                    Spacer()

                    // Add User Button
                    Button(action: {
                        if !subscriptionVM.isSubscribed {
                            isPresentingSubscription = true
                        } else {
                            isPresentingAuthorizationFullScreen = true
                        }
                    }) {
                        HStack {
                            Text("Add User")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            if !subscriptionVM.isSubscribed {
                                Image("needPremiumWhite")
                                    .resizable()
                                    .frame(width: 67, height: 18)
                            }
                        }
                        .frame(width: 350, height: 56)
                        .background(Color.black)
                        .cornerRadius(14)
                        .shadow(color: Color(.systemGray4).opacity(0.12), radius: 2, x: 0, y: 1)
                    }
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                }
            }
            .id(reloadID) // Ключ для перерисовки всего ZStack
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Personal")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            .sheet(isPresented: $isPresentingSubscription) {
                SubscriptionView()
            }
            .fullScreenCover(
                isPresented: $isPresentingAuthorizationFullScreen,
                onDismiss: {
                    userVM.users = Array(try! Realm().objects(UserModel.self))
                }
            ) {
                PersonalAuthorizationView()
            }
        }
    }
}
