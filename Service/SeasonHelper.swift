//  SeasonHelper.swift
//  Drift

import Foundation
import CoreLocation
import WeatherKit

struct SeasonHelper {

    static func season(for date: Date, latitude: Double? = nil) -> String {
        let month = Calendar.current.component(.month, from: date)
        let inSouthernHemisphere = (latitude ?? 0) < 0
        switch month {
        case 3...5:  return inSouthernHemisphere ? "AUTUMN" : "SPRING"
        case 6...8:  return inSouthernHemisphere ? "WINTER" : "SUMMER"
        case 9...11: return inSouthernHemisphere ? "SPRING" : "AUTUMN"
        default:     return inSouthernHemisphere ? "SUMMER" : "WINTER"
        }
    }
}
