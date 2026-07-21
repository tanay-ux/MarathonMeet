import Foundation
import CoreLocation

struct GPXRoute: Identifiable {
    let id = UUID()
    let name: String
    let coordinates: [CLLocationCoordinate2D]

    var polylineCoordinates: [CLLocationCoordinate2D] { coordinates }

    static let empty = GPXRoute(name: "Course", coordinates: [])
}

enum GPXParser {
    static func parse(data: Data, name: String = "Course") throws -> GPXRoute {
        let parser = XMLParser(data: data)
        let delegate = GPXParserDelegate()
        parser.delegate = delegate
        guard parser.parse(), !delegate.coordinates.isEmpty else {
            throw GPXParseError.noTrackPoints
        }
        return GPXRoute(name: name, coordinates: delegate.coordinates)
    }

    static func parse(url: URL) throws -> GPXRoute {
        let data = try Data(contentsOf: url)
        return try parse(data: data, name: url.deletingPathExtension().lastPathComponent)
    }

    static func loadBundled(named resourceName: String) -> GPXRoute? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "gpx"),
              let route = try? parse(url: url) else { return nil }
        return route
    }
}

enum GPXParseError: LocalizedError {
    case noTrackPoints

    var errorDescription: String? {
        switch self {
        case .noTrackPoints: return "No track points found in GPX file."
        }
    }
}

private final class GPXParserDelegate: NSObject, XMLParserDelegate {
    var coordinates: [CLLocationCoordinate2D] = []
    private var currentElement = ""
    private var currentLat: String?
    private var currentLon: String?

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "trkpt" || elementName == "rtept" {
            currentLat = attributeDict["lat"]
            currentLon = attributeDict["lon"]
            if let lat = currentLat.flatMap(Double.init), let lon = currentLon.flatMap(Double.init) {
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
    }
}
