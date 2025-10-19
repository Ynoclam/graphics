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
    @StateObject private var viewModel = StockViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Цена закрытия")
                    .font(.headline)
                    .padding(.leading)
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.stocks.isEmpty {
                    Text("Нет данных для отображения")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Chart(viewModel.stocks) { item in
                        if let time = item.time {
                            LineMark(
                                x: .value("Время", time),
                                y: .value("Цена", item.price)
                            )
                            .foregroundStyle(.blue)
                           // .symbol(Circle())
                            .interpolationMethod(.cardinal)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .hour, count: 6))
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 300)
                    .padding()
                }
            }
            .navigationTitle("Swift Charts Example")
            .task {
                await viewModel.loadData()
            }
        }
    }
}


struct FinanceChartApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#Preview {
    ContentView()
}
