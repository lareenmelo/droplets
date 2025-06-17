//
//  ContentView.swift
//  droplets
//
//  Created by Lareen Melo on 6/14/25.
//

import SwiftUI

struct ContentView: View {
    private let apiKey = "getYourOwn"

    @State var temperature: Int = 0
    
    var body: some View {
        VStack {
            Text("\(temperature) Celsius")
        }
        .padding()
        .onAppear {
            DispatchQueue.main.async {
                fetchWeather { result in
                    switch result {
                    case .success(let weather):
                        temperature = weather.inCelsius
                    case .failure(_): print("failure")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}


// MARK: - Models
struct Weather {
    var temperature: Double
    
    var inCelsius: Int {
        Int(temperature - 273.15)
    }
}

struct WeatherResponse: Decodable {
    var main: WeatherData
    
    struct WeatherData: Decodable {
        var temp: Double
    }
    
    static func buildWeather(from response: WeatherResponse) -> Weather {
        .init(temperature: response.main.temp)
    }
}


// MARK: - Networking
extension ContentView {
    func fetchWeather(completion: @escaping (Result<Weather, Error>) -> Void) {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=44.34&lon=10.99&appid=\(apiKey)") else { return }
        
        let urlRequest = URLRequest(url: url)
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
            guard let data = data else { return }
            
            do {
                let jsonData = try JSONDecoder().decode(WeatherResponse.self, from: data)
                let weather = WeatherResponse.buildWeather(from: jsonData)
                
                completion(.success(weather))
                
            } catch let error {
                completion(.failure(error))
            }
        }
        
        dataTask.resume()
    }
}
