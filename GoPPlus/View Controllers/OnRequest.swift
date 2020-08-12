import UIKit
import GoogleMaps

class OnRequest: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var mapContainer: UIView!
    @IBOutlet weak var centerUserLocation: UIImageView!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var swipeContainer: UIView!
    @IBOutlet weak var swipeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var swipeHeight100Constraint: NSLayoutConstraint!
    @IBOutlet weak var swipeHeightLargeConstraint: NSLayoutConstraint!
    @IBOutlet weak var timelabel: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    private let locationManager = CLLocationManager()
    private var map = GMSMapView()
    let zoom:Float = 16.0
    var doApplyMapChange:Bool = true
    var doSwipeContainerHidden:Bool = true
    var vehiclesArray:[Constants.VehicleByType] = []
    var typeSelected:Constants.VehicleByType = Constants.VehicleByType(id: 0, nombre: "", minima: 0, precio_min: 0, precio_base: 0, precio_km: 0, precio_minimo: 0, unselected: "", selected: "")
    var nearVehicles:[Constants.NearVehicle] = []
    var nearVehiclesMarkers:[GMSMarker] = []
    var latitude:Double = 0.0
    var longitude:Double = 0.0
    var vehicleIndexSelected = -1
    var loopNearVehicles:Bool = true
    var unratedService:Constants.UnratedService = Constants.UnratedService(id: 0, conductor: 0, nombre_conductor: "", fecha: "", precio: 0)
    var ratingOpened:Bool = false
    var mapCreated:Bool = false
    var validStreet:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showLoading()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.setTouchListeners()
        self.hideLoading()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.loopNearVehicles = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.loopNearVehicles = true
        
        if mapCreated == false {
            self.loadMap()
            self.getUserLocation()
            mapCreated = true
        }
    }

    private func setTouchListeners() {
        self.centerUserLocation.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleCenterTap(_:))))
        self.streetLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleOpenSearchTap(_:))))
    }
    
    @objc func handleCenterTap(_ sender: UITapGestureRecognizer) {
        getUserLocation()
    }
    
    @objc func handleOpenSearchTap(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "addressSegue", sender: self)
    }
    
    @IBAction func openDestination(_ sender: Any) {
        if self.typeSelected.id != 0 {
            if self.latitude != 0 && self.longitude != 0 {
                performSegue(withIdentifier: "openDestinationSegue", sender: self)
            } else {
                Constants.showMessage(msg: "Ubicación no válida")
            }
        } else {
            Constants.showMessage(msg: "Selecciona un tipo de vehículo")
        }
    }

    private func loadMap() {
        self.map = GMSMapView.map(withFrame: self.mapContainer.bounds, camera: GMSCameraPosition.camera(withLatitude: 21.122039, longitude: -101.667102, zoom: zoom))
        self.map.autoresizingMask = [.flexibleWidth , .flexibleHeight]
        self.map.delegate = self
        self.mapContainer.addSubview(self.map)
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        self.latitude =  mapView.projection.coordinate(for: mapView.center).latitude
        self.longitude = mapView.projection.coordinate(for: mapView.center).longitude
        
        if self.doApplyMapChange {
            getLocationAddress(location: mapView.projection.coordinate(for: mapView.center))
        }
    }
    
    private func getUserLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0.0
        
        if (!CLLocationManager.locationServicesEnabled()) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways) {
                locationManager.startUpdatingLocation()
            } else {
                locationManager.requestWhenInUseAuthorization()
            }
        }
        
         self.displayVehiclesByType()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.denied) {
            Constants.showMessage(msg: "Habilita los servicios de ubicación")
        } else if (status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse) {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.last {
            manager.stopUpdatingLocation()
            
            self.map.camera = GMSCameraPosition.camera(withLatitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, zoom: self.zoom)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager didFailWithError")
    }
    
    func getLocationAddress(location:CLLocationCoordinate2D) {
        
        if !Constants.isConnectedToNetwork() {
            Constants.showMessage(msg: "No tienes conexión a internet")
        } else {
            GMSGeocoder().reverseGeocodeCoordinate(location) { (response, error) in
                if error != nil {
                    return
                }
                
                if let result = response?.firstResult() {
                    self.validStreet = false
                    self.streetLabel.text = "Sin disponibilidad en esta zona"
                    
                    if let countryCode = result.country {
                        if (countryCode == "México" || countryCode == "Mexico") {
                            if let street = result.thoroughfare,
                                let locality = result.subLocality {
                                
                                self.streetLabel.text = street + " " + locality
                            } else {
                                self.streetLabel.text = result.thoroughfare ?? "Calle no encontrada"
                            }
                            
                            self.validStreet = true
                        }
                    }
                } else {
                    Constants.showMessage(msg: "No se encontraron direcciones")
                }
            }
        }
    }
    
    @IBAction func unwindStartAddress(_ sender: UIStoryboardSegue) {
        if let source = sender.source as? Search {
            if !source.location.address.isEmpty {
                self.doApplyMapChange = false
                self.streetLabel.text = source.location.address
                self.map.camera = GMSCameraPosition.camera(withLatitude: source.location.latitude, longitude: source.location.longitude, zoom: self.zoom)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.doApplyMapChange = true
                }
            }
        }
    }
    
    @IBAction func unwindDestinationAddress(_ sender: UIStoryboardSegue) {
        if let source = sender.source as? Destination {
            if source.serviceCreated {
                self.showLoading()
            }
        }
    }
    
    @IBAction func unwindFromRating(_ sender: UIStoryboardSegue) {
        if let source = sender.source as? Rating {
            self.ratingOpened = false
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "openDestinationSegue" {
            if !self.validStreet {
                Constants.showMessage(msg: "Elige una dirección válida")
                return false
            }
        }
        
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if Constants.isConnectedToNetwork() == false {
            Constants.showMessage(msg: "No tienes conexión a internet")
            return
        }
        
        
        if segue.identifier == "addressSegue" {
            if let destination = segue.destination as? Search {
                destination.unwindIdentifier = "unwindStartAddress"
            }
        }
        
        if segue.identifier == "openDestinationSegue" {
            if self.shouldPerformSegue(withIdentifier: "openDestinationSegue", sender: self) {
                if let destination = segue.destination as? Destination {
                    destination.typeSelected = self.typeSelected
                    destination.startAddress = Constants.SDAddress(latitude: self.latitude, longitude: self.longitude, address: self.streetLabel.text!)
                }
            }
        }
        
        if segue.identifier == "openRating" {
            if let destination = segue.destination as? Rating {
                destination.unratedService = self.unratedService
            }
        }
    }
    
    @IBAction func doSwipeContainer(_ sender: Any) {
        if doSwipeContainerHidden {
            self.swipeHeight100Constraint.isActive = false
            self.swipeHeightLargeConstraint.isActive = true
            self.swipeButton.setImage(UIImage(named: "chevronabajo"), for: UIControl.State.normal)
        } else {
            self.swipeHeight100Constraint.isActive = true
            self.swipeHeightLargeConstraint.isActive = false
            self.swipeButton.setImage(UIImage(named: "chevronarriba"), for: UIControl.State.normal)
        }
        
        UIView.animate(withDuration: 0.3){
            self.view.layoutIfNeeded()
        }

        doSwipeContainerHidden = !doSwipeContainerHidden
    }
    
    private func displayVehiclesByType() {
        if let data = UserDefaults.standard.value(forKey:"vehiclesByType") as? Data {
            guard let vehiclesByType = try? PropertyListDecoder().decode([Constants.VehicleByType].self, from: data) else {
                print("Error getting vehiclesByType")
                return
            }
            
            self.vehiclesArray = vehiclesByType
            
            if self.vehicleIndexSelected == -1 {
                self.vehicleIndexSelected = 0;
            }
            
            self.typeSelected = self.vehiclesArray[self.vehicleIndexSelected]
            self.collectionView.reloadData()
            self.doLoopNearVehicles()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                self.displayVehiclesByType()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.displayVehiclesByType()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        for cell in self.collectionView.visibleCells as! [VehicleCell] {
            cell.setImage(selected: false)
        }
        
        self.vehicleIndexSelected = indexPath.row
        
        let cell = collectionView.cellForItem(at: indexPath) as! VehicleCell
        cell.setImage(selected: true)
        self.typeSelected = self.vehiclesArray[indexPath.row];
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.vehiclesArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VehicleCell", for: indexPath) as! VehicleCell
        let vehicle = self.vehiclesArray[indexPath.row] as Constants.VehicleByType
        
        cell.typeName.text = vehicle.nombre
        cell.minprice.text = String(format:"Mínima $%.2f", vehicle.minima)
        cell.minuteprice.text = String(format:"Minuto $%.2f", vehicle.precio_min)
        cell.kmprice.text = String(format:"KM $%.2f", vehicle.precio_km)
        cell.selectedImage = vehicle.selected
        cell.unselectedImage = vehicle.unselected
        cell.image.image = nil
        
        if indexPath.row == self.vehicleIndexSelected {
            cell.setImage(selected: true)
        } else {
            cell.setImage(selected: false)
        }
        
        return cell
    }
    
    func doLoopNearVehicles() {
        if (self.loopNearVehicles) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(10) ) {
                self.displayNearVehicles()
                self.doLoopNearVehicles()
            }
        }
    }
    
    func displayNearVehicles() {
        if self.typeSelected.id != 0 && self.latitude != 0 && self.longitude != 0 {
            let type = String(self.typeSelected.id)
            let lat  = String(format:"%f", self.latitude)
            let lng  = String(format:"%f", self.longitude)
            let url  = "vehicles?latitude=" + lat + "&longitude=" + lng + "&type=" + type
            self.map.clear()
            
            Constants.getRequest(endpoint: Constants.APIEndpoint.client + url, parameters: nil) { (result) in
                guard let result = result else {
                    return
                }
                
                DispatchQueue.main.async {
                    do {
                    
                        if let vehicles = result["data"] {
                            guard let vehiclesArray = try? JSONSerialization.data(withJSONObject:vehicles) else {
                                return
                            }
                            
                            self.nearVehicles = try JSONDecoder().decode([Constants.NearVehicle].self, from: vehiclesArray)
                            
                            for i:Constants.NearVehicle in self.nearVehicles {
                                let marker = GMSMarker(position: CLLocationCoordinate2DMake(i.latitude, i.longitude))
                                marker.map = self.map
                                marker.icon = UIImage(named: "carios")
                                self.nearVehiclesMarkers.append(marker)
                            }
                            
                            self.calculateTime()
                        } else {
                            self.timelabel.text = "Sin unidades"
                        }
                    
                    } catch {
                        print("Error while getting nearest vehicles")
                    }
                }
            }
        }
    }
    
    
    func calculateTime() {
        if self.nearVehicles.count > 0 {
            let firstVehicle = self.nearVehicles[0]
            var minutes:Double = 0
            let origin = String(firstVehicle.latitude) + "," + String(firstVehicle.longitude)
            let destination = String(self.latitude) + "," + String(self.longitude)
            
            Constants.getDistanceMatrix(parameters: ["origins" : origin, "destinations": destination, "travelMode": "DRIVING", "key": Constants.APIKEY]) { (result) in
                
                DispatchQueue.main.async {
                    struct JSON_Distance: Codable{
                        var destination_addresses: [String]!
                        var origin_addresses: [String]!
                        var rows: [Element]!
                        var status: String!
                    }
                    
                    struct Element: Codable {
                        var elements: [internalJSON]!
                    }
                    
                    struct internalJSON:Codable {
                        var distance: DistanceOrTime!
                        var duration: DistanceOrTime!
                        var status: String!
                    }
                    
                    struct DistanceOrTime: Codable {
                        var text: String!
                        var value: Int!
                        
                    }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: result!, options: [])
                        let matrix =  try JSONDecoder().decode(JSON_Distance.self, from: jsonData)
                        
                        if matrix.rows.count > 0 {
                            if matrix.rows[0].elements.count > 0 {
                                minutes = Double(matrix.rows[0].elements[0].duration.value) / 60
                                
                                DispatchQueue.main.async {
                                    self.timelabel.text = String(format:"%.0f min", minutes)
                                }
                            }
                        } else {
                            self.timelabel.text = "Sin ruta"
                        }
                    }
                    catch let err {
                        print(err)
                    }
                }
                
                
            }
        } else {
            DispatchQueue.main.async {
                self.timelabel.text = "Sin unidades"
            }
        }
    }
    
    public func showLoading() {
        self.loading.startAnimating()
        self.view.isUserInteractionEnabled = false
    }
    
    public func hideLoading() {
        DispatchQueue.main.async {
            self.loading.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    public func newUnratedService(service: Constants.UnratedService) {
        DispatchQueue.main.async {
            if service.id != 0 {
                if self.ratingOpened == false {
                    self.ratingOpened = true
                    self.unratedService = service
                    self.performSegue(withIdentifier: "openRating", sender: self)
                }
            }
        }
    }
    
}
