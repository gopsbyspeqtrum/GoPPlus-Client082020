import UIKit

class Activate: UIViewController {

    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    struct ResendStruct:Codable {
        let id:Int
    }
    
    struct ActivateStruct:Codable {
        let id:Int 
        let token:String
    }
    
    var email:String = ""
    var id:Int = 0
    var activationSuccess:Bool = false
    var fromLogin:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupToolbar()
        self.loading.stopAnimating()
    }
    
    private func setupToolbar() {
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x:0, y:0, width: self.view.frame.width, height: 30))
        let flexspace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton:UIBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolbar.setItems([flexspace, doneButton], animated: false)
        toolbar.sizeToFit()
        
        self.codeField.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }

    @IBAction func dismissController(_ sender: Any) {
        self.activationSuccess = false
        
        if (self.fromLogin == true) {
            self.performSegue(withIdentifier: "unwindLoginActivation", sender: self)
        } else {
            self.performSegue(withIdentifier: "unwindSignup", sender: self)
        }
    }
    
    @IBAction func doActivate(_ sender: Any) {
        let code = self.codeField.text!
        let codePlaceholder = self.codeField.placeholder!
        
        var message:String = ""
        
        if !Validator.isRequired(text: code) {
            message = Validator.replaceMessage(name: codePlaceholder, value: code, message: Validator.requiredError)
        }
        
        if message.isEmpty {
            let activate = ActivateStruct(id: self.id, token: code)
            
            guard let upload = try? JSONEncoder().encode(activate) else {
                Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                return
            }
            
            self.loading.startAnimating()
            self.view.isUserInteractionEnabled = false
            
            Constants.postRequest(endpoint: Constants.APIEndpoint.client + "activate", bodyData: upload) { (result) in
                
                DispatchQueue.main.async {
                    self.loading.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    
                    if result == nil {
                        Constants.showMessage(msg: "Algo salió mal, intenta nuevamente")
                        return
                    }
                    
                    guard let result = result else {
                        Constants.showMessage(msg: "Algo salió mal, intenta nuevamente")
                        return
                    }
                    
                    if let status = result["status"] as? Bool {
                        
                        if status {
                            Constants.showPrompt(msg: "Tu cuenta está activada. Ingresa tu correo y contraseña registrados para iniciar sesión.", completion: { (clicked) in
                                self.activationSuccess = true
                                
                                if (self.fromLogin == true) {
                                    self.performSegue(withIdentifier: "unwindLoginActivation", sender: self)
                                } else {
                                    self.performSegue(withIdentifier: "unwindSignup", sender: self)
                                }
                            })
                        } else {
                            Constants.showMessage(msg: "Verifica el código ingresado, es sensible a mayúsculas y minúsculas. No debe contener espacios. Ó solicita el reenvío del código de activación.")
                        }
                    }
                }
            }
        } else {
            Constants.showMessage(msg: message)
        }
    }
    
    @IBAction func doResend(_ sender: Any) {
        let resend = ResendStruct(id: self.id)
        guard let upload = try? JSONEncoder().encode(resend) else {
            return
        }
        
        self.loading.startAnimating()
        self.view.isUserInteractionEnabled = false
        
        Constants.postRequest(endpoint: Constants.APIEndpoint.client + "resend-code", bodyData: upload) { (result) in
            
            DispatchQueue.main.async {
                self.loading.stopAnimating()
                self.view.isUserInteractionEnabled = true
                
                if result == nil {
                    Constants.showMessage(msg: "Algo salió mal, intenta nuevamente")
                    return
                }
                
                guard let result = result else {
                    Constants.showMessage(msg: "Algo salió mal, intenta nuevamente")
                    return
                }
                
                if let message = result["message"] as? String {
                    Constants.showMessage(msg: message)
                }
            }
        }
    }
}
