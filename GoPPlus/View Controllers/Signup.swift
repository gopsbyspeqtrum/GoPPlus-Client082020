import UIKit
import FacebookLogin


class Signup: UIViewController, UITextFieldDelegate {
    
    struct Register:Codable {
        var fbid:String
        var name:String
        var email:String
        var phone:String
        var password:String
        var birthDate:String
    }
    
    struct InitSettings:Codable {
        let k: String
        let v: String
    }
    
    struct InitSettingsWrapper:Codable {
        let settings:[InitSettings]
    }
    
    var userId:Int = 0
    var newUser = Register(fbid: "", name: "", email: "", phone: "", password: "", birthDate: "")
    var termsAccepted:Bool = false
    var currentSettings:InitSettingsWrapper = InitSettingsWrapper(settings: [])
    
    @IBOutlet weak var FBButton: UIButton!
    @IBOutlet weak var birthdayField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var email2Field: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var checkboxView: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var openTerms: UILabel!
    
    override func viewDidLoad() {
        print("N")

        super.viewDidLoad()
        self.getPublicConfig()
        self.birthdayField.delegate = self
        self.loading.stopAnimating()
        self.setupTapGesture()
        self.setupToolbar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        let userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        self.scrollView.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.scrollView.contentInset = contentInset
    }
    
    
    @IBAction func specialDateTextFieldClick(_ sender: UITextField) {
        let datePickerView:UIDatePicker = UIDatePicker()
        let calendar = Calendar(identifier: .gregorian)
        var comps = DateComponents()
        comps.year = -99
        let minDate = calendar.date(byAdding: comps, to: Date())
        comps.year = -18
        let maxDate = calendar.date(byAdding: comps, to: Date())
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT-06:00") //Current time zone

        let currentDate:String = self.birthdayField.text!
        
        if !currentDate.isEmpty {
            if let date = dateFormatter.date(from: currentDate) {
                datePickerView.date = date
            }
        }
        
        datePickerView.maximumDate = maxDate
        datePickerView.minimumDate = minDate
        datePickerView.datePickerMode = UIDatePicker.Mode.date
        
        self.birthdayField.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(datePickerFromValueChanged), for: UIControl.Event.valueChanged)
    }
    
    @objc func datePickerFromValueChanged(sender:UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        birthdayField.text = dateFormatter.string(from: sender.date)
    }
    
    private func setupTapGesture() {
        self.checkboxView.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        
        self.checkboxView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (self.tapAction (_:))))
        self.openTerms.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (self.openTermsAction (_:))))
    }
    
    
    
    private func setupToolbar() {
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x:0, y:0, width: self.view.frame.width, height: 30))
        let flexspace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton:UIBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolbar.setItems([flexspace, doneButton], animated: false)
        toolbar.sizeToFit()
        
        self.birthdayField.inputAccessoryView = toolbar
        self.nameField.inputAccessoryView = toolbar
        self.phoneField.inputAccessoryView = toolbar
        self.emailField.inputAccessoryView = toolbar
        self.email2Field.inputAccessoryView = toolbar
        self.passwordField.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    @objc func openTermsAction(_ sender:UITapGestureRecognizer) {
        print("here")
        if self.currentSettings.settings.count > 0 {
            
            for s in self.currentSettings.settings {
                
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
    
    @objc func tapAction(_ sender:UITapGestureRecognizer) {
        if !termsAccepted {
            termsAccepted = true
            self.checkboxView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        } else {
            termsAccepted = false
            self.checkboxView.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        }
    }
    
    @IBAction func dismissController(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doRegister(_ sender: Any) {
        if !termsAccepted {
            Constants.showMessage(msg: "Acepta los términos y condiciones")
            return
        }
        
        let birthday = birthdayField.text!
        let name = nameField.text!
        let phone = phoneField.text!
        let email = emailField.text!
        let email2 = email2Field.text!
        let password = passwordField.text!
        
        let birthdayPlaceholder = birthdayField.placeholder!
        let namePlaceholder = nameField.placeholder!
        let phonePlaceholder = phoneField.placeholder!
        let emailPlaceholder = emailField.placeholder!
        let email2Placeholder = email2Field.placeholder!
        let passwordPlaceholder = passwordField.placeholder!
        
        var message = ""
    
        if !Validator.isRequired(text: birthday) {
            message += "\n" + Validator.replaceMessage(name: birthdayPlaceholder, value: birthday, message: Validator.requiredError)
        }
        
        if !Validator.isRequired(text: name) {
            message += "\n" + Validator.replaceMessage(name: namePlaceholder, value: name, message: Validator.requiredError)
        }
        
        if !Validator.isName(name: name) {
            message += "\n" + Validator.replaceMessage(name: namePlaceholder, value: name, message: Validator.nameError)
        }
        
        if !name.isEmpty {
            if name.count < 3 || name.count > 100 {
                message += "\nEl campo " + namePlaceholder + " debe ser mayor a 2 caracteres y menor a 100"
            }
        }
        
        if !Validator.isRequired(text: phone) {
            message += "\n" + Validator.replaceMessage(name: phonePlaceholder, value: phone, message: Validator.requiredError)
        }
        
        if !phone.isEmpty {
            if phone.count != 10 {
                message += "\nEl campo " + phonePlaceholder + " debe ser igual a 10 caracteres"
            }
        }
        
        if !Validator.isRequired(text: email) {
            message += "\n" + Validator.replaceMessage(name: emailPlaceholder, value: email, message: Validator.requiredError)
        }
        
        if !Validator.isEmail(email: email) {
            message += "\n" + Validator.replaceMessage(name: emailPlaceholder, value: email, message: Validator.emailError)
        }
        
        if email2 != email {
            message += "\n" + email2Placeholder + " no es igual a " + emailPlaceholder
        }
        
        if !Validator.isRequired(text: password) {
            message += "\n" + Validator.replaceMessage(name: passwordPlaceholder, value: password, message: Validator.requiredError)
        }
        
        if !Validator.isPassword(password: password) {
            message += "\n" + Validator.replaceMessage(name: passwordPlaceholder, value: password, message: Validator.passwordError)
        }
        
        if !message.isEmpty {
            Constants.showMessage(msg: message)
            return
        }
        
        newUser.name = name
        newUser.email = email
        newUser.birthDate = birthday
        newUser.phone = phone
        newUser.password = password.md5()
        
        guard let upload = try? JSONEncoder().encode(newUser) else {
            Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
            return
        }
        
        self.loading.startAnimating()
        self.view.isUserInteractionEnabled = false
        
        Constants.postRequest(endpoint: Constants.APIEndpoint.client + "register", bodyData: upload) { response in
            
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
                    
                    if status {
                        if !self.newUser.fbid.isEmpty {
                            Constants.showPrompt(msg: "Cuenta registrada, inicia sesión con tu correo electrónico y contraseña registrados", completion: { (clicked) in
                                self.dismissController(self)
                            })
                        } else {
                            self.userId = response["id"] as! Int
                            
                            Constants.showPrompt(msg: "Cuenta registrada. Enviamos un código de activación a tu correo  \(self.newUser.email), ingresa el código en la página de activación para iniciar sesión.", completion: { (clicked) in
                                
                                self.performSegue(withIdentifier: "segueActivate", sender: self)
                            })
                        }
                    } else {
                        Constants.showMessage(msg: message)
                    }
                }
            }
        }
    }
    
    @IBAction func doFacebookLogin(_ sender: Any) {
        let loginManager = LoginManager()
        
        loginManager.logIn(permissions: ["public_profile", "email"], from: self )
       {
        loginresult, error in
            
            if error != nil {
                Constants.showMessage(msg: "Facebook Login. Intenta nuevamente")
                return
            }
            
            if let FBResult = loginresult {
                if FBResult.isCancelled {
                    Constants.showMessage(msg: "Facebook Login cancelado. Intenta nuevamente")
                    return
                }
                
                let graphRequest:GraphRequest = GraphRequest(graphPath: "me", parameters: ["fields" : "id, email, name, first_name,last_name, birthday"])
               
                graphRequest.start(completionHandler: { (connection, result, error) in
                    
                    if error != nil {
                        Constants.showMessage(msg: "Facebook Login. Intenta nuevamente")
                    } else {
                        guard let myDictionary:NSDictionary = result as? NSDictionary else {
                            Constants.showMessage(msg: "Facebook Login. Intenta nuevamente")
                            return
                        }
                        
                        let id:String = myDictionary.object(forKey: "id") as! String
                        var birthday:String = myDictionary.object(forKey: "birthday") as? String ?? ""
                        let email:String = myDictionary.object(forKey: "email") as? String ?? ""
                        let first_name:String = myDictionary.object(forKey: "first_name") as? String ?? ""
                        let last_name:String = myDictionary.object(forKey: "last_name") as? String ?? ""
                        
                        
                        if !birthday.isEmpty {
                            birthday = birthday.replacingOccurrences(of: "/", with: "-")
                        }
                        
                        self.birthdayField.text = birthday
                        self.nameField.text = first_name + " " + last_name
                        self.emailField.text = email
                        self.email2Field.text = email
                        self.emailField.isEnabled = false
                        self.email2Field.isEnabled = false
                        
                        self.newUser.fbid = id
                        self.newUser.name = first_name + " " + last_name
                        self.newUser.email = email
                        self.newUser.birthDate = birthday
                    }
                })
            }
        }
    }
    
    
    @IBAction func unwindSignup(_ sender: UIStoryboardSegue) {
        if let ac = sender.source as? Activate {
            if ac.activationSuccess {
                self.dismissController(self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueActivate" {
            if let ac = segue.destination as? Activate {
                ac.email = self.newUser.email
                ac.id = self.userId
            }
        }
    }
    
    
    func getPublicConfig() {
        Constants.getRequest(endpoint: Constants.APIEndpoint.client + "initsettings", parameters:nil) { (result) in
            guard let result = result else {
                print("Error getting initSettings")
                return
            }
            
            do {
                guard let settings_ = try? JSONSerialization.data(withJSONObject:result) else {
                    print("Error decoding initSettings")
                    return
                }
                
                self.currentSettings = try JSONDecoder().decode(InitSettingsWrapper.self, from: settings_)
            } catch {
                print("Error getting settings")
            }
        }
    }
}
