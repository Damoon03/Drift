//  LocationService.swift
//  Drift

import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {

    @Published var locationName: String = ""
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let p = placemarks?.first
            let name = p?.locality ?? p?.subLocality ?? p?.name ?? ""
            Task { @MainActor in
                self.locationName = name.uppercased()
                self.latitude = location.coordinate.latitude
                self.longitude = location.coordinate.longitude
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        Task { @MainActor in self.reverseGeocode(loc) }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse {
                manager.requestLocation()
            }
        }
    }
}
