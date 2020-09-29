import UIKit

extension UITableView {
    func scrollToBottom(animated: Bool = true) {
        let section = self.numberOfSections
        if section > 0 {
            let row = self.numberOfRows(inSection: section - 1)
            if row > 0 {
                self.scrollToRow(at: NSIndexPath(row: row - 1, section: section - 1) as IndexPath, at: .bottom, animated: animated)
            }
        }
    }
}

class Chat: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    var driver_id:Int = 0
    var service_id:Int = 0
    
    struct ResultComplete:Codable {
        let data:[ChatMessages]
        let message:String
        let status:Bool
    }
    
    struct ChatMessages:Codable {
        let mensaje: String
        let fecha: String
        let img: String
        let es_conductor: Int
    }
    
    
    
    var chatMessages:[ChatMessages] = []
    
    override func viewDidLoad() {
        print("B")

        super.viewDidLoad()
        self.table.delegate = self
        self.table.dataSource = self
        
        self.table.rowHeight = 150
        self.table.estimatedRowHeight = 150
        UITableView.appearance().separatorColor = UIColor.white
        
        self.loadMessages(seconds: 0)
        self.setupToolbar()
    }
    
    private func setupToolbar() {
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x:0, y:0, width: self.view.frame.width, height: 30))
        let flexspace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton:UIBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolbar.setItems([flexspace, doneButton], animated: false)
        toolbar.sizeToFit()
        
        self.messageField.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
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

    @IBAction func dismissController(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func send(_ sender: Any) {
        self.view.endEditing(true)
        let message = self.messageField.text!
        let messagePlaceholder = self.messageField.placeholder!
        var errorMessage = ""
        
        if !Validator.isRequired(text: message) {
            errorMessage += "\n" + Validator.replaceMessage(name: messagePlaceholder, value: message, message: Validator.requiredError)
        }
        
        if !errorMessage.isEmpty {
            Constants.showMessage(msg: errorMessage)
        } else {
            struct chatSend:Codable {
                let id:Int
                let id_chofer:Int
                let mensaje:String
            }
            
            let chatSendObject = chatSend(id: self.service_id, id_chofer: self.driver_id, mensaje: message)
            
            guard let uploadData = try? JSONEncoder().encode(chatSendObject) else {
                Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                return
            }
            
            self.view.isUserInteractionEnabled = false
            
            Constants.postRequest(endpoint: Constants.APIEndpoint.client + "chat-message", bodyData: uploadData) { (result) in
                DispatchQueue.main.async {
                    self.view.isUserInteractionEnabled = true
                    self.messageField.text = ""
                    self.table.reloadData()
                }
            }
        }
    }

    func loadMessages(seconds:Int) {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(seconds), execute: {
            
            Constants.getRequest(endpoint: Constants.APIEndpoint.client + "chat", parameters: ["id": String(self.service_id), "id_chofer": String(self.driver_id)]) { (result) in
                guard let result = result else {
                    self.loadMessages(seconds: 10)
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
                    let chats =  try JSONDecoder().decode(ResultComplete.self, from: jsonData)
                    self.chatMessages = chats.data
                    
                    DispatchQueue.main.async {
                        self.table.reloadData()
                        self.table.scrollToBottom()
                        self.loadMessages(seconds: 10)
                    }
                } catch {
                    print("Error getting data")
                }
            }
        })
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let h = self.chatMessages[indexPath.row]
        
        if h.es_conductor == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DriverChatCell", for: indexPath) as! DriverChatCell
            
            cell.message.text = h.mensaje
            cell.date.text = h.fecha
            
            let urlComponent = NSURLComponents(string: h.img)!
            
            
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: urlComponent.url!)
                
                DispatchQueue.main.async {
                    cell.profileImage.image = UIImage(data: data!)
                    cell.profileImage.layer.cornerRadius = cell.profileImage.frame.width / 2
                    cell.profileImage.clipsToBounds = true
                    cell.profileImage.layer.masksToBounds = true
                }
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ClientChatCell", for: indexPath) as! ClientChatCell
            cell.message.text = h.mensaje
            cell.date.text = h.fecha
            
            let urlComponent = NSURLComponents(string: h.img)!
            
            
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: urlComponent.url!)
                
                DispatchQueue.main.async {
                    cell.profileImage.image = UIImage(data: data!)
                    cell.profileImage.layer.cornerRadius = cell.profileImage.frame.width / 2
                    cell.profileImage.clipsToBounds = true
                    cell.profileImage.layer.masksToBounds = true
                }
            }
            
            return cell
        }
    }
    

}
