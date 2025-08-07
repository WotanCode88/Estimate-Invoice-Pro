import SwiftUI
import RealmSwift
import WebKit
import MessageUI

struct SettingsView: View {
    @StateObject private var subscriptionVM = SubscriptionViewModel.shared
    @State private var isPresentingSubscription = false
    @State private var isPresentingPersonal = false
    @State private var isPresentingBusiness = false
    @State private var isPresentingItems = false

    @State private var isPresentingPolicySheet = false
    @State private var isShowingMailAlert = false

    @ObservedObject private var userVM = UserViewModel.shared

    private var initials: String {
        guard let name = userVM.currentUser?.name else { return "" }
        let components = name.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let second = components.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(second)".uppercased()
    }
    
    private let policyURL = URL(string: "https://www.freeprivacypolicy.com/live/8fbdbf58-0ba7-4bd3-b422-f9cf8beabd45")!

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                Spacer().frame(height: 56)

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 72, height: 72)
                    if let logoData = userVM.currentUser?.logo, let logoImage = UIImage(data: logoData) {
                        Image(uiImage: logoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Text(initials)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .frame(height: 72)
                .frame(maxWidth: .infinity)

                if let name = userVM.currentUser?.name {
                    Text(name)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }

                if !subscriptionVM.isSubscribed {
                    Button(action: {
                        isPresentingSubscription = true
                    }) {
                        Image("freeTrailButton")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 350, height: 60)
                            .clipped()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 24)
                }

                VStack(spacing: 0) {
                    Button(action: {
                        isPresentingPersonal = true
                    }) {
                        HStack(spacing: 12) {
                            Image("personalAsset")
                                .resizable()
                                .frame(width: 22, height: 22)
                            Text("Personal Account")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(height: 46)
                        .padding(.horizontal, 20)
                    }
                    .fullScreenCover(isPresented: $isPresentingPersonal, onDismiss: {
                        userVM.currentUser = userVM.coreModel?.currentUser
                        userVM.users = Array(userVM.realm.objects(UserModel.self))
                    }) {
                        PersonalView()
                    }

                    Divider()
                        .background(Color(.systemGray4))

                    Button(action: {
                        isPresentingBusiness = true
                    }) {
                        HStack(spacing: 12) {
                            Image("buisnessAsset")
                                .resizable()
                                .frame(width: 22, height: 22)
                            Text("Business information")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(height: 46)
                        .padding(.horizontal, 20)
                    }
                    .fullScreenCover(isPresented: $isPresentingBusiness) {
                        BuisnessView()
                    }

                    Divider()
                        .background(Color(.systemGray4))

                    Button(action: {
                        isPresentingItems = true
                    }) {
                        HStack(spacing: 12) {
                            Image("itemAsset")
                                .resizable()
                                .frame(width: 22, height: 22)
                            Text("Items")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(height: 46)
                        .padding(.horizontal, 20)
                    }
                    .fullScreenCover(isPresented: $isPresentingItems) {
                        ItemSettingsView()
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                )
                .padding(.horizontal, 32)
                .padding(.top, 20)

                VStack(spacing: 0) {

                    Button(action: {
                        openMail()
                    }) {
                        HStack(spacing: 12) {
                            Image("contactAsset")
                                .resizable()
                                .frame(width: 22, height: 22)
                            Text("Contact Us")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(height: 46)
                        .padding(.horizontal, 20)
                    }
                    .alert(isPresented: $isShowingMailAlert) {
                        Alert(
                            title: Text("Mail not available"),
                            message: Text("Mail app is not configured on this device."),
                            dismissButton: .default(Text("OK"))
                        )
                    }

                    Divider()
                        .background(Color(.systemGray4))

                    Button(action: {
                        isPresentingPolicySheet = true
                    }) {
                        HStack(spacing: 12) {
                            Image("privacyAsset")
                                .resizable()
                                .frame(width: 22, height: 22)
                            Text("Privacy Policy")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(height: 46)
                        .padding(.horizontal, 20)
                    }

                    Divider()
                        .background(Color(.systemGray4))

                    Button(action: {
                        isPresentingPolicySheet = true
                    }) {
                        HStack(spacing: 12) {
                            Image("termsAsset")
                                .resizable()
                                .frame(width: 22, height: 22)
                            Text("Terms Of Use")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(height: 46)
                        .padding(.horizontal, 20)
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                )
                .padding(.horizontal, 32)
                .padding(.top, 20)

                Spacer()
            }
        }
        .sheet(isPresented: $isPresentingSubscription) {
            SubscriptionView()
        }
        .sheet(isPresented: $isPresentingPolicySheet) {
            PolicyWebView(url: policyURL)
        }
    }

    private func openMail() {
        let email = "xteam448@gmail.com"
        let subject = "Contact Us"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(email)?subject=\(encodedSubject)"
        if let url = URL(string: urlString) {
            #if os(iOS)
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                isShowingMailAlert = true
            }
            #endif
        } else {
            isShowingMailAlert = true
        }
    }
}

struct PolicyWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor)
        ])
        let request = URLRequest(url: url)
        webView.load(request)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
