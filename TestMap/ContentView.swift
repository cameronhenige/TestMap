
import SwiftUI
import MapKit

struct ContentView: View {
    
    @State var map = MKMapView()

    var body: some View {
        Text("Why is this crashing when scrolling close to the box and moving quickly?")
            .padding()
        BoxMapView(map: self.$map).frame(width: 400.0, height: 400.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
