//
//  LocationService.swift
//  droplets
//
//  Created by Lareen Melo on 12/2/25.
//

import CoreLocation

/// Directly receives location-related events from a location manager and handles updating user's location status accordingly
@Observable
class LocationProvider: NSObject, CLLocationManagerDelegate {
    private var manager = CLLocationManager()
    var coordinates: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        coordinates = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // TODO: Handle Error
        print("Handle location update error")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted,
                .denied:
            print("Handle ocation denied")
        case .authorizedAlways,
                .authorizedWhenInUse:
            manager.requestLocation()
        @unknown default:
            print("Handle unknown error")
        }
    }
}
