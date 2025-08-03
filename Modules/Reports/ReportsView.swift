import SwiftUI
import RealmSwift

struct ReportsView: View {
    private var invoiceYears: [Int] {
        guard let realm = try? Realm() else { return [] }
        let invoices = realm.objects(InvoiceModel.self)
        let years = invoices.compactMap {
            Calendar.current.dateComponents([.year], from: $0.Issued).year
        }
        return Array(Set(years)).sorted(by: >)
    }
    
    private var currentYear: Int? {
        invoiceYears.first
    }
    
    private var formattedYear: String? {
        if let year = currentYear {
            let formatter = NumberFormatter()
            formatter.numberStyle = .none
            formatter.groupingSeparator = ""
            return formatter.string(from: NSNumber(value: year))
        }
        return nil
    }
    
    private var totalPaid: Double {
        guard let realm = try? Realm() else { return 0 }
        let paidInvoices = realm.objects(InvoiceModel.self).filter("wasPaid == true")
        return paidInvoices.reduce(0.0) { $0 + ($1.total) }
    }
    
    private var paidCurrency: String {
        guard let realm = try? Realm() else { return "" }
        let paidInvoices = realm.objects(InvoiceModel.self).filter("wasPaid == true")
        return paidInvoices.first?.currency ?? ""
    }
    
    // Квартальная разбивка с месяцами внутри
    private var quartersTotals: [(quarterLabel: String, quarterSum: Double, months: [(label: String, value: Double)])] {
        guard let realm = try? Realm() else { return [] }
        let paidInvoices = realm.objects(InvoiceModel.self).filter("wasPaid == true")
        // Группировка по кварталам и месяцам
        var quarterDict: [QuarterKey: [InvoiceModel]] = [:]
        for invoice in paidInvoices {
            let comps = Calendar.current.dateComponents([.year, .month], from: invoice.Issued)
            let year = comps.year ?? 0
            let month = comps.month ?? 0
            let quarter = ((month - 1) / 3 + 1)
            let key = QuarterKey(year: year, quarter: quarter)
            quarterDict[key, default: []].append(invoice)
        }
        // Сортированные квартальные ключи
        let sortedQuarterKeys = quarterDict.keys.sorted(by: >)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        // Собираем массив по кварталам с массивом месяцев внутри
        return sortedQuarterKeys.map { quarterKey in
            let invoicesInQuarter = quarterDict[quarterKey] ?? []
            let quarterSum = invoicesInQuarter.reduce(0.0) { $0 + ($1.total) }
            // Группировка по месяцам внутри квартала
            let monthDict = Dictionary(grouping: invoicesInQuarter) { invoice in
                let comps = Calendar.current.dateComponents([.year, .month], from: invoice.Issued)
                return YearMonth(year: comps.year ?? 0, month: comps.month ?? 0)
            }
            // Сортировка месяцев внутри квартала
            let sortedMonthKeys = monthDict.keys.sorted()
            let months: [(label: String, value: Double)] = sortedMonthKeys.map { monthKey in
                let invoices = monthDict[monthKey] ?? []
                let first = invoices.first?.Issued ?? Date()
                let label = dateFormatter.string(from: first)
                let value = invoices.reduce(0.0) { $0 + ($1.total) }
                return (label: label, value: value)
            }
            let quarterLabel = "Q\(quarterKey.quarter) \(quarterKey.year)"
            return (quarterLabel: quarterLabel, quarterSum: quarterSum, months: months)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Income")
                    .font(.system(size: 28, weight: .bold)) // уменьшено
                    .foregroundColor(.black)
                    .padding(.top, 40)
                
                Group {
                    if let yearString = formattedYear {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 18, weight: .medium)) // уменьшено
                                .foregroundColor(Color(.systemGray))
                            Text(yearString)
                                .font(.system(size: 14, weight: .regular)) // уменьшено
                                .foregroundColor(.black)
                        }
                        .frame(height: 36)
                        .frame(maxWidth: 100)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color(.systemGray4).opacity(0.12), radius: 2, x: 0, y: 1)
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 18, weight: .medium)) // уменьшено
                                .foregroundColor(Color(.black))
                            Text("No invoices")
                                .font(.system(size: 14, weight: .regular)) // уменьшено
                                .foregroundColor(.gray)
                        }
                        .frame(height: 36)
                        .frame(maxWidth: 120)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color(.systemGray4).opacity(0.12), radius: 2, x: 0, y: 1)
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 0)
                
                HStack {
                    Text("TOTAL")
                        .font(.system(size: 18, weight: .medium)) // medium (исключение)
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(String(format: "%.2f", totalPaid)) \(paidCurrency)")
                        .font(.system(size: 18, weight: .medium)) // medium (исключение)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                )
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .padding(.top, 8)
                
                // Квартальная разбивка с месячной детализацией внутри одного прямоугольника и разделителями
                ForEach(quartersTotals, id: \.quarterLabel) { quarter in
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(quarter.quarterLabel)
                                .font(.system(size: 16, weight: .regular)) // уменьшено
                                .foregroundColor(.black)
                            Spacer()
                            Text("\(String(format: "%.2f", quarter.quarterSum)) \(paidCurrency)")
                                .font(.system(size: 16, weight: .regular)) // уменьшено
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        
                        Divider()
                            .padding(.horizontal, 12)
                        
                        VStack(spacing: 0) {
                            ForEach(quarter.months.indices, id: \.self) { idx in
                                let month = quarter.months[idx]
                                HStack {
                                    Text(month.label)
                                        .font(.system(size: 15, weight: .regular)) // уменьшено
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text("\(String(format: "%.2f", month.value)) \(paidCurrency)")
                                        .font(.system(size: 15, weight: .regular)) // уменьшено
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                if idx < quarter.months.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 12)
                                }
                            }
                        }
                    }
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                Spacer()
            }
        }
    }
}

struct QuarterKey: Hashable, Comparable {
    let year: Int
    let quarter: Int

    static func < (lhs: QuarterKey, rhs: QuarterKey) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        return lhs.quarter < rhs.quarter
    }
}

struct YearMonth: Hashable, Comparable {
    let year: Int
    let month: Int

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        return lhs.month < rhs.month
    }
}
