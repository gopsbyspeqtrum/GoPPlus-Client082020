import UIKit
import CoreLocation

class Search: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var unwindIdentifier:String = "unwindStartAddress"
    var data:[Location] = []
    lazy var googleClient: GoogleClientRequest = GoogleClient()
    
    struct Location:Codable {
        var latitude: Double
        var longitude: Double
        var address: String
    }
    
    var location:Location = Location(latitude: 0.0, longitude: 0.0, address: "")
    var searchResult:GooglePlaces = GooglePlaces(predictions: [], status: "NO")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupToolbar()
        self.table.dataSource = self
        self.table.delegate = self
        self.location = Location(latitude: 0.0, longitude: 0.0, address: "")
        self.loading.stopAnimating()
    }
    
    private func setupToolbar() {
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x:0, y:0, width: self.view.frame.width, height: 30))
        let flexspace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton:UIBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(doneButtonAction))
        
        toolbar.setItems([flexspace, doneButton], animated: false)
        toolbar.sizeToFit()
        
        self.addressField.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    @IBAction func goSearchAddress(_ sender: Any) {
        let address = addressField.text!
        let placeholder = addressField.placeholder!
        var message = ""
        
        if !Validator.isRequired(text: address) {
            message = Validator.replaceMessage(name: placeholder, value: address, message: Validator.requiredError)
        }
        
        if message.isEmpty {
            self.getAddresses(address: address)
        } else {
            Constants.showMessage(msg: message)
        }
    }
    
    func getAddresses(address: String) {
        self.data.removeAll()
        
        self.loading.startAnimating()
        
        googleClient.getGooglePlacesData(forKeyword: address + " Leon,Guanajuato") { (response) in
            
            DispatchQueue.main.async {
                self.loading.stopAnimating()
                
                if response.results.count > 0 {
                    self.searchResult = response.results[0]
                    
                    for pred in self.searchResult.predictions {
                        self.data.append(Location(latitude: 0, longitude: 0, address: pred.structured_formatting.main_text))
                        self.table.reloadData()
                    }
                    
                    
                } else {
                    Constants.showMessage(msg: "No se encontraron coincidencias")
                }
            }
        }
    }
    
    @IBAction func dismissController(_ sender: Any) {
        performSegue(withIdentifier: unwindIdentifier, sender: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = data[indexPath.row].address
        cell.textLabel?.font = UIFont(name: "Arial", size: 14.0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if data.count == 0 {
            return
        }
        
        location = data[indexPath.row]
        let place = self.searchResult.predictions[indexPath.row]
        
        self.loading.startAnimating()
        
        googleClient.getGooglePlaceId(forPlaceId: place.place_id) { (response) in
            DispatchQueue.main.async {
                if response.status == "OK" {
                    self.location.latitude = response.result.geometry.location.lat
                    self.location.longitude = response.result.geometry.location.lng
                    self.performSegue(withIdentifier: self.unwindIdentifier, sender: self)
                } else {
                    Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                }
            }
        }
    }
}
