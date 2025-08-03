import Foundation
import Alamofire
import Combine

struct Currency: Identifiable {
    let code: String
    let name: String
    var id: String { code }
}

class CurrencyViewModel: ObservableObject {
    @Published var currencies: [Currency] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    func fetchCurrencies() {
        isLoading = true
        error = nil
        let url = "https://api.frankfurter.app/currencies"
        AF.request(url).responseData { response in
            DispatchQueue.main.async {
                self.isLoading = false
                switch response.result {
                case .success(let data):
                    if let dict = try? JSONDecoder().decode([String: String].self, from: data) {
                        self.currencies = dict.map { Currency(code: $0.key, name: $0.value) }
                            .sorted { $0.code < $1.code }
                    } else {
                        self.error = "Error decoding currencies"
                    }
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
