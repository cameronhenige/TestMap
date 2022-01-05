
import Foundation
import CoreLocation

public struct GeoHashConverter {
    public static func decode(hash: String) -> (latitude: (min: Double, max: Double), longitude: (min: Double, max: Double))? {
        // For example: hash = u4pruydqqvj

        let bits = hash.map { bitmap[$0] ?? "?" }.joined(separator: "")
        guard bits.count % 5 == 0 else { return nil }
        // bits = 1101000100101011011111010111100110010110101101101110001

        let (lat, lon) = bits.enumerated().reduce(into: ([Character](), [Character]())) {
            if $1.0 % 2 == 0 {
                $0.1.append($1.1)
            } else {
                $0.0.append($1.1)
            }
        }
        // lat = [1,1,0,1,0,0,0,1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,0,1,0,0]
        // lon = [1,0,0,0,0,1,1,1,0,1,1,0,0,1,1,0,1,0,0,1,1,1,0,1,1,1,0,1]

        func combiner(array a: (min: Double, max: Double), value: Character) -> (Double, Double) {
            let mean = (a.min + a.max) / 2
            return value == "1" ? (mean, a.max) : (a.min, mean)
        }

        let latRange = lat.reduce((-90.0, 90.0), combiner)
        // latRange = (57.649109959602356, 57.649111300706863)

        let lonRange = lon.reduce((-180.0, 180.0), combiner)
        // lonRange = (10.407439023256302, 10.407440364360809)

        return (latRange, lonRange)
    }

    public static func encode(latitude: Double, longitude: Double, length: Int) -> String {
        // For example: (latitude, longitude) = (57.6491106301546, 10.4074396938086)

        func combiner(array a: (min: Double, max: Double, array: [String]), value: Double) -> (Double, Double, [String]) {
            let mean = (a.min + a.max) / 2
            if value < mean {
                return (a.min, mean, a.array + "0")
            } else {
                return (mean, a.max, a.array + "1")
            }
        }

        let lat = Array(repeating: latitude, count: length*5).reduce((-90.0, 90.0, [String]()), combiner)
        // lat = (57.64911063015461, 57.649110630154766, [1,1,0,1,0,0,0,1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,0,...])

        let lon = Array(repeating: longitude, count: length*5).reduce((-180.0, 180.0, [String]()), combiner)
        // lon = (10.407439693808236, 10.407439693808556, [1,0,0,0,0,1,1,1,0,1,1,0,0,1,1,0,1,0,0,1,1,1,0,1,1,1,0,1,0,1,..])

        let latlon = lon.2.enumerated().flatMap { [$1, lat.2[$0]] }
        // latlon - [1,1,0,1,0,0,0,1,0,0,1,0,1,0,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,...]

        let bits = latlon.enumerated().reduce([String]()) { $1.0 % 5 > 0 ? $0 << $1.1 : $0 + $1.1 }
        //  bits: [11010,00100,10101,10111,11010,11110,01100,10110,10110,11011,10001,10010,10101,...]

        let arr = bits.compactMap { charmap[$0] }
        // arr: [u,4,p,r,u,y,d,q,q,v,j,k,p,b,...]

        return String(arr.prefix(length))
    }

    // MARK: Private

    private static let bitmap = "0123456789bcdefghjkmnpqrstuvwxyz".enumerated()
        .map {
            ($1, String(integer: $0, radix: 2, padding: 5))
        }
        .reduce(into: [Character: String]()) {
            $0[$1.0] = $1.1
    }

    private static let charmap = bitmap
        .reduce(into: [String: Character]()) {
            $0[$1.1] = $1.0
    }
}

public extension GeoHashConverter {
    enum Precision: Int {
        case twentyFiveHundredKilometers = 1    // ±2500 km
        case sixHundredThirtyKilometers         // ±630 km
        case seventyEightKilometers             // ±78 km
        case twentyKilometers                   // ±20 km
        case twentyFourHundredMeters            // ±2.4 km
        case sixHundredTenMeters                // ±0.61 km
        case seventySixMeters                   // ±0.076 km
        case nineteenMeters                     // ±0.019 km
        case twoHundredFourtyCentimeters        // ±0.0024 km
        case sixtyCentimeters                   // ±0.00060 km
        case seventyFourMillimeters             // ±0.000074 km
    }

    static func encode(latitude: Double, longitude: Double, precision: GeoHashConverter.Precision) -> String {
        return encode(latitude: latitude, longitude: longitude, length: precision.rawValue)
    }
}

private extension String {
    init(integer n: Int, radix: Int, padding: Int) {
        let s = String(n, radix: radix)
        let pad = (padding - s.count % padding) % padding
        self = Array(repeating: "0", count: pad).joined(separator: "") + s
    }
}

private func + (left: [String], right: String) -> [String] {
    var arr = left
    arr.append(right)
    return arr
}

private func << (left: [String], right: String) -> [String] {
    var arr = left
    var s = arr.popLast()!
    s += right
    arr.append(s)
    return arr
}

#if canImport(CoreLocation)

// MARK: - CLLocationCoordinate2D

import CoreLocation

public extension CLLocationCoordinate2D {
    init(geohash: String) {
        if let (lat, lon) = GeoHashConverter.decode(hash: geohash) {
            self = CLLocationCoordinate2DMake((lat.min + lat.max) / 2, (lon.min + lon.max) / 2)
        } else {
            self = kCLLocationCoordinate2DInvalid
        }
    }

    func geohash(length: Int) -> String {
        return GeoHashConverter.encode(latitude: latitude, longitude: longitude, length: length)
    }

    func geohash(precision: GeoHashConverter.Precision) -> String {
        return geohash(length: precision.rawValue)
    }
}

extension CLLocationCoordinate2D {
    var cartesian: CartesianCoordinate3D { .init(from: self) }

    // Returns the coordinates of the midpoint between point a and b.
    // Limitation: point a and b may not be diametrically opposite.
    public static func midpoint(between a: CLLocationCoordinate2D, and b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        ((a.cartesian + b.cartesian) / 2).spherical
    }
}

struct CartesianCoordinate3D {
    let x: Double
    let y: Double
    let z: Double

    var spherical: CLLocationCoordinate2D {
        let r = sqrt(x * x + y * y)
        if r == 0 {
            if z > 0 {
                return .init(latitude: 90, longitude: 0)
            } else if z < 0 {
                return .init(latitude: -90, longitude: 0)
            } else {
                // (x, y, z) == (0, 0, 0)
                return .init(latitude: .nan, longitude: .nan)
            }
        } else {
            let latitude = degrees(fromRadians: atan2(z, r))
            let longitude = degrees(fromRadians: atan2(y, x))
            return .init(latitude: latitude, longitude: longitude)
        }
    }

    static func + (a: CartesianCoordinate3D, b: CartesianCoordinate3D) -> CartesianCoordinate3D {
        .init(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)
    }

    static func / (numerator: CartesianCoordinate3D, denominator: Double) -> CartesianCoordinate3D {
        .init(x: numerator.x / denominator, y: numerator.y / denominator, z: numerator.z / denominator)
    }
}

extension CartesianCoordinate3D {

    init(from locationCoordinate2D: CLLocationCoordinate2D) {
        let latitudeInRadians = radians(fromDegrees: locationCoordinate2D.latitude)
        let longitudeInRadians = radians(fromDegrees: locationCoordinate2D.longitude)

        x = cos(latitudeInRadians) * cos(longitudeInRadians)
        y = cos(latitudeInRadians) * sin(longitudeInRadians)
        z = sin(latitudeInRadians)
    }
}

private func degrees(fromRadians radians: Double) -> Double {
    radians * 180 / .pi
}

private func radians(fromDegrees degrees: Double) -> Double {
    degrees * .pi / 180
}

#endif
