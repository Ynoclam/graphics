//
//  ContentView.swift
//  graphycs
//
//  Created by Максим Кобрянов on 6.10.2025.
//
import SwiftUI
import Charts
import Combine

struct StockPoint: Identifiable, Decodable {
    let id = UUID()
    let date: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: date)
    }
}

@MainActor
class StockViewModel: ObservableObject {
    @Published var data: [StockPoint] = []
    @Published var isLoading = false
    
    func fetchData() async {
        isLoading = true
        
        let apiKey = "iDL9FuloaeiTy0c6eOQOg6h9YJNvumOq"
        let symbol = "AAPL"
        let urlString = "https://financialmodelingprep.com/api/v3/historical-chart/1hour/\(symbol)?apikey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([StockPoint].self, from: data)
            self.data = decoded.reversed()
        } catch {
            print("Ошибка загрузки данных: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}

struct ContentView: View {
    @StateObject private var viewModel = StockViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Загрузка данных...")
                        .padding()
                } else if viewModel.data.isEmpty {
                    Text("Нет данных")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    Chart(viewModel.data) { point in
                        if let date = point.dateValue {
                            LineMark(
                                x: .value("Время", date),
                                y: .value("Цена", point.close)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.cardinal)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .hour, count: 6))
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .padding()
                }
            }
            .navigationTitle("График акций")
            .task {
                await viewModel.fetchData()
            }
        }
    }
}

@main
struct FinanceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#Preview {
    ContentView()
}
