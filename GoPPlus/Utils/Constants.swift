import UIKit
import SystemConfiguration
import Foundation

class Constants: NSObject {
    
    static let APIKEY:String = "AIzaSyAnLqd2gzuXQxq_msNZSDAHxn7PTNN7b7Q" 
    static let SECRET:String = "g0sp3qtrUm_"
    
    struct APIEndpoint {
        static let client : String   =  "https://goclientx.goppluswebx.com/"
        static let driver : String   =  "https://godriverx.goppluswebx.com/"
        static let payment : String  =  "https://gopspayx.goppluswebx.com/"
        static let admin : String    =  "https://gopplusweb.goppluswebx.com/"
    }
    
    struct VehicleByType:Codable {
        let id: Int
        let nombre: String
        let minima: Double
        let precio_min: Double
        let precio_base: Double
        let precio_km: Double
        let precio_minimo: Double
        let unselected: String
        let selected: String
    }
    
    struct Settings:Codable {
        let k: String
        let v: String
    }
    
    struct NearVehicle:Codable {
        let ID_Vehiculo_Conductor: Int
        let latitude: Double
        let longitude: Double
        let dist:Double
    }
    
    struct SDAddress:Codable {
        var latitude: Double
        var longitude: Double
        var address: String
    }
    
    struct PromoTypeCode:Codable {
        let id: String
        let typecode:String
        let type:String
    }
    
    struct CreditCardItem:Codable {
        let Id: Int
        let Numero: String
    }
    
    struct UnratedService:Codable {
        let id:Int
        let conductor:Int
        let nombre_conductor:String
        let fecha:String
        let precio:Double
        
    }
    
    struct DBKeys {
        static let user: String = "user."
    }
    
    struct ServiceData:Codable {
        let destino:String
        let estatus_reserva:Int
        let estatus_reserva_nombre:String
        let estatus_vehiculo:Int
        let fecha_domicilio:String
        let id:Int
        let id_afiliado:Int
        let id_conductor:Int
        let idd:Int?
        let km:Double
        let lat_destino:Double
        let lat_origen:Double
        let lng_destino:Double
        let lng_origen:Double
        let origen:String
        let tipo_vehiculo:String
        let vc_id:Int
        let placas:String?
        let modelo:String?
        let marca:String?
        let color:String?
        let permiso:String?
        let calificacion:Double?
        let nombre:String?
        let lat:Double?
        let lng:Double?
    }
    
    static func showMessage(msg: String) {
        let alert = UIAlertController(title: "GoPPlus", message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
    }
    
    static func showConfirmation(msg: String, completion: @escaping(_ acceptedAction: Bool ) -> ()){
        let alert = UIAlertController(title: "GoPPlus", message: msg, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Aceptar", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
            completion(true)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) in
            completion(false)
        }))
        
        UIApplication.topViewController()?.present(alert, animated: true, completion: {
            //print("Alert displayed")
        })
    }
    
    static func showConfirmationWithButtonTitle(msg: String, acceptTitle: String, cancelTitle: String, completion: @escaping(_ acceptedAction: Bool ) -> ()){
        let alert = UIAlertController(title: "GoPPlus", message: msg, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: acceptTitle, style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
            completion(true)
        }))
        
        alert.addAction(UIAlertAction(title: cancelTitle, style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) in
            completion(false)
        }))
        
        UIApplication.topViewController()?.present(alert, animated: true, completion: {
            //print("Alert displayed")
        })
    }
    
    static func showPrompt(msg: String, completion: @escaping(_ acceptedAction: Bool ) -> ()){
        let alert = UIAlertController(title: "GoPPlus", message: msg, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
            completion(true)
        }))
        
        UIApplication.topViewController()?.present(alert, animated: true, completion: {
            //print("Alert displayed")
        })
    }
    
    static func getFromSetting(key: String) -> String {
        var value = ""
        
        if let data = UserDefaults.standard.value(forKey:"settings") as? Data {
            guard let settings = try? PropertyListDecoder().decode([Constants.Settings].self, from: data) else {
                print("Error getting settings")
                return value
            }
            
            for s in settings {
                if s.k == key {
                    value = s.v
                }
            }
        }
        
        return value
    }
    
    static func toEncrypt(text: String) -> String {
        return text.sha256().uppercased()
    }
    
    static func toEncrypt64(text: String) -> String {
        let complete = text + self.SECRET
        return Data(complete.utf8).base64EncodedString()
    }
    
    static func store(key: String, value: String) {
        UserDefaults.standard.setValue(value, forKey: key)
    }
    
    static func storeInt(key: String, value: Int) {
        UserDefaults.standard.set(value, forKey: key)
    }

    static func existStored(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    static func getStringStored(key: String) -> String {
        return UserDefaults.standard.string(forKey: key)!
    }
    
    static func getIntStored(key: String) -> Int {
        return UserDefaults.standard.integer(forKey: key)
    }
    
    static func deleteStored() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
    
    static func getDirectionsMatrix(parameters: [String: String]?, completion: @escaping ([String:Any]?) -> ()) {
        let urlComponent = NSURLComponents(string: "https://maps.googleapis.com/maps/api/directions/json")!
        
        if parameters != nil {
            if let parameters = parameters {
                urlComponent.queryItems = parameters.map { (key, value) in
                    URLQueryItem(name: key, value: value)
                }
            }
        }
        
        var request = URLRequest(url: urlComponent.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let data = data
            
            if let error = error {
                print("error: \(error)")
                completion(nil)
                return;
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("server error")
                completion(nil)
                return
            }
            
            guard let content = data else {
                completion(nil)
                return
            }
            
            if let json = (((try? JSONSerialization.jsonObject(with: content, options: []) as? [String: Any]) as [String : Any]??)) {
                completion(json)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
        
    }
    
    static func isConnectedToNetwork() -> Bool {
        let reachability = SCNetworkReachabilityCreateWithName(nil, "www.google.com")
        var flags = SCNetworkReachabilityFlags()
        
        SCNetworkReachabilityGetFlags(reachability!, &flags)
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
    
    static func getAutocomplete(parameters: [String: String]?, completion: @escaping ([String:Any]?) -> ()) {
        let urlComponent = NSURLComponents(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json")!
        
        if parameters != nil {
            if let parameters = parameters {
                urlComponent.queryItems = parameters.map { (key, value) in
                    URLQueryItem(name: key, value: value)
                }
            }
        }
        
        var request = URLRequest(url: urlComponent.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let data = data
            
            if let error = error {
                print("error: \(error)")
                completion(nil)
                return;
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("server error")
                completion(nil)
                return
            }
            
            guard let content = data else {
                completion(nil)
                return
            }
            
            if let json = (((try? JSONSerialization.jsonObject(with: content, options: []) as? [String: Any]) as [String : Any]??)) {
                completion(json)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
        
    }
    
    static func getPlaceId(parameters: [String: String]?, completion: @escaping ([String:Any]?) -> ()) {
        let urlComponent = NSURLComponents(string: "https://maps.googleapis.com/maps/api/place/details/json")!
        
        if parameters != nil {
            if let parameters = parameters {
                urlComponent.queryItems = parameters.map { (key, value) in
                    URLQueryItem(name: key, value: value)
                }
            }
        }
        
        var request = URLRequest(url: urlComponent.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let data = data
            
            if let error = error {
                print("error: \(error)")
                completion(nil)
                return;
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("server error")
                completion(nil)
                return
            }
            
            guard let content = data else {
                completion(nil)
                return
            }
            
            if let json = (((try? JSONSerialization.jsonObject(with: content, options: []) as? [String: Any]) as [String : Any]??)) {
                completion(json)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
        
    }
    
    static func getDistanceMatrix(parameters: [String: String]?, completion: @escaping ([String:Any]?) -> ()) {
        let urlComponent = NSURLComponents(string: "https://maps.googleapis.com/maps/api/distancematrix/json")!
        
        if parameters != nil {
            if let parameters = parameters {
                urlComponent.queryItems = parameters.map { (key, value) in
                    URLQueryItem(name: key, value: value)
                }
            }
        }
        
        var request = URLRequest(url: urlComponent.url!)
        
        print("=== GET ===")
        print(urlComponent.url!)
        
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let data = data
            
            if let error = error {
                print("error: \(error)")
                completion(nil)
                return;
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("server error")
                completion(nil)
                return
            }
            
            guard let content = data else {
                completion(nil)
                return
            }
            
            print(content)
            
            if let json = (((try? JSONSerialization.jsonObject(with: content, options: []) as? [String: Any]) as [String : Any]??)) {
                completion(json)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    static func getHeaderValue(key:String) -> String{
        
        if (existStored(key: key)) {
            return getStringStored(key: key)
        }
        
        return ""
    }
    
    static func getRequest(endpoint: String, parameters: [String: String]?, completion: @escaping ([String:Any]?) -> ()) {
        
        if (!isConnectedToNetwork()) {
            completion(["message": "No tienes conexión a internet", "status": false])
            return
        }
        
        
        let urlComponent = NSURLComponents(string: endpoint)!
        
        if parameters != nil {
            if let parameters = parameters {
                urlComponent.queryItems = parameters.map { (key, value) in
                    URLQueryItem(name: key, value: value)
                }
            }
        }
        
        var request = URLRequest(url: urlComponent.url!)
        
        //print("=== GET ===")
        //print(urlComponent.url!)
        
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if (existStored(key: "appid")) {
            let appid:String = getStringStored(key: "appid")
            request.setValue(appid, forHTTPHeaderField: "appid")
        }
        
        if (existStored(key: "user.id")) {
            let userid:String = toEncrypt(text: String(getIntStored(key: "user.id")))
            request.setValue(userid , forHTTPHeaderField: "userid")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let data = data
            
            if let error = error {
                print("error: \(error)")
                completion(nil)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(nil)
                return
            }
            
            if !(200...299).contains(response.statusCode) {
                if response.statusCode == 503 {
                    completion(["logout": true])
                    return
                }
                
                completion(nil)
                return
            }
            
            guard let content = data else {
                completion(nil)
                return
            }
            
            if let dataString = String(data: content, encoding: .utf8) {
                print("getRequest response: \(dataString)")
            }
            
            if let json = (((try? JSONSerialization.jsonObject(with: content, options: []) as? [String: Any]) as [String : Any]??)) {
                completion(json)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    static func postRequest(endpoint: String, bodyData: Data?, completion: @escaping ([String:Any]?) -> () ) {
        if (!isConnectedToNetwork()) {
            completion(["message": "No tienes conexión a internet", "status": false])
            return
        }
        
        let url = URL(string: endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        //print("=== POST ===")
        //print(endpoint)
        
        if (existStored(key: "appid")) {
            let appid:String = getStringStored(key: "appid")
            request.setValue(appid, forHTTPHeaderField: "appid")
        }
        
        if (existStored(key: "user.id")) {
            let userid = toEncrypt(text: String(getIntStored(key: "user.id")))
            request.setValue(userid, forHTTPHeaderField: "userid")
        }
        
        let task = URLSession.shared.uploadTask(with: request, from: bodyData) { data, response, error in
            
            let data = data
            
            if let error = error {
                print("error: \(error)")
                completion(nil)
                return;
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("server error")
                completion(nil)
                return
            }
            
            guard let content = data else {
                completion(nil)
                return
            }
            
            if let dataString = String(data: content, encoding: .utf8) {
                print("postRequest response: \(dataString)")
            }
            
            if let json = (((try? JSONSerialization.jsonObject(with: content, options: []) as? [String: Any]) as [String : Any]??)) {
                completion(json)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    
}
