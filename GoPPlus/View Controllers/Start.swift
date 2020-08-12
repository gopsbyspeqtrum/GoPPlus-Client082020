import UIKit
import CoreLocation

class Start: UIViewController {

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var onRequestContainer: UIView!
    @IBOutlet weak var sidebarContainer: UIView!
    @IBOutlet weak var onBoardContainer: UIView!
    @IBOutlet weak var waitContainer: UIView!
    @IBOutlet weak var navigationBarLogo: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var versionLabel: UILabel!
    
    var isSideBarHidden:Bool =  true
    @IBOutlet weak var hiddenSidebarConstraint: NSLayoutConstraint!
    @IBOutlet weak var visibleSidebarConstraint: NSLayoutConstraint!
    
    var OnRequestController:OnRequest?
    var OnBoardController:OnBoard?
    var OnWaitController:Wait?
    
    struct DeviceToken:Codable {
        let id:Int
        let token:String
    }
    
    struct ResultService:Codable {
        let status:Bool
        let message:String
        let data:Constants.ServiceData?
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.getVersionNumber()
        self.showWait()
        self.getActiveServiceLoop(seconds: 0)
        self.getUnratedServiceLoop(seconds: 0)
        self.remoteSync()
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "containerOnRequest" {
            print("onRequest segue")
            self.OnRequestController = segue.destination as? OnRequest
        } else if segue.identifier == "containerOnBoard" {
            print("onBoard segue")
            self.OnBoardController = segue.destination as? OnBoard
        } else if segue.identifier == "containerOnWait" {
            print("onWait segue")
            self.OnWaitController = segue.destination as? Wait
        } else {
            self.toggleSidebar(self)
        }
    }
    
    @IBAction func toggleSidebar(_ sender: Any) {
        if self.isSideBarHidden {
            self.hiddenSidebarConstraint.isActive = false
            self.visibleSidebarConstraint.isActive = true
        } else {
            self.hiddenSidebarConstraint.isActive = true
            self.visibleSidebarConstraint.isActive = false
        }
        
        UIView.animate(withDuration: 0.3){
            self.view.layoutIfNeeded()
        }
        
        self.isSideBarHidden = !self.isSideBarHidden
    }
    
    @IBAction func closeSession(_ sender: Any) {
        Constants.deleteStored()
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func openServices(_ sender: Any) {
        self.toggleSidebar(self)
    }
    
    @IBAction func openTerms(_ sender: Any) {
        self.toggleSidebar(self)
        
        if let data = UserDefaults.standard.value(forKey:"settings") as? Data {
            guard let settings = try? PropertyListDecoder().decode([Constants.Settings].self, from: data) else {
                print("Error getting settings")
                return
            }
            
            for s in settings {
                if s.k == "urlTerminosCondiciones" {
                    guard let url = URL(string: s.v) else {
                        return
                    }
                    
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            }
        }
    }
    
    func loadUserImage() {
        let fbid = Constants.getStringStored(key: Constants.DBKeys.user + "fbid")
        let usid = Constants.getIntStored(key: Constants.DBKeys.user + "id")
        var profileImageUrl:String = "";
        var parameters:[String:String] = [:]
        
        if fbid.isEmpty {
            profileImageUrl = Constants.APIEndpoint.client + "profile-image"
            parameters = ["id": String(usid)];
        } else {
            profileImageUrl = "https://graph.facebook.com/" + fbid + "/picture"
            parameters = ["type": "normal", "height": "100", "width": "100"]
        }
        
        let urlComponent = NSURLComponents(string: profileImageUrl)!
        
        urlComponent.queryItems = parameters.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: urlComponent.url!)
            
            DispatchQueue.main.async {
                if data != nil {
                    self.userImage.image = UIImage(data: data!)
                }
                
                self.userNameLabel.text = Constants.getStringStored(key: Constants.DBKeys.user + "nombre")
                self.userImage.layer.borderWidth = 1
                self.userImage.layer.borderColor = UIColor.gray.cgColor
                self.userImage.layer.cornerRadius = self.userImage.frame.width / 2
                self.userImage.clipsToBounds = true
                self.userImage.layer.masksToBounds = true
            }
        }
    }
    
    private func showWait() {
        DispatchQueue.main.async {
            if (self.waitContainer.isHidden) {
                self.onBoardContainer.isHidden = true
                self.onRequestContainer.isHidden = true
                self.waitContainer.isHidden = false
                self.hideNavigationBar()
            }
        }
    }
    
    private func showOnRequest() {
        DispatchQueue.main.async {
            if (self.onRequestContainer.isHidden) {
                self.onBoardContainer.isHidden = true
                self.waitContainer.isHidden = true
                self.onRequestContainer.isHidden = false
                self.showNavigationBar()
            }
        }
    }
    
    private func showOnBoard() {
        DispatchQueue.main.async {
            if (self.onBoardContainer.isHidden) {
                self.onRequestContainer.isHidden = true
                self.waitContainer.isHidden = true
                self.onBoardContainer.isHidden = false
                self.showNavigationBar()
            }
        }
    }
    
    private func hideNavigationBar() {
        self.navigationBar.isHidden = true
        self.navigationBarLogo.isHidden = true
    }
    
    private func showNavigationBar() {
        self.navigationBar.isHidden = false
        self.navigationBarLogo.isHidden = false
    }
    
    private func getUnratedServiceLoop(seconds:Int) {
        let userId:Int = Constants.getIntStored(key: Constants.DBKeys.user + "id")
        
        if userId == 0 {
            print("Missing user id")
            self.performSegue(withIdentifier: "unwinStartView", sender: self)
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(seconds), execute: {
            Constants.getRequest(endpoint: Constants.APIEndpoint.client + "finished", parameters: ["id": String(userId)], completion: { (result) in
                let delaySeconds:Int = 15
                
                guard let result = result else {
                    self.getUnratedServiceLoop(seconds: delaySeconds)
                    return
                }
                
                do {
                    struct ResultDefault:Codable {
                        let status:Bool
                        let message:String
                        let data:Constants.UnratedService?
                    }
                    
                    let jsonData   = try JSONSerialization.data(withJSONObject: result, options: [])
                    let resultData = try JSONDecoder().decode(ResultDefault.self, from: jsonData)
                    let default_service:Constants.UnratedService = Constants.UnratedService(id: 0, conductor: 0, nombre_conductor: "", fecha: "", precio: 0)
                    
                    if resultData.status == true {
                        if self.OnRequestController != nil {
                            self.OnRequestController?.newUnratedService(service: resultData.data ?? default_service);
                        }
                    }
                } catch {
                    print("Error [finished]")
                }
                
                self.getUnratedServiceLoop(seconds: delaySeconds)
            })
        })
    }
    
    private func getSettingsLoop() {
        if Constants.getIntStored(key: Constants.DBKeys.user + "id") == 0 {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(60), execute: {
            self.remoteSync()
        })
    }
    
    private func getActiveServiceLoop(seconds:Int) {
        
        let userId:Int = Constants.getIntStored(key: Constants.DBKeys.user + "id")
        
        if userId == 0 {
            print("Missing user id")
            self.performSegue(withIdentifier: "unwinStartView", sender: self)
            return
        }
        
        
        loadUserImage()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(seconds) ) {
            Constants.getRequest(endpoint: Constants.APIEndpoint.client + "get-service", parameters: ["id": String(userId)], completion: { (result) in
                var delaySeconds:Int = 10
                
                guard let result = result else {
                    self.getActiveServiceLoop(seconds: delaySeconds)
                    return
                }
                
                if result["logout"] != nil {
                    Constants.deleteStored()
                    self.performSegue(withIdentifier: "unwinStartView", sender: self)
                    return
                }
                
                do {
                    let jsonData   = try JSONSerialization.data(withJSONObject: result, options: [])
                    let resultData = try JSONDecoder().decode(ResultService.self, from: jsonData)
                    
                    if resultData.status {
                        if resultData.data != nil  {
                            if resultData.data?.estatus_reserva == 3 {
                                if self.OnWaitController != nil {
                                    self.OnWaitController?.statusLabelValue = "Buscando la unidad más cercana"
                                    self.OnWaitController?.setServiceData(data: resultData.data!)
                                }
                                
                                if self.OnBoardController != nil {
                                    self.OnBoardController?.firstCentered = false
                                }
                                
                                self.showWait()
                            } else {
                                
                                if self.OnWaitController != nil {
                                    self.OnWaitController?.hideAlert()
                                }
                                
                                if self.OnBoardController != nil {
                                    self.OnBoardController?.setServiceData(data: resultData.data!)
                                }
                                
                                self.showOnBoard()
                            }
                        } else {
                            self.showWait()
                        }
                        
                        delaySeconds = 15
                    } else {
                        self.showOnRequest()
                        
                        if self.OnRequestController != nil {
                            self.OnRequestController?.hideLoading()
                        }
                        
                        if self.OnWaitController != nil {
                            self.OnWaitController?.hideAlert()
                        }
                        
                        if self.OnBoardController != nil {
                            self.OnBoardController?.firstCentered = false
                        }
                    }
                } catch {
                    print("error")
                }
                
                self.getActiveServiceLoop(seconds: delaySeconds)
            })
        }
    }
    
    private func remoteSync() {
        
        let userId:Int = Constants.getIntStored(key: Constants.DBKeys.user + "id")
        
        if userId == 0 {
            print("Missing user id")
            self.performSegue(withIdentifier: "unwinStartView", sender: self)
            return
        }
        
        Constants.getRequest(endpoint: Constants.APIEndpoint.client + "sync", parameters: nil) { (result) in
            guard let result = result else {
                self.getSettingsLoop()
                return
            }
            
            do {
                if let vehiclesByType = result["vehiclesByType"] {
                    guard let vehiclesArray = try? JSONSerialization.data(withJSONObject:vehiclesByType) else {
                        print("Error getting array")
                        return
                    }
                    
                    let vehicles = try JSONDecoder().decode([Constants.VehicleByType].self, from: vehiclesArray)
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(vehicles), forKey: "vehiclesByType")
                }
                
                if let settings = result["settings"] {
                    guard let settingsArray = try? JSONSerialization.data(withJSONObject:settings) else {
                        print("Error getting array")
                        return
                    }
                    
                    let settings_ = try JSONDecoder().decode([Constants.Settings].self, from: settingsArray)
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(settings_), forKey: "settings")
                }
            } catch {
                print(error)
                print("Error while getting vehicles by type and settings")
            }
            
            
            self.syncToken()
            self.getSettingsLoop()
        }
    }
    
    func syncToken() {
        if (Constants.existStored(key: "deviceToken")) {
            let dt = DeviceToken(id: Constants.getIntStored(key: Constants.DBKeys.user + "id"), token: Constants.getStringStored(key: "deviceToken"))
            
            guard let upload = try? JSONEncoder().encode(dt) else {
                print("Algo salió mal")
                return
            }
            
            Constants.postRequest(endpoint: Constants.APIEndpoint.client + "token", bodyData: upload) { response in
                
            }
        }
    }
    
    func getVersionNumber() {
        let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject
        self.versionLabel.text = self.versionLabel.text! + " " + (nsObject as! String)
    }
}
