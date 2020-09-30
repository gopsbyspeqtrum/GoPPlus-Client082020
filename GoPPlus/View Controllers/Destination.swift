import UIKit
import GoogleMaps
import WebKit

class Destination: UIViewController, GMSMapViewDelegate, WKNavigationDelegate{

    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var mapContainer: UIView!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var fareLabel: UILabel!
    @IBOutlet weak var webview: WKWebView?
    
     
    private var map = GMSMapView()
    let zoom:Float = 16.0
    var startAddress:Constants.SDAddress = Constants.SDAddress(latitude: 0, longitude: 0, address: "")
    var endAddress:Constants.SDAddress = Constants.SDAddress(latitude: 0, longitude: 0, address: "")
    var startMarker:GMSMarker = GMSMarker(position: CLLocationCoordinate2DMake(0, 0))
    var typeSelected:Constants.VehicleByType = Constants.VehicleByType(id: 0, nombre: "", minima: 0, precio_min: 0, precio_base: 0, precio_km: 0, precio_minimo: 0, unselected: "", selected: "")
    var doApplyMapChange:Bool = true
    var selectedKM:Double = 0
    var estimatedFare:Double = 0
    var promocode:Constants.PromoTypeCode = Constants.PromoTypeCode(id: "", typecode: "Ninguno", type: "")
    var creditcard:Constants.CreditCardItem = Constants.CreditCardItem(Id: 0, Numero: "Ninguna")
    var serviceCreated:Bool = false
    var mapCreated:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.serviceCreated = false
        self.webview?.navigationDelegate = self
        self.webview?.isHidden = true
        self.endAddress = self.startAddress
        self.endLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleOpenSearchTap(_:))))
        self.startLabel.text = self.startAddress.address
        self.endLabel.text = self.endAddress.address
        self.startMarker.position = CLLocationCoordinate2DMake(self.startAddress.latitude, self.startAddress.longitude)
        self.startMarker.icon = UIImage(named: "s_pin")
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if mapCreated == false {
            loadMap()
            mapCreated = true
        }
    }
    
    func loadMap(){
        self.map = GMSMapView.map(withFrame: self.mapContainer.bounds, camera: GMSCameraPosition.camera(withLatitude: self.startAddress.latitude, longitude: self.startAddress.longitude, zoom: zoom))
        self.map.autoresizingMask = [.flexibleWidth , .flexibleHeight]
        self.map.delegate = self
        self.mapContainer.addSubview(self.map)
        self.startMarker.map = self.map
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if (self.doApplyMapChange) {
            self.endAddress.latitude =  mapView.projection.coordinate(for: mapView.center).latitude
            self.endAddress.longitude = mapView.projection.coordinate(for: mapView.center).longitude
            getLocationAddress(location: mapView.projection.coordinate(for: mapView.center))
        }
    }
    
    @objc func handleOpenSearchTap(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "endAddressSegue", sender: self)
    }
    
    @IBAction func unwindEndAddress(_ sender: UIStoryboardSegue) {
        if let source = sender.source as? Search {

            if !source.location.address.isEmpty {
                self.doApplyMapChange = false
                self.endLabel.text = source.location.address
                
                self.map.camera = GMSCameraPosition.camera(withLatitude: source.location.latitude, longitude: source.location.longitude, zoom: self.zoom)
                self.endAddress.latitude = source.location.latitude
                self.endAddress.longitude = source.location.longitude
                calculateFare()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.doApplyMapChange = true
                }
            }
        }
    }
    
    @IBAction func unwindCreditCard(_ sender: UIStoryboardSegue) {
        if let source = sender.source as? CreditCard {
            self.creditcard = source.selectedCreditCard
            self.cardLabel.text = self.creditcard.Numero
        }
    }
    
    @IBAction func unwindDiscount(_ sender: UIStoryboardSegue) {
        if let source = sender.source as? PromoCode {
            self.promocode = source.newTypeCode
            self.codeLabel.text = self.promocode.typecode
        }
    }
    
    @IBAction func doCenterMap(_ sender: Any) {
        self.map.animate(to: GMSCameraPosition.camera(withLatitude:  self.startAddress.latitude, longitude:  self.startAddress.longitude, zoom: self.zoom))
    }
    
    @IBAction func doStartPayworks(_ sender: Any) {
        
        if self.creditcard.Id == 0 {
            Constants.showMessage(msg: "Selecciona un método de pago para continuar")
            return
        }
        
        if self.startAddress.address == self.endAddress.address {
            Constants.showMessage(msg: "Elige una dirección destino diferente al punto de origen")
            return
        }
        
        if self.selectedKM <= 0.1 {
            Constants.showMessage(msg: "Elige una dirección destino diferente al punto de origen")
            return
        }
        
        if self.estimatedFare <= 0 {
            Constants.showMessage(msg: "La tarifa no ha sido calculada correctamente.")
            return
        }
        
        let preauthFare = self.estimatedFare * 2
        var code = ""
        var coupon = ""
        
        if !self.promocode.id.isEmpty {
            code = self.promocode.typecode
            
            if self.promocode.type == "coupon" {
                coupon = self.promocode.id
            }
            
            if self.promocode.type == "code" {
                code = self.promocode.id
            }
            
        }
        
        
        var url_ = Constants.APIEndpoint.payment + "preauth-service-start"
        url_ += "?card_id=" + String(self.creditcard.Id)
        url_ += "&origen=" + self.startAddress.address.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        url_ += "&destino=" + self.endAddress.address.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        url_ += "&lat_origen=" + String(self.startAddress.latitude)
        url_ += "&lng_origen=" + String(self.startAddress.longitude)
        url_ += "&lat_destino=" + String(self.endAddress.latitude)
        url_ += "&lng_destino=" + String(self.endAddress.longitude)
        url_ += "&usuario_id=" + String(Constants.getIntStored(key: Constants.DBKeys.user + "id"))
        url_ += "&tipo_id=" + String(self.typeSelected.id)
        url_ += "&afiliado=" + String(Constants.getIntStored(key: Constants.DBKeys.user + "afiliado"))
        
        if !code.isEmpty {
            url_ += "&codigo=" + code
        }
        
        if !coupon.isEmpty {
            url_ += "&cupon=" + coupon
        }
        
        url_ += "&cliente_id=" + String(Constants.getIntStored(key: Constants.DBKeys.user + "clienteid"))
        url_ += "&monto=" + String(format: "%.0f", preauthFare)
        url_ += "&km=" + String(format: "%.2f", self.selectedKM)
        
        self.webview?.isHidden = false

        self.view.bringSubviewToFront(webview!)
        
        var request = URLRequest(url: URL(string: url_)!)
        
        request.addValue(Constants.getHeaderValue(key: "appid"), forHTTPHeaderField:"appid")
        request.addValue(Constants.toEncrypt(text: Constants.getHeaderValue(key: "user.id")), forHTTPHeaderField:"userid")
        
        webview?.load(request)
    }
    
    @IBAction func openCreditCard(_ sender: Any) {
        self.performSegue(withIdentifier: "openCreditCardSegue", sender: self)
    }
    
    @IBAction func openDiscount(_ sender: Any) {
        self.performSegue(withIdentifier: "openDiscountSegue", sender: self)
    }
    
    @IBAction func dismissController(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "endAddressSegue" {
            if let destination = segue.destination as? Search {
                destination.unwindIdentifier = "unwindEndAddress"
            }
        }
        
        if segue.identifier == "openCreditCardSegue" {
            if let destination = segue.destination as? CreditCard {
                destination.prevCreditCard = self.creditcard
            }
        }
        
        if segue.identifier == "openDiscountSegue" {
            if let destination = segue.destination as? PromoCode {
                destination.prevTypeCode = self.promocode
            }
        }
    }
    
    
    func getLocationAddress(location:CLLocationCoordinate2D) {
        GMSGeocoder().reverseGeocodeCoordinate(location) { (response, error) in
            if error != nil {
                return
            }
            
            if let result = response?.firstResult() {
                self.endLabel.text = "Sin disponibilidad en esta zona"
                
                if let countryCode = result.country {
                    if (countryCode == "México" || countryCode == "Mexico") {
                        if let street = result.thoroughfare,
                            let locality = result.subLocality {
                            self.endLabel.text = street + " " + locality
                        } else {
                            self.endLabel.text = result.thoroughfare ?? "Calle no encontrada"
                        }
                        
                         self.endAddress.address = self.endLabel.text!
                    }
                }
                
                self.calculateFare()
            } else {
                Constants.showMessage(msg: "No se encontraron direcciones")
            }
        }
    }
    
    func calculateFare() {
        var minutes:Double = 0
        let coordinate1 = CLLocation(latitude: self.startAddress.latitude, longitude: self.startAddress.longitude)
        let coordinate2 = CLLocation(latitude: self.endAddress.latitude, longitude: self.endAddress.longitude)
        self.selectedKM = coordinate1.distance(from: coordinate2) / 1000
        
        	
        let origin = String(self.startAddress.latitude) + "," + String(self.startAddress.longitude)
        let destination = String(self.endAddress.latitude) + "," + String(self.endAddress.longitude)
        
        
        Constants.getDistanceMatrix(parameters: ["origins" : origin, "destinations": destination, "travelMode": "DRIVING", "key": Constants.APIKEY]) { (result) in
  
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
                        
                        let estimated:Double = (self.typeSelected.precio_min * minutes) + (self.typeSelected.precio_km * self.selectedKM) + self.typeSelected.precio_base
                        
                        DispatchQueue.main.async {
                            if estimated < self.typeSelected.precio_minimo {
                                self.fareLabel.text = String(format: "$%.2f", self.typeSelected.precio_minimo)
                                self.estimatedFare = self.typeSelected.precio_minimo
                            } else {
                                self.fareLabel.text = String(format: "$%.2f", estimated)
                                self.estimatedFare = estimated
                            }
                        }
                    }
                }
            }
            catch let err {
                print(err)
            }
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let url_ = navigationResponse.response.url?.absoluteString {
            if url_.range(of: "preauth-service-ok") != nil {
                self.serviceCreated = true
                performSegue(withIdentifier: "unwindDestinationAddress", sender: self)
                
            }
            
            if url_.range(of: "preauth-service-error") != nil {
                webView.isHidden = true
                self.view.sendSubviewToBack(webView)
                self.serviceCreated = false
                
                DispatchQueue.main.async {
                    if let errorMessage = self.getQueryStringParameter(url: navigationResponse.response.url?.absoluteString ?? "", param: "e") {
                        Constants.showMessage(msg: errorMessage)
                    } else {
                        Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                    }
                }
            }
        }
        decisionHandler(.allow)
    }
    }
    
//    func webView(_ webView: WKWebView, shouldStartLoadWith request: URLRequest, navigationType: WKNavigationType.Type) -> Bool {
//        if let url_ = request.url?.absoluteString {
//            if url_.range(of: "preauth-service-ok") != nil {
//                self.serviceCreated = true
//                performSegue(withIdentifier: "unwindDestinationAddress", sender: self)
//            }
//
//            if url_.range(of: "preauth-service-error") != nil {
//                self.webview.isHidden = true
//                self.view.sendSubviewToBack(self.webview)
//                self.serviceCreated = false
//
//                DispatchQueue.main.async {
//                    if let errorMessage = self.getQueryStringParameter(url: request.url?.absoluteString ?? "", param: "e") {
//                        Constants.showMessage(msg: errorMessage)
//                    } else {
//                        Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
//                    }
//                }
//            }
//        }
//
//        return true
//    }

