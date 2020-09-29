import UIKit

class PasswordReplace: UIViewController {
    var email:String = ""
    var passwordUpdated:Bool = false
    
    struct Restore: Codable {
        let email: String
        let token: String
        let pass: String
    }
    
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        print("H")
        super.viewDidLoad()
        self.loading.stopAnimating()
        self.setupToolbar()
    }
    
    private func setupToolbar() {
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x:0, y:0, width: self.view.frame.width, height: 30))
        let flexspace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton:UIBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolbar.setItems([flexspace, doneButton], animated: false)
        toolbar.sizeToFit()
        
        self.codeField.inputAccessoryView = toolbar
        self.passwordField.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    @IBAction func dismissController(_ sender: Any) {
        passwordUpdated = false
        performSegue(withIdentifier: "unwind", sender: self)
    }
    
    @IBAction func updatePassword(_ sender: Any) {
        let code = self.codeField.text!
        let pass = self.passwordField.text!
        
        let codePlaceholder = self.codeField.placeholder!
        let passPlaceholder = self.passwordField.placeholder!
        
        var message = ""
        
        if !Validator.isRequired(text: code) {
            message += Validator.replaceMessage(name: codePlaceholder, value: code, message: Validator.requiredError)
        }
        
        if code.count != 5 {
            message += "El campo " + codePlaceholder + " debe ser igual a cinco caracteres."
        }
        
        if !Validator.isRequired(text: pass) {
            message += Validator.replaceMessage(name: passPlaceholder, value: pass, message: Validator.requiredError)
        }
        
        if !Validator.isPassword(password: pass) {
            message += Validator.replaceMessage(name: passPlaceholder, value: pass, message: Validator.passwordError)
        }
        
        if message.isEmpty {
            
            let dataSend = Restore(email: email, token: code, pass: pass.md5())
            
            guard let upload = try? JSONEncoder().encode(dataSend) else {
                Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                return
            }
            
            self.loading.startAnimating()
            self.view.isUserInteractionEnabled = false
            
            Constants.postRequest(endpoint: Constants.APIEndpoint.client + "recover", bodyData: upload) { response in
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
                    
                    if let status = response["status"] as? Bool,
                       let message = response["message"] as? String {
                        
                        if status {
                            Constants.showPrompt(msg: message, completion: { (accepted) in
                                self.passwordUpdated = true
                                self.performSegue(withIdentifier: "unwind", sender: self)
                            })
                        } else {
                            Constants.showMessage(msg: message)
                        }
                    }
                }
            }
        } else {
            Constants.showMessage(msg: message)
        }
    }
}
