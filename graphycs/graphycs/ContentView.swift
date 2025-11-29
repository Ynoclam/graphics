//
//  ContentView.swift
//  graphycs
//
//  Created by Максим Кобрянов on 6.10.2025.
//
import SwiftUI
import Charts
import Combine

struct StockData: Identifiable, Decodable {
    let id = UUID()
    let price: Double
    let symbol:String
    let date: String
    let volume: Double
    
    var time: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}

@MainActor
final class StockViewModel: ObservableObject {
    @Published var stocks: [StockData] = []
    @Published var isLoading = false
    
    func loadData() async {
        isLoading = true
        
        let apiKey = "iDL9FuloaeiTy0c6eOQOg6h9YJNvumOq"
        let symbol = "AAPL"
        let urlString = "https://financialmodelingprep.com/stable/historical-price-eod/light?symbol=\(symbol)&apikey=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return
          }
        
        do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                decoder.dateDecodingStrategy = .formatted(formatter)

                let decoded = try decoder.decode([StockData].self, from: data)
                self.stocks = decoded.reversed()
            } catch {
                print("Ошибка загрузки данных: \(error)")
            }
        
        isLoading = false
    }
}

struct ContentView: View {
    @Binding var selectionDate: Date?
    @StateObject private var viewModel = StockViewModel()
    private let minDate = Calendar.current.date(
        from: DateComponents(year: 2020, month: 1, day: 1))!
    @State private var startDate = Calendar.current.date(
        from: DateComponents(year: 2025, month: 1, day: 1))!
    @State private var endDate = Date()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {

                Text("Цена закрытия")
                    .font(.headline)
                    .padding(.leading)

                HStack {
                    DatePicker(
                        "С",selection: $startDate,
                        in: minDate...endDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        "по",selection: $endDate,
                        in: startDate...Date(),
                        displayedComponents: .date
                    )
                }
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if viewModel.stocks.isEmpty {
                    Text("Нет данных для отображения")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                        Chart {
                            ForEach(filtered, id: \.0) { date, close in
                                LineMark(
                                    x: .value("Дата", date),
                                    y: .value("Цена", close)
                                )
                                .interpolationMethod(.catmullRom)
                                .lineStyle(.init(lineWidth: 3))

                                AreaMark(
                                    x: .value("Дата", date),
                                    y: .value("Цена", close)
                                )
                                .interpolationMethod(.catmullRom)
                                .opacity(0.2)
                            }
                        }
                        .chartScrollableAxes(.horizontal)
                        .chartXVisibleDomain(length: 3600*24*7)
                        .chartXSelection(value: $selectionDate)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.day(.defaultDigits))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(width: 1200, height: 600)
                        .padding()
                       
                }
            }
            .navigationTitle("Swift Charts Example")
            .task {
                await viewModel.loadData()
            }
        }
    }
   

    var filtered: [(Date, Double)] {
        viewModel.stocks.compactMap { item in
            guard let date = item.time else { return nil }
            if date >= startDate && date <= endDate {
                return (date, item.price)
            }
            return nil
        }
    }
}


struct FinanceChartApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(selectionDate: .constant(Date()))
        }
    }
}

#Preview {
    ContentView(selectionDate: .constant(Date()))
}
