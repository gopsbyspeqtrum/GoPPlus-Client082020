//
//  Rating.swift
//  GoPPlus
//
//  Created by Cristina on 12/20/18.
//  Copyright © 2018 GFA. All rights reserved.
//

import UIKit

class Rating: UIViewController {

    @IBOutlet weak var imageProfile: UIImageView!
    @IBOutlet weak var driverName: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var dateFinished: UILabel!
    @IBOutlet weak var comments: UITextField!
    @IBOutlet weak var oneStar: UIButton!
    @IBOutlet weak var twoStar: UIButton!
    @IBOutlet weak var threeStar: UIButton!
    @IBOutlet weak var fourStar: UIButton!
    @IBOutlet weak var fiveStar: UIButton!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailLabel: UILabel!
    
    var rate:Int = 0
    
    var unratedService:Constants.UnratedService = Constants.UnratedService(id: 0, conductor: 0, nombre_conductor: "", fecha: "", precio: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupToolbar()
        self.price.text = String(format: "$%.2f", self.unratedService.precio)
        self.driverName.text = self.unratedService.nombre_conductor
        self.dateFinished.text = self.unratedService.fecha
        self.emailLabel.text = "quejas_movilidad@guanajuato.gob.mx"
        self.showDriverProfileImage()
        self.loading.stopAnimating()
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
        
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            var contentInset:UIEdgeInsets = self.scrollView.contentInset
            contentInset.bottom = keyboardHeight
            
            self.scrollView.contentInset = contentInset
        }
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.scrollView.contentInset = contentInset
    }
    
    private func setupToolbar() {
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x:0, y:0, width: self.view.frame.width, height: 30))
        let flexspace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton:UIBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolbar.setItems([flexspace, doneButton], animated: false)
        toolbar.sizeToFit()
        
        self.comments.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    func showDriverProfileImage() {
        let profileImageUrl = Constants.APIEndpoint.driver + "images"
        let parameters:[String:String] = ["id": String(self.unratedService.conductor) + ".jpg"]
        let urlComponent = NSURLComponents(string: profileImageUrl)!
        
        urlComponent.queryItems = parameters.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        
        DispatchQueue.global().async {
             let imageData = try? Data(contentsOf: urlComponent.url!)
            
            DispatchQueue.main.async {
                self.imageProfile.image = UIImage(data: imageData!)
                self.imageProfile.layer.borderWidth = 1
                self.imageProfile.layer.borderColor = UIColor.gray.cgColor
                self.imageProfile.layer.cornerRadius = self.imageProfile.frame.width / 2
                self.imageProfile.clipsToBounds = true
                self.imageProfile.layer.masksToBounds = true
            }
        }
    }
    
    @IBAction func doChangeRate(_ sender: UIButton) {
        
        self.oneStar.setImage(UIImage(named: "iconstarblack"), for: UIControl.State.normal)
        self.twoStar.setImage(UIImage(named: "iconstarblack"), for: UIControl.State.normal)
        self.threeStar.setImage(UIImage(named: "iconstarblack"), for: UIControl.State.normal)
        self.fourStar.setImage(UIImage(named: "iconstarblack"), for: UIControl.State.normal)
        self.fiveStar.setImage(UIImage(named: "iconstarblack"), for: UIControl.State.normal)
        
        
        if sender == self.oneStar {
            self.oneStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.rate = 1
        }
        
        if sender == self.twoStar {
            self.oneStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.twoStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.rate = 2
        }
        
        if sender == self.threeStar {
            self.oneStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.twoStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.threeStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.rate = 3
        }
        
        if sender == self.fourStar {
            self.oneStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.twoStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.threeStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.fourStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.rate = 4
        }
        
        if sender == self.fiveStar {
            self.oneStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.twoStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.threeStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.fourStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.fiveStar.setImage(UIImage(named: "iconstar"), for: UIControl.State.normal)
            self.rate = 5
        }
    }
    
    @IBAction func doSend(_ sender: Any) {
        if self.rate == 0 {
            Constants.showMessage(msg: "Califica tus Servicios, así nos ayudas a mejorar.")
            return
        }
        
        let comments = self.comments.text!
        let placeholder = self.comments.placeholder!
        var message:String = ""
        
        if !Validator.isRequired(text: comments) {
            message += "\n" + Validator.replaceMessage(name: placeholder, value: comments, message: Validator.requiredError)
        }
        
        if !Validator.isText(text: comments) {
            message += "\n" + Validator.replaceMessage(name: placeholder, value: comments, message: Validator.textError)
        }
        
        if comments.count > 50 {
            message += "\n El texto debe ser menor a 50 caracteres"
        }
        
        if comments.count < 2 {
            message += "\n El texto debe ser mayor a 2 caracteres"
        }
        
        
        if message.isEmpty {
            
            struct RatingData:Codable {
                let id:Int
                let rate:Int
                let obs:String
            }
            
            let ratingData_ = RatingData(id: self.unratedService.id, rate: self.rate, obs: comments)
            
            guard let uploadData = try? JSONEncoder().encode(ratingData_) else {
                Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                return
            }
            
            self.loading.startAnimating()
            self.view.isUserInteractionEnabled = false
            
            Constants.postRequest(endpoint: Constants.APIEndpoint.client + "rate", bodyData: uploadData) { (result) in
                DispatchQueue.main.async {
                    self.loading.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    
                    guard let result = result else {
                        Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                        return
                    }
                    
                    if let status = result["status"] as? Bool,
                        let message_ = result["message"] as? String {
                        
                        if status == true {
                            self.performSegue(withIdentifier: "unwindFromRating", sender: self)
                        } else {
                            Constants.showMessage(msg: message_)
                        }
                    }
                }
            }
        } else {
            Constants.showMessage(msg: message)
        }
    }
}
