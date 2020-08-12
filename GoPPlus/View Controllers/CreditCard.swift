import UIKit
import WebKit

class CreditCard: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, WKUIDelegate {

    @IBOutlet weak var cardNumber: UITextField!
    @IBOutlet weak var monthNumber: UITextField!
    @IBOutlet weak var yearNumber: UITextField!
    @IBOutlet weak var cvvNumber: UITextField!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var prevCreditCard:Constants.CreditCardItem = Constants.CreditCardItem(Id: 0, Numero: "Ninguna")
    var selectedCreditCard:Constants.CreditCardItem = Constants.CreditCardItem(Id: 0, Numero: "Ninguna")
    var creditCards:[Constants.CreditCardItem] = []
    var previousCardDeleted:Bool = false
    
    struct CreditCardResponse:Codable {
        let data:[Constants.CreditCardItem]
        let message:String
        let status:Bool
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupToolbar()
        
        self.cardNumber.delegate = self
        self.monthNumber.delegate = self
        self.yearNumber.delegate = self
        self.cvvNumber.delegate = self
        self.webview.uiDelegate = self
        self.table.delegate = self
        self.table.dataSource = self
        self.table.estimatedRowHeight = 60.0
        self.table.rowHeight = 60.0
        self.loadCards()
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
        var userInfo = notification.userInfo!
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

    @IBAction func dismissController(_ sender: Any) {
        
        if !self.previousCardDeleted {
            self.selectedCreditCard = self.prevCreditCard
        } else {
            self.selectedCreditCard = Constants.CreditCardItem(Id: 0, Numero: "Ninguna")
        }
        
        self.performSegue(withIdentifier: "unwindCreditCard", sender: self)
    }
    
    @IBAction func doAddCard(_ sender: Any) {
        self.view.endEditing(true)
        
        let number:String = self.cardNumber.text!
        let month:String  = self.monthNumber.text!
        let year:String   = self.yearNumber.text!
        let sec:String    = self.cvvNumber.text!
        
        
        let numberText:String = self.cardNumber.placeholder!
        let monthText:String  = self.monthNumber.placeholder!
        let yearText:String   = self.yearNumber.placeholder!
        let secText:String    = self.cvvNumber.placeholder!
        
        var message:String = ""
        
        let date = Date()
        let calendar = Calendar.current
        let currentYear = String(calendar.component(.year, from: date))
        let yearDigits = String(currentYear.suffix(2))
        
        
        if !Validator.isRequired(text: number) {
            message += "\n" + Validator.replaceMessage(name: numberText, value: number, message: Validator.requiredError)
        }
        
        if !Validator.isNumber(text: number) {
            message += "\n" + Validator.replaceMessage(name: numberText, value: number, message: Validator.numberError)
        }
        
        if !Validator.isRequired(text: month) {
            message += "\n" + Validator.replaceMessage(name: monthText, value: month, message: Validator.requiredError)
        }
        
        if !Validator.isNumber(text: month) {
            message += "\n" + Validator.replaceMessage(name: monthText, value: month, message: Validator.numberError)
        }
        
        if !Validator.isValidMonth(text: month) {
            message += "\n" + Validator.replaceMessage(name: monthText, value: month, message: Validator.monthError)
        }
        
        if !Validator.isRequired(text: year) {
            message += "\n" + Validator.replaceMessage(name: yearText, value: year, message: Validator.requiredError)
        }
        
        if !Validator.isNumber(text: year) {
            message += "\n" + Validator.replaceMessage(name: yearText, value: year, message: Validator.numberError)
        }
        
        if !year.isEmpty {
            if (Int(year) ?? -1) < (Int(yearDigits) ?? 0) {
                message += "\n" + Validator.replaceMessage(name: yearText, value: year, message: Validator.yearError)
            }
        }
        
        if !Validator.isRequired(text: sec) {
            message += "\n" + Validator.replaceMessage(name: secText, value: sec, message: Validator.requiredError)
        }
        
        if !Validator.isNumber(text: sec) {
            message += "\n" + Validator.replaceMessage(name: secText, value: sec, message: Validator.numberError)
        }
        
        if !Validator.isValidCVV(text: sec) {
            message += "\n" + Validator.replaceMessage(name: secText, value: sec, message: Validator.cvvError)
        }
        
        if message.isEmpty {
            let card = Constants.toEncrypt64(text: number)
            let exp  = Constants.toEncrypt64(text: month + "" + year)
            let cvv  = Constants.toEncrypt64(text: sec)
            let id   = Constants.toEncrypt64(text: String(Constants.getIntStored(key: Constants.DBKeys.user + "clienteid")))
            let url_ = Constants.APIEndpoint.payment + "card-service-start?y=" + id + "&i=" + card + "&f=" + exp + "&a=" + cvv
            
            var request = URLRequest(url: URL(string: url_)!)
            
            request.addValue(Constants.getHeaderValue(key: "appid"), forHTTPHeaderField:"appid")
            request.addValue(Constants.toEncrypt(text: Constants.getHeaderValue(key: "user.id")), forHTTPHeaderField:"userid")
            
            self.view.bringSubviewToFront(self.webview)
            self.webview.load(request)
        } else {
            Constants.showMessage(msg: message)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let  char = string.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        if (isBackSpace == -92) {
            print("Backspace was pressed")
            return true
        }
        
        if let textValue = textField.text {
            if textField == self.cardNumber {
                if textValue.count > 15 {
                    return false
                }
            }
            
            if textField == self.monthNumber {
                if textValue.count > 1 {
                    return false
                }
            }
            
            if textField == self.yearNumber {
                if textValue.count > 1 {
                    return false
                }
            }
            
            if textField == self.cvvNumber {
                if textValue.count > 3 {
                    return false
                }
            }
        }
        
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.creditCards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell", for: indexPath) as! CardCell
        cell.actionBlock = {
            Constants.showConfirmation(msg: "¿Seguro de eliminar la tarjeta?", completion: { (is_true) in
                
                if is_true {
                    self.loading.startAnimating()
                    self.view.isUserInteractionEnabled = false
                    
                    struct removeCardStruct:Codable {
                        let id: Int
                        let card_id: Int
                    }
                    
                    let uploadData = removeCardStruct(id: Constants.getIntStored(key: Constants.DBKeys.user + "clienteid"), card_id: self.creditCards[indexPath.row].Id)
                    
                    guard let upload = try? JSONEncoder().encode(uploadData) else {
                        Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                        self.loading.stopAnimating()
                        self.view.isUserInteractionEnabled = true
                        return
                    }
                    
                    Constants.postRequest(endpoint: Constants.APIEndpoint.payment + "remove", bodyData: upload, completion: { (result) in
                        DispatchQueue.main.async {
                            self.loading.stopAnimating()
                            self.view.isUserInteractionEnabled = true
                            
                            guard let result = result else {
                                Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                                return
                            }
                            
                            if let status = result["status"] as? Bool,
                                let message = result["message"] as? String {
                                Constants.showMessage(msg: message)
                                
                                if status == true {
                                    if self.creditCards[indexPath.row].Id == self.prevCreditCard.Id {
                                        self.previousCardDeleted = true
                                    }
                                    
                                    self.loadCards()
                                }
                            }
                        }
                    })
                }
            })
        }
        
        cell.numberLabel.text = "**** **** **** " + self.creditCards[indexPath.row].Numero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedCreditCard = self.creditCards[indexPath.row]
        self.performSegue(withIdentifier: "unwindCreditCard", sender: self)
    }
    
    private func setupToolbar() {
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x:0, y:0, width: self.view.frame.width, height: 30))
        let flexspace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton:UIBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolbar.setItems([flexspace, doneButton], animated: false)
        toolbar.sizeToFit()
        
        self.cardNumber.inputAccessoryView = toolbar
        self.monthNumber.inputAccessoryView = toolbar
        self.yearNumber.inputAccessoryView = toolbar
        self.cvvNumber.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    func loadCards() {
        self.cardNumber.text = ""
        self.monthNumber.text = ""
        self.yearNumber.text = ""
        self.cvvNumber.text = ""
        
        let id = String(Constants.getIntStored(key: Constants.DBKeys.user + "clienteid"))
        self.loading.startAnimating()
        self.view.isUserInteractionEnabled = false
        
        Constants.getRequest(endpoint: Constants.APIEndpoint.payment + "list-", parameters: ["id" : id]) { (result) in
            DispatchQueue.main.async {
                self.loading.stopAnimating()
                self.view.isUserInteractionEnabled = true
                
                guard let result = result else {
                    Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
                    let thisResponse = try JSONDecoder().decode(CreditCardResponse.self, from: jsonData)
                    
                    if  thisResponse.status == false {
                        Constants.showMessage(msg: thisResponse.message)
                    }
                    
                    if thisResponse.data.count == 0 {
                        Constants.showMessage(msg: "No encontramos tarjetas vinculadas a tu cuenta. Agrega una nueva tarjeta para solicitar tu vehículo seleccionado con GoPPlus")
                    }
                    
                    self.creditCards = thisResponse.data
                    self.table.reloadData()
                } catch {
                    Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, shouldStartLoadWith request: URLRequest, navigationType: WKNavigationType.Type) -> Bool {
        if let url_ = request.url?.absoluteString {

            if url_.range(of: "card-service-end") != nil || url_.range(of: "card-service-error") != nil {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2) ) {
                    self.view.sendSubviewToBack(self.webview)
                    self.loadCards()
                }
            }
        }
        
        
        return true
    }
    
}
