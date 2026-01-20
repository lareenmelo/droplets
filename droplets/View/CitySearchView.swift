//
//  CitySearchView.swift
//  droplets
//
//  Created by Lareen Melo on 1/20/26.
//

import CoreLocation
import MapKit
import SwiftUI

struct CitySearchView: View {
    @ObservedObject var viewModel = ViewModel()
    @Binding var city: City?
    var dismissViewAction: () -> Void

    var body: some View {
        NavigationStack {
            List(viewModel.suggestedCities, id: \.self) { city in
                Button(action: {
                    searchLocation(completion: city)
                    dismissViewAction()
                }, label: {
                    Text(city.title)
                })
            }
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer, prompt: "Enter city name")
    }

    private func searchLocation(completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        searchRequest.naturalLanguageQuery = viewModel.searchText
        
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            if let response {
                for item in response.mapItems {
                    if let name = item.name,
                       let location = item.placemark.location {
                        city = .init(
                            name: name,
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude)
                    }
                }
            }
        }
    }
}

// MARK: City Search View Model
extension CitySearchView {
    class ViewModel: NSObject, ObservableObject {
        let completer = MKLocalSearchCompleter()
        @Published var suggestedCities: [MKLocalSearchCompletion] = []
        @Published var cities: [City] = []
        @Published var searchText = "" {
            didSet {
                completer.queryFragment = searchText
            }
        }

        override init() {
            super.init()
            
            completer.delegate = self
            completer.resultTypes = .address
            completer.addressFilter = .init(including: .locality)
        }
    }
}

extension CitySearchView.ViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestedCities = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        // TODO: Error Handling
        print(#function, error)
    }
}
