import SwiftUI
import MapKit

struct BoxMapView: UIViewRepresentable {
    
    @Binding var map : MKMapView
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
        
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: BoxMapView
        
        init(_ parent: BoxMapView) {
            self.parent = parent
        }
        
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            mapView.removeOverlays(mapView.overlays)
            
            let geoHash = mapView.centerCoordinate.geohash(length: 7)

            let geoHashSquare = GeoHashConverter.decode(hash: geoHash)
            
            let topLeft = CLLocationCoordinate2DMake(geoHashSquare!.latitude.min, geoHashSquare!.longitude.min)
            let topRight = CLLocationCoordinate2DMake(geoHashSquare!.latitude.min, geoHashSquare!.longitude.max)
            let bottomLeft = CLLocationCoordinate2DMake(geoHashSquare!.latitude.max, geoHashSquare!.longitude.min)
            let bottomRight = CLLocationCoordinate2DMake(geoHashSquare!.latitude.max, geoHashSquare!.longitude.max)

            let points = [topLeft, topRight, bottomRight, bottomLeft]
            print(points)

            let polygon = MKPolygon(coordinates: points, count: points.count)
            
            
            mapView.addOverlay(polygon)
            
            
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            
            let over = MKPolygonRenderer(overlay: overlay)
            over.strokeColor = .blue
            over.fillColor = .red
            over.lineWidth = 3
            return over
        }
        
        
    }
    
    func makeUIView(context: Context) -> MKMapView {
        map.delegate = context.coordinator
        let centerCoordinate = CLLocationCoordinate2D(latitude: 32, longitude: 33)
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        map.setRegion(region, animated: true)
        
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        

        
    }
}

