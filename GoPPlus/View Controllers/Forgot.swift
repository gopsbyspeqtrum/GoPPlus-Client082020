import UIKit

class Forgot: UIViewController {

    var email: String!
    var emailSent:Bool = false
    
    struct DataSend: Codable {
        let email: String
    }
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        print("E")
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
        
        self.emailField.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }

    @IBAction func dismissController(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doSendAuthCode(_ sender: Any) {
        email = self.emailField.text!
        
        let placeholder = self.emailField.placeholder!
        var message = ""
        
        if !Validator.isRequired(text: email) {
            message += "\n" + Validator.requiredError
        }
        
        if !Validator.isEmail(email: email) {
            message += "\n" + Validator.emailError
        }
        
        if !message.isEmpty {
            Constants.showMessage(msg: Validator.replaceMessage(name: placeholder, value: email, message: message))
        } else {
            //Send code
            let dataSend = DataSend(email: email)
            
            guard let upload = try? JSONEncoder().encode(dataSend) else {
                Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                return
            }
            
            self.loading.startAnimating()
            self.view.isUserInteractionEnabled = false
            
            Constants.postRequest(endpoint: Constants.APIEndpoint.client + "forgot", bodyData: upload) { response in
                
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
                            self.performSegue(withIdentifier: "passwordReplaceSegue", sender: nil)
                        } else {
                            Constants.showMessage(msg: message)
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "passwordReplaceSegue" {
            if let pr = segue.destination as? PasswordReplace {
                pr.email = self.email
            }
        }
    }
    
    @IBAction func unwindFromPasswordReplace(_ sender: UIStoryboardSegue) {
        if let sourceVC = sender.source as? PasswordReplace {
            if sourceVC.passwordUpdated {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
