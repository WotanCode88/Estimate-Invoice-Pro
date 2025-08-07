import Combine
import RealmSwift
import StoreKit

struct SubscriptionProduct: Identifiable, Equatable {
    let id: String
    let title: String
    let assetName: String
    let price: String
}

extension SubscriptionProduct {
    static let annual = SubscriptionProduct(
        id: "com.yourapp.subscription.annual",
        title: "Annual Subscription",
        assetName: "annualAsset",
        price: "9.99$ / week"
    )
    static let monthly = SubscriptionProduct(
        id: "com.yourapp.subscription.monthly",
        title: "Monthly Subscription",
        assetName: "monthlyAsset",
        price: "99.99$ / year"
    )
    static let week = SubscriptionProduct(
        id: "com.yourapp.subscription.weektrial",
        title: "Week Subscription",
        assetName: "weekAsset",
        price: "5,99 / week"
    )
    static let all: [SubscriptionProduct] = [.annual, .monthly, .week]
}

class SubscriptionViewModel: ObservableObject {
    @Published var isSubscribed: Bool = false
    @Published var selectedProduct: SubscriptionProduct? = nil
    @Published var storeProducts: [Product] = []
    @Published var purchaseInProgress: Bool = false

    static let shared = SubscriptionViewModel()

    private var updateListenerTask: Task<Void, Never>? = nil
    private var cancellables = Set<AnyCancellable>()

    private let productIDs: [String] = SubscriptionProduct.all.map { $0.id }

    private init() {
        let realm = try? Realm()
        if let user = realm?.objects(UserModel.self).first {
            self.isSubscribed = user.isSubscribed
        }
        fetchProducts()
        listenForUpdates()
        self.isSubscribed = true
    }

    deinit {
        updateListenerTask?.cancel()
    }

    private func fetchProducts() {
        Task {
            do {
                let products = try await Product.products(for: productIDs)
                DispatchQueue.main.async {
                    self.storeProducts = products
                    Task {
                        await self.refreshSubscriptionStatus()
                    }
                }
            } catch {
                print("Failed to fetch products: \(error.localizedDescription)")
            }
        }
    }

    private func listenForUpdates() {
        updateListenerTask = Task.detached {
            for await result in Transaction.updates {
                await self.handle(transactionResult: result)
            }
        }
    }

    func purchase(product: SubscriptionProduct) {
        guard let storeProduct = storeProducts.first(where: { $0.id == product.id }) else { return }
        purchaseInProgress = true
        Task {
            do {
                let result = try await storeProduct.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        await transaction.finish()
                        await MainActor.run {
                            self.completeSubscriptionPurchase(for: product)
                        }
                    case .unverified(_, let error):
                        print("Purchase unverified: \(error.localizedDescription)")
                    }
                case .userCancelled:
                    print("User cancelled purchase")
                case .pending:
                    print("Purchase pending")
                @unknown default:
                    print("Unknown purchase result")
                }
            } catch {
                print("Failed purchase: \(error.localizedDescription)")
            }
            await MainActor.run {
                self.purchaseInProgress = false
            }
        }
    }

    func restore() {
        Task {
            do {
                try await AppStore.sync()
                await self.refreshSubscriptionStatus()
            } catch {
                print("Restore failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func handle(transactionResult: VerificationResult<Transaction>) async {
        switch transactionResult {
        case .verified(let transaction):
            if productIDs.contains(transaction.productID) {
                let product = SubscriptionProduct.all.first { $0.id == transaction.productID }
                completeSubscriptionPurchase(for: product)
            }
            await transaction.finish()
            await refreshSubscriptionStatus()
        case .unverified(_, let error):
            print("Unverified transaction: \(error.localizedDescription)")
        }
    }

    private func completeSubscriptionPurchase(for product: SubscriptionProduct?) {
        self.isSubscribed = true
        self.selectedProduct = product

        let realm = try? Realm()
        if let user = realm?.objects(UserModel.self).first {
            try? realm?.write {
                user.isSubscribed = true
            }
        }
    }

    func refreshSubscriptionStatus() async {
        var foundActive = false
        for product in storeProducts {
            if let statuses = try? await product.subscription?.status,
               let status = statuses.first,
               status.state == .subscribed {
                await MainActor.run {
                    self.completeSubscriptionPurchase(for: SubscriptionProduct.all.first { $0.id == product.id })
                }
                foundActive = true
                break
            }
        }
        if !foundActive {
            await MainActor.run {
                self.isSubscribed = false
                self.selectedProduct = nil
                let realm = try? Realm()
                if let user = realm?.objects(UserModel.self).first {
                    try? realm?.write {
                        user.isSubscribed = false
                    }
                }
            }
        }
    }
}
