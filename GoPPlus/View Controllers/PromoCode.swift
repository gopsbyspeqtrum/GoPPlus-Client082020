import UIKit

class PromoCode: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    struct ValidateCode:Codable {
        let code:String
        let id_cl:Int
    }
    
    var newTypeCode:Constants.PromoTypeCode = Constants.PromoTypeCode(id: "", typecode: "Ninguno", type: "")
    var prevTypeCode:Constants.PromoTypeCode = Constants.PromoTypeCode(id: "", typecode: "Ninguno", type: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loading.stopAnimating()
        self.setupToolbar()
        self.codeField.delegate = self
        self.codeField.autocapitalizationType = .allCharacters
    }

    @IBAction func dismissController(_ sender: Any) {
        self.newTypeCode = self.prevTypeCode
        self.performSegue(withIdentifier: "unwindDiscount", sender: self)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.codeField {
            if string == "" {
                textField.deleteBackward()
            } else {
                textField.insertText(string.uppercased())
            }
            
            return false
        }
        
        return true
    }
    
    @IBAction func doVerifyCode(_ sender: Any) {
        let id = Constants.getIntStored(key: Constants.DBKeys.user + "clienteid")
        let code = self.codeField.text!
        let codeHint = self.codeField.placeholder!
    
        
        var message = ""
        
        if !Validator.isRequired(text: code) {
            message += "\n" + Validator.replaceMessage(name: codeHint, value: code, message: Validator.requiredError)
        }
        
        if code.count > 50 {
            message += "\n" + Validator.replaceMessage(name: codeHint, value: code, message: "El código de descuento debe ser menor a 50 caracteres")
        }
        
        if (message.isEmpty) {
            let d = ValidateCode(code: code, id_cl: id)
            guard let uploadData = try? JSONEncoder().encode(d) else {
                return
            }
            
            self.loading.startAnimating()
            self.view.isUserInteractionEnabled = false
            
            Constants.postRequest(endpoint: Constants.APIEndpoint.client + "validate-code", bodyData: uploadData) { (response) in
                DispatchQueue.main.async {
                    self.loading.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    
                    if response == nil {
                        Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                        return
                    }
                    
                    guard let response = response else {
                        Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                        return
                    }
                    
                    if let status = response["status"] as? Bool,
                        let message = response["message"] as? String {
                        
                        if (!status) {
                            Constants.showMessage(msg:message)
                            return
                        }
                    }
                    
                    if let cid = response["cid"] as? String {
                        self.newTypeCode = Constants.PromoTypeCode(id: cid, typecode: code, type: "coupon")
                    } else if let uid = response["uid"] as? String {
                        self.newTypeCode = Constants.PromoTypeCode(id: uid, typecode: code, type: "code")
                    } else {
                        self.newTypeCode = Constants.PromoTypeCode(id: "", typecode: "Ninguno", type: "")
                    }
                    
                    self.performSegue(withIdentifier: "unwindDiscount", sender: self)
                }
            }
        } else {
            Constants.showMessage(msg: message)
        }
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
}
