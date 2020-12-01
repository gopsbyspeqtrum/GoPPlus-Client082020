import UIKit

class Login: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passField: UITextField!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    struct Credentials: Codable {
        let email: String
        let password: String
    }
    
    struct AppUser:Codable {
        let status:Bool
        let message:String
        let id:Int?
        let fbid:String?
        let nombre:String?
        let telefono:String?
        let esActivo:Int?
        let afiliado:Int?
        let codigo:String?
        let cliente:Int?
        let fechac:String?
    }
    
    var userEmail:String = ""
    var userId:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupToolbar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.verifyUserExists()
    }

    @IBAction func doLogin(_ sender: Any) {
        self.view.endEditing(true)
        let email = self.emailField.text!
        let pass  = self.passField.text!
        let emailPlaceholder = self.emailField.placeholder!
        let passPlaceholder = self.passField.placeholder!
        var message = ""
        
        if !Validator.isRequired(text: email) {
            message += "\n" + Validator.replaceMessage(name: emailPlaceholder, value: email, message: Validator.requiredError)
        }
        if !Validator.isEmail(email: email) {
            message += "\n" + Validator.replaceMessage(name: emailPlaceholder, value: email, message: Validator.emailError)
        }
        if !Validator.isRequired(text: pass) {
            message += "\n" + Validator.replaceMessage(name: passPlaceholder, value: pass, message: Validator.requiredError)
        }
        if !Validator.isPassword(password: pass) {
            message += "\n" + Validator.replaceMessage(name: passPlaceholder, value: pass, message: Validator.passwordErrorLogin)
        }
        if message.isEmpty {
            self.loginRequest(email: email, pass: pass)
        } else {
            Constants.showMessage(msg: message)
        }
    }
    

    private func loginRequest(email: String, pass: String) {
        let credential = Credentials(email: email, password: pass.md5())
        guard let uploadData = try? JSONEncoder().encode(credential) else {
            Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
            return
        }
        self.activity.startAnimating()
        self.view.isUserInteractionEnabled = false
        Constants.postRequest(endpoint: Constants.APIEndpoint.client + "login", bodyData: uploadData) { response in
            DispatchQueue.main.async {
                self.activity.stopAnimating()
                self.view.isUserInteractionEnabled = true
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: response as Any, options: [])
                    let result =  try JSONDecoder().decode(AppUser.self, from: jsonData)
                    if result.status == true {
                        if result.esActivo == 1 {
                            Constants.store(key: Constants.DBKeys.user + "correo", value: self.emailField.text!)
                            Constants.storeInt(key: Constants.DBKeys.user + "id", value: result.id ?? 0)
                            Constants.storeInt(key: Constants.DBKeys.user + "clienteid", value: result.cliente ?? 0)
                            Constants.storeInt(key: Constants.DBKeys.user + "esActivo", value: result.esActivo ?? 0)
                            Constants.storeInt(key: Constants.DBKeys.user + "afiliado", value: result.afiliado ?? 0)
                            Constants.store(key: Constants.DBKeys.user + "fechac", value: result.fechac ?? "")
                            Constants.store(key: Constants.DBKeys.user + "fbid", value: result.fbid ?? "")
                            Constants.store(key: Constants.DBKeys.user + "nombre", value: result.nombre ?? "")
                            Constants.store(key: Constants.DBKeys.user + "telefono", value: result.telefono ?? "")
                            Constants.store(key: Constants.DBKeys.user + "codigo", value: result.codigo ?? "")
                            Constants.store(key: Constants.DBKeys.user + "contrasena", value: pass.md5())
                            
                            self.emailField.text = ""
                            self.passField.text = ""
                            
                            self.updateAppId(id: result.id ?? 0)
                            
                        } else {
                            self.userEmail = self.emailField.text!
                            self.userId = result.id ?? 0
                            self.performSegue(withIdentifier: "activatefromloginsegue", sender: self)
                            Constants.showMessage(msg: "Abre activación")
                        }
                    } else {
                        Constants.showMessage(msg: result.message)
                    }
                    
                    
                } catch {
                    Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                    return;
                }
            }
        }
    }
    
    private func updateAppId(id:Int) {
        self.activity.startAnimating()
        
        Constants.store(key: "appid", value: Constants.toEncrypt(text: UUID().uuidString))
        
        struct AppIDStruct:Codable {
            let id:Int
            let appid:String
        }
        
        let appid = AppIDStruct(id: id, appid: Constants.getStringStored(key: "appid"))
        
        guard let upload = try? JSONEncoder().encode(appid) else {
            print("Algo salió mal")
            return
        }
        
        Constants.postRequest(endpoint: Constants.APIEndpoint.client + "set-appid", bodyData: upload) { response in
            DispatchQueue.main.async(execute: {
                self.activity.stopAnimating()
                self.openStartController()
            })
        }
    }
    
    private func openStartController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let startController = storyboard.instantiateViewController(withIdentifier: "gopplusview") as! Start
        startController.modalPresentationStyle = .fullScreen
        self.present(startController, animated: false, completion: nil)
    }
    
    private func verifyUserExists() {
        if Constants.existStored(key: "user.id") {
            self.openStartController()
        }
        
        self.activity.stopAnimating()
    }
    
    private func setupToolbar() {
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x:0, y:0, width: self.view.frame.width, height: 30))
        let flexspace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton:UIBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolbar.setItems([flexspace, doneButton], animated: false)
        toolbar.sizeToFit()
        
        self.emailField.inputAccessoryView = toolbar
        self.passField.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "activatefromloginsegue" {
            if let ac = segue.destination as? Activate {
                ac.email = userEmail
                ac.id = userId
                ac.fromLogin = true
            }
        }
    }
    
    @IBAction func unwindLoginActivation(_ sender: UIStoryboardSegue) {
        if let ac = sender.source as? Activate {
            if ac.activationSuccess {
                self.doLogin(self)
            }
        }
    }
    
    
    @IBAction func unwinStartView(_ sender: UIStoryboardSegue) {
        
    }
    
    
}
