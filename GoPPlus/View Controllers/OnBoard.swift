import UIKit
import GoogleMaps
import WebKit

class OnBoard: UIViewController, GMSMapViewDelegate, WKNavigationDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var driveImage: UIImageView!
    @IBOutlet weak var driverRate: UILabel!
    @IBOutlet weak var driverName: UILabel!
    @IBOutlet weak var makeModel: UILabel!
    @IBOutlet weak var extraInfo: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var licNumber: UILabel!
    @IBOutlet weak var mapContainer: UIView!
    @IBOutlet weak var webview: WKWebView?
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var butmensaje: UIButton!
    
    
    let zoom:Float = 15.0
    public var firstCentered:Bool = false
    var serviceData:Constants.ServiceData?
    private var map = GMSMapView()
    private var startMarker:GMSMarker = GMSMarker(position: CLLocationCoordinate2DMake(0, 0))
    private var endMarker:GMSMarker = GMSMarker(position: CLLocationCoordinate2DMake(0, 0))
    private var carMarker:GMSMarker = GMSMarker(position: CLLocationCoordinate2DMake(0, 0))
    private var mapRoute:GMSPolyline?
    var mapLoaded:Bool = false
    
    var chatController:Chat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webview?.navigationDelegate = self
        self.loading.stopAnimating()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        webview?.isHidden = true
        self.view.sendSubviewToBack(webview!)
        self.loading.stopAnimating()
    }

    @IBAction func centerMap(_ sender: Any) {
        if let data = self.serviceData {
            self.map.animate(to: GMSCameraPosition.camera(withLatitude: data.lat!, longitude: data.lng!, zoom: self.zoom))

        }
    }
    
    @IBAction func openChat(_ sender: Any) {
        //chatSegue
        self.performSegue(withIdentifier: "chatSegue", sender: self)
    }
    
    @IBAction func openchat2(_ sender: Any) {
        //chatSegue
        self.performSegue(withIdentifier: "chatSegue", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "chatSegue" {
            self.chatController = segue.destination as? Chat
            self.chatController?.service_id = self.serviceData?.idd ?? 0
            self.chatController?.driver_id = self.serviceData?.id_conductor ?? 0
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(true)
        if mapLoaded == false {
            setMap()
            mapLoaded = true
        }
    }
    
    @IBAction func cancelService(_ sender: Any) {
        Constants.showConfirmationWithButtonTitle(msg: "¿Seguro de cancelar el servicio?", acceptTitle: "Sí, cancelar", cancelTitle: "Seguir esperando") { (is_accepted) in
            
            if is_accepted {
                if let data = self.serviceData {
                    let url_ = Constants.APIEndpoint.payment + "postauth-service-start?act=CANCEL&id=" + String(data.id)
                    self.webview?.load(URLRequest(url: URL(string: url_)!))
                    self.view.bringSubviewToFront(self.webview!)
                    self.webview?.isHidden = false
                }
            }
        }
    }
    
    private func setMap() {

        self.map = GMSMapView.map(withFrame: self.mapContainer.bounds, camera: GMSCameraPosition.camera(withLatitude: 21.122039, longitude: -101.667102, zoom: self.zoom))
        self.map.autoresizingMask = [.flexibleWidth , .flexibleHeight]
        self.map.delegate = self
        self.mapContainer.addSubview(self.map)
    }
    
    public func setServiceData(data: Constants.ServiceData) {
        self.serviceData = data
        self.updateUI()

    }
    
    private func updateUI() {

        DispatchQueue.main.async {
            if let data = self.serviceData {
                self.map.clear()
                self.statusLabel.text = data.estatus_reserva_nombre
                self.driverName.text = data.nombre
                self.driverRate.text = String(data.calificacion ?? 5)
                self.makeModel.text = data.marca! + " " + data.modelo! + " " + data.color!
                self.extraInfo.text = data.placas!
                self.licNumber.text = data.permiso ?? ""
                //self.kmInfo.text = String(data.km ) + "km"
                
                let profileImageUrl = Constants.APIEndpoint.driver + "images"
                let parameters:[String:String] = ["id": String(data.id_conductor) + ".jpg"]
                let urlComponent = NSURLComponents(string: profileImageUrl)!
                
                urlComponent.queryItems = parameters.map { (key, value) in
                    URLQueryItem(name: key, value: value)
                }
                
                let imageData = try? Data(contentsOf: urlComponent.url!)
                self.driveImage.image = UIImage(data: imageData!)
                self.driveImage.layer.borderWidth = 1
                self.driveImage.layer.borderColor = UIColor.gray.cgColor
                self.driveImage.layer.cornerRadius = self.driveImage.frame.width / 2
                self.driveImage.clipsToBounds = true
                self.driveImage.layer.masksToBounds = true
                
                if data.estatus_reserva == 5 {
                    self.chatButton.isHidden = true
                    self.cancelButton.isHidden = true
                    
                    if self.chatController != nil {
                        self.chatController?.dismissController(self)
                    }
                    
                } else {
                    self.chatButton.isHidden = false
                    self.cancelButton.isHidden = false
                }
                
                if !self.firstCentered {
                    self.map.animate(to: GMSCameraPosition.camera(withLatitude: data.lat!, longitude: data.lng!, zoom: self.zoom))
                    self.firstCentered = true
                }
                
                
                self.startMarker = GMSMarker(position: CLLocationCoordinate2DMake(data.lat_origen, data.lng_origen))
                self.endMarker = GMSMarker(position: CLLocationCoordinate2DMake(data.lat_destino, data.lng_destino))
                self.carMarker = GMSMarker(position: CLLocationCoordinate2DMake(data.lat!, data.lng!))
                
                self.startMarker.title = data.origen
                self.endMarker.title = data.destino
                
                self.startMarker.icon = UIImage(named: "s_pin")
                self.endMarker.icon = UIImage(named: "s_flag")
                self.carMarker.icon = UIImage(named: "carios")
             
                self.startMarker.map = self.map
                self.endMarker.map = self.map
                self.carMarker.map = self.map
                
                self.getRoute()
            }
        }
    }
    
    func getRoute() {

        if let data = self.serviceData {
            let coordinate1 = CLLocation(latitude: data.lat!, longitude: data.lng!)
            var coordinate2 = CLLocation(latitude: data.lat_origen, longitude: data.lng_origen)
            
            if data.estatus_reserva == 5 {
                coordinate2 = CLLocation(latitude: data.lat_destino, longitude: data.lng_destino)
            }
            
            let origin = String(coordinate1.coordinate.latitude) + "," + String(coordinate1.coordinate.longitude)
            let destination = String(coordinate2.coordinate.latitude) + "," + String(coordinate2.coordinate.longitude)
            
            Constants.getDirectionsMatrix(parameters: ["origin": origin, "destination": destination, "key": Constants.APIKEY]) { (result) in
                
                guard let result = result else {
                    return
                }
                
                if let status = result["status"] as? String {
                    if status == "OK" {
                        if let routes = result["routes"] as? [[String: Any]] {
                            if routes.count > 0 {
                                if let route1 = routes[0] as? [String:Any] {
                                    if let overview_polyline = route1["overview_polyline"] as? [String:Any] {
                                        DispatchQueue.main.async {
                                            
                                            
                                            
                                            if let points = overview_polyline["points"] as? String {
                                                self.mapRoute = GMSPolyline(path: GMSPath(fromEncodedPath: points))
                                                self.mapRoute?.map = self.map
                                                self.mapRoute?.strokeColor = UIColor.blue
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            
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
                            let minutes = Double(matrix.rows[0].elements[0].duration.value) / 60
                            
                            DispatchQueue.main.async {
                                self.carMarker.title = String(format: "%.0f min", minutes)
                            }
                        }
                    }
                }
                catch let err {
                    print(err)
                }
            }
        }
    }


    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let url_ = navigationResponse.response.url?.absoluteString {
       
                   if url_.range(of: "postauth-service-end") != nil {
                       Constants.showMessage(msg: "Cancelado, espere un momento")
                   }
       
                   if url_.range(of: "postauth-service-error") != nil {
       
                    if let errorMessage = getQueryStringParameter(url: navigationResponse.response.url?.absoluteString ?? "", param: "e") {
                           Constants.showMessage(msg: errorMessage)
                       } else {
                           Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                       }
       
                       webView.isHidden = true
                       self.view.sendSubviewToBack(webView)
                       self.view.isUserInteractionEnabled = true
                       self.loading.stopAnimating()
                   }
               }
        decisionHandler(.allow)
        }

    }
    
//    func webView(_ webView: WKWebView, shouldStartLoadWith request: URLRequest, navigationType: WKNavigationType.Type) -> Bool {
//        if let url_ = request.url?.absoluteString {
//
//            if url_.range(of: "postauth-service-end") != nil {
//                Constants.showMessage(msg: "Cancelado, espere un momento")
//            }
//
//            if url_.range(of: "postauth-service-error") != nil {
//
//                if let errorMessage = getQueryStringParameter(url: request.url?.absoluteString ?? "", param: "e") {
//                    Constants.showMessage(msg: errorMessage)
//                } else {
//                    Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
//                }
//
//                self.webview?.isHidden = true
//                self.view.sendSubviewToBack(self.webview!)
//                self.view.isUserInteractionEnabled = true
//                self.loading.stopAnimating()
//            }
//        }
//
//        return true
//    }
    
    
