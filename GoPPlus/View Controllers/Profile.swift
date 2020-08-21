import UIKit
import Photos

class Profile: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var birthdayField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var scrollview: UIScrollView!
    
    let myPickerController = UIImagePickerController()
    var keyboardHeight: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.birthdayField.delegate = self
        self.profileImage.isUserInteractionEnabled = true
        self.profileImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeProfileImage(_:))))
        self.profileImage.layer.borderWidth = 1
        self.profileImage.layer.borderColor = UIColor.gray.cgColor
        self.profileImage.layer.cornerRadius = self.profileImage.frame.width / 2
        self.profileImage.clipsToBounds = true
        self.profileImage.layer.masksToBounds = true
        loadUserImage()
        loadUserData()
        
        self.myPickerController.delegate = self;
        self.myPickerController.sourceType = .photoLibrary
        
        self.setupToolbar()
        self.loading.stopAnimating()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.checkPermission()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        let userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.scrollview.contentInset
        contentInset.bottom = keyboardFrame.size.height
        self.scrollview.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.scrollview.contentInset = contentInset
    }
    
    
    @IBAction func specialDateTextFieldClick(_ sender: UITextField) {
        let currentDate:String = Constants.getStringStored(key: Constants.DBKeys.user + "fechac")
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
        //according to date format your date string
        guard let date = dateFormatter.date(from: currentDate) else {
            fatalError()
        }
        
        datePickerView.date = date
        datePickerView.maximumDate = maxDate
        datePickerView.minimumDate = minDate
        datePickerView.datePickerMode = UIDatePicker.Mode.date
        
        birthdayField.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(datePickerFromValueChanged), for: UIControl.Event.valueChanged)
    }
    
    @objc func datePickerFromValueChanged(sender:UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        birthdayField.text = dateFormatter.string(from: sender.date)
    }

    @IBAction func dismissController(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doUpdateProfile(_ sender: Any) {
        self.view.endEditing(true)
        
        let email = self.emailField.text!
        let name  = self.nameField.text!
        let phone = self.phoneField.text!
        let birth = self.birthdayField.text!
        
        let emailPlaceholder = self.emailField.placeholder!
        let namePlaceholder  = self.nameField.placeholder!
        let phonePlaceholder = self.phoneField.placeholder!
        let birthPlaceholder = self.birthdayField.placeholder!
        
        var message = ""
        
        if !Validator.isRequired(text: email) {
            message += "\n" + Validator.replaceMessage(name: emailPlaceholder, value: email, message: Validator.requiredError)
        }
        
        if !Validator.isEmail(email: email) {
            message += "\n" + Validator.replaceMessage(name: emailPlaceholder, value: email, message: Validator.emailError)
        }
        
        if !Validator.isRequired(text: name) {
            message += "\n" + Validator.replaceMessage(name: namePlaceholder, value: name, message: Validator.requiredError)
        }
        
        if !Validator.isName(name: name) {
            message += "\n" + Validator.replaceMessage(name: namePlaceholder, value: name, message: Validator.nameError)
        }
        
        if !Validator.isRequired(text: phone) {
            message += "\n" + Validator.replaceMessage(name: phonePlaceholder, value: phone, message: Validator.requiredError)
        }
        
        if !Validator.isRequired(text: birth) {
            message += "\n" + Validator.replaceMessage(name: birthPlaceholder, value: birth, message: Validator.requiredError)
        }
        
        
        if message.isEmpty {
            struct User:Codable {
                let id: Int
                let oldemail:String
                let name:String
                let phone:String
                let email:String
                let birthDate:String
            }
            
            let UpdUser = User(
                id: Constants.getIntStored(key: Constants.DBKeys.user + "id"),
                oldemail: Constants.getStringStored(key: Constants.DBKeys.user + "correo"),
                name: name,
                phone: phone,
                email: email,
                birthDate: birth)
            
            guard let uploadData = try? JSONEncoder().encode(UpdUser) else {
                Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                return
            }
            
            self.loading.startAnimating()
            
            Constants.postRequest(endpoint: Constants.APIEndpoint.client + "updateprofile", bodyData: uploadData) { (result) in
                
                guard let response = result else {
                    Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                    return;
                }
                
                 DispatchQueue.main.async {
                
                    if let status = response["status"] as? Bool,
                        let message = response["message"] as? String {
                        
                        if (status == true) {
                            Constants.showMessage(msg: "Actualizado");
                            Constants.store(key: Constants.DBKeys.user + "correo", value: email)
                            Constants.store(key: Constants.DBKeys.user + "telefono", value: phone)
                            Constants.store(key: Constants.DBKeys.user + "nombre", value: name)
                            Constants.store(key: Constants.DBKeys.user + "fechac", value: birth)
                        } else {
                            Constants.showMessage(msg: message)
                        }
                    }
                    
                    self.loading.stopAnimating()
                }
            }
            
        } else {
            Constants.showMessage(msg: message)
        }
        
    }
    
    func loadUserData() {
        self.birthdayField.text = Constants.getStringStored(key: Constants.DBKeys.user + "fechac")
        self.nameField.text = Constants.getStringStored(key: Constants.DBKeys.user + "nombre")
        self.phoneField.text = Constants.getStringStored(key: Constants.DBKeys.user + "telefono")
        self.emailField.text = Constants.getStringStored(key: Constants.DBKeys.user + "correo")
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
            self.infoLabel.isHidden = true
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
                    self.profileImage.image = UIImage(data: data!)
                }
            }
        }
    }
    
    @objc func changeProfileImage(_ sender: UITapGestureRecognizer) {
        let fbid = Constants.getStringStored(key: Constants.DBKeys.user + "fbid")
        
        if (fbid.isEmpty) {
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status{
                    case .authorized:
                        DispatchQueue.main.async{
                            self.present(self.myPickerController, animated: true, completion: nil)
                        }
                    default:
                        Constants.showMessage(msg: "Permite el acceso a la librería para seleccionar una nueva foto de perfil")
                        break
                }
            }
        }
    }
    
    func checkPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch (photoAuthorizationStatus) {
            
                case .authorized:
                    print("Access is granted by user")
                case .notDetermined:
            
                    PHPhotoLibrary.requestAuthorization({
                        (newStatus) in
                        
                        print("status is \(newStatus)")
                    })
                
                case .restricted:
                    print("User do not have access to photo album.")
                case .denied:
                    print("User has denied the permission.")
            
        }
                
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let size = image.size
        
        let widthRatio  = 100  / size.width
        let heightRatio = 100 / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let theImage:String = newImage?.pngData()?.base64EncodedString() {
            let id = Constants.getIntStored(key: Constants.DBKeys.user + "id")
            struct ImageUpload:Codable {
                let id:Int
                let theImage:String
            }
            
            let imageUpload = ImageUpload(id: id, theImage: theImage)
            
            guard let uploadData = try? JSONEncoder().encode(imageUpload) else {
                return
            }
            
            self.loading.startAnimating()
            
            Constants.postRequest(endpoint: Constants.APIEndpoint.client + "upload-profile-image", bodyData: uploadData) { (result) in
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(5) ) {
                    self.loading.stopAnimating()
                    
                    if result != nil {
                        self.profileImage.image = image
                        Constants.showMessage(msg: "Foto de perfil actualizada")
                    } else {
                        Constants.showMessage(msg: "Intenta nuevamente")
                    }
                }
            }
        }
        
        dismiss(animated: true, completion: nil)
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
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
}
