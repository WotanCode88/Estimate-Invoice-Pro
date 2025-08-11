import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @ObservedObject var viewModel = SubscriptionViewModel.shared

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Image("subView")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width * 0.8, alignment: .top)
                        .clipped()
                        .frame(maxWidth: .infinity, alignment: .top)

                    Button(action: {
                        viewModel.restore()
                    }) {
                        Text("Restore")
                            .font(.system(size: geometry.size.width * 0.042, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 18)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Capsule())
                            .shadow(radius: 1)
                    }
                    .padding(.top, geometry.size.width * 0.04)
                    .padding(.trailing, 12)
                }
                .frame(maxWidth: .infinity, alignment: .top)

                Spacer().frame(height: geometry.size.height * 0.04)

                VStack(spacing: 16) {
                    // Сначала все продукты, КРОМЕ weektrial
                    ForEach(viewModel.storeProducts.filter { $0.id != "com.yourapp.subscription.weektrial" }, id: \.id) { product in
                        let info = SubscriptionProduct.all.first(where: { $0.id == product.id })
                        Button(action: {
                            if let info = info {
                                viewModel.purchase(product: info)
                            }
                        }) {
                            HStack(alignment: .center, spacing: 14) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.displayName)
                                        .font(.system(size: geometry.size.width * 0.04, weight: .bold))
                                        .foregroundColor(.black)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }

                                Spacer(minLength: 12)
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(product.displayPrice)
                                        .font(.system(size: geometry.size.width * 0.05, weight: .bold))
                                        .foregroundColor(.black)
                                    if let info = info {
                                        Text(info.title)
                                            .font(.system(size: geometry.size.width * 0.032, weight: .medium))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                }
                            }
                            .padding(.vertical, geometry.size.height * 0.016)
                            .padding(.horizontal, geometry.size.width * 0.045)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                                    .background(Color.white.cornerRadius(16))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(minHeight: max(52, geometry.size.height * 0.09))
                    }

                    // Затем weektrial (если он есть)
                    if let weekTrialProduct = viewModel.storeProducts.first(where: { $0.id == "com.yourapp.subscription.weektrial" }) {
                        let info = SubscriptionProduct.all.first(where: { $0.id == weekTrialProduct.id })
                        VStack(spacing: 6) {
                            Button(action: {
                                if let info = info {
                                    viewModel.purchase(product: info)
                                }
                            }) {
                                HStack(alignment: .center, spacing: 14) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(weekTrialProduct.displayName)
                                            .font(.system(size: geometry.size.width * 0.04, weight: .bold))
                                            .foregroundColor(.black)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.8)
                                    }

                                    Spacer(minLength: 12)
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(weekTrialProduct.displayPrice)
                                            .font(.system(size: geometry.size.width * 0.05, weight: .bold))
                                            .foregroundColor(.black)
                                        if let info = info {
                                            Text(info.title)
                                                .font(.system(size: geometry.size.width * 0.032, weight: .medium))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                    }
                                }
                                .padding(.vertical, geometry.size.height * 0.016)
                                .padding(.horizontal, geometry.size.width * 0.045)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                                        .background(Color.white.cornerRadius(16))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(minHeight: max(52, geometry.size.height * 0.09))

                            Text("Trial for 3 days, then 5.99$ per week. Cancel at any time.")
                                .font(.system(size: geometry.size.width * 0.033, weight: .regular))
                                .foregroundColor(.blue)
                                .padding(.top, 2)
                        }
                    }
                }
                .padding(.horizontal, geometry.size.width * 0.06)
                .padding(.top, 8)

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color(.systemBackground))
        }
    }
}
