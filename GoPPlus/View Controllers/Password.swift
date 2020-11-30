import UIKit

class Password: UIViewController {
    
    @IBOutlet weak var currentPasswordField: UITextField!
    @IBOutlet weak var newPasswordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loading.stopAnimating()
        self.setupToolbar()
    }

    @IBAction func dismissController(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setupToolbar() {
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x:0, y:0, width: self.view.frame.width, height: 30))
        let flexspace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton:UIBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolbar.setItems([flexspace, doneButton], animated: false)
        toolbar.sizeToFit()
        
        self.currentPasswordField.inputAccessoryView = toolbar
        self.newPasswordField.inputAccessoryView = toolbar
        self.confirmPasswordField.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    @IBAction func doUpdatePassword(_ sender: Any) {
        let pass1 = self.currentPasswordField.text!
        let pass2  = self.newPasswordField.text!
        let pass3  = self.confirmPasswordField.text!
        
        let ph1 = self.currentPasswordField.placeholder!
        let ph2 = self.newPasswordField.placeholder!
        let ph3 = self.confirmPasswordField.placeholder!
        
        let lastPass = Constants.getStringStored(key: Constants.DBKeys.user + "contrasena")
        
         var message = ""
        
        if !Validator.isRequired(text: pass1) {
            message += "\n" + Validator.replaceMessage(name: ph1, value: pass1, message: Validator.requiredError)
        }
        
        if !Validator.isRequired(text: pass2) {
            message += "\n" + Validator.replaceMessage(name: ph2, value: pass2, message: Validator.requiredError)
        }
        
        if !Validator.isRequired(text: pass3) {
            message += "\n" + Validator.replaceMessage(name: ph3, value: pass3, message: Validator.requiredError)
        }
        
        if !Validator.isPassword(password: pass1) {
            message += "\n" + Validator.replaceMessage(name: ph1, value: pass1, message: Validator.passwordError)
        }
        
        if !Validator.isPassword(password: pass2) {
            message += "\n" + Validator.replaceMessage(name: ph2, value: pass2, message: Validator.passwordError)
        }
        
        if !Validator.isPassword(password: pass3) {
            message += "\n" + Validator.replaceMessage(name: ph3, value: pass3, message: Validator.passwordError)
        }
        
        if  !pass2.elementsEqual(pass3) {
            message += "\n" + ph2 + " no coincide con " + ph3
        }
        
        if pass1.elementsEqual(pass2) {
            message += "\n" + ph1 + " es igual que " + ph2
        }
        
        if !pass1.md5().elementsEqual(lastPass) {
            message += "\n" + ph1 + " es incorrecta "
        }
        
        
        if message.isEmpty {
            
            struct PassStruct:Codable {
                let id:Int
                let password:String
                let newpassword:String
            }
            
            let newPass = PassStruct(id: Constants.getIntStored(key: Constants.DBKeys.user + "id"), password: pass1.md5(), newpassword: pass2.md5())
            
            guard let uploadData = try? JSONEncoder().encode(newPass) else {
                Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                return
            }
            
            self.loading.startAnimating()
            self.view.isUserInteractionEnabled = false
            
            Constants.postRequest(endpoint: Constants.APIEndpoint.client + "password", bodyData: uploadData) { (response) in
                
                DispatchQueue.main.async {
                    self.loading.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    
                    if response == nil {
                        Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                        return;
                    }
                    
                    guard let response = response else {
                        Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                        return;
                    }
                    
                    if let status = response["status"] as? Bool {
                        
                        if (status) {
                            Constants.store(key: Constants.DBKeys.user + "contrasena", value: pass2.md5())
                        }
                        self.dismiss(animated: true) {
                            Constants.showMessage(msg: "Contraseña actualizada. La próxima vez que inicies sesión, deberás usar tu nueva contraseña.")
                        }
                    }
                }
            }
        } else {
            Constants.showMessage(msg: message)
        }
    }
    
}
