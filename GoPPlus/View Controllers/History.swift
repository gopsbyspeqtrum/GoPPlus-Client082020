import UIKit

class History: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    struct HistoryComplete:Codable {
        let data:[HistoryStruct]
        let message:String
        let status:Bool
    }
    
    struct HistoryStruct:Codable {
        let estatus:String
        let origen:String
        let destino:String
        let fecha_actualizacion:String
        let fecha_finalizacion:String
        let fecha_domicilio:String
        let fecha_ocupado:String
        let conductor:String
        let marca:String?
        let modelo:String?
        let color:String?
        let placas:String?
        let lat_origen:Double
        let lng_origen:Double
        let lat_destino:Double
        let lng_destino:Double
        let tipo_vehiculo:String
        let ruta:String
        let encuesta: Int
        let id: Int
        let id_conductor:Int?
        let monto:Double
    }
    
    var historyItems:[HistoryStruct] = []
    
    override func viewDidLoad() {
        print("F")

        super.viewDidLoad()
        self.table.delegate = self
        self.table.dataSource = self
        self.loading.stopAnimating()
        self.loadHistory()
    }

    @IBAction func dismissController(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doReload(_ sender: Any) {
        self.loadHistory()
    }
    
    func loadHistory() {
        
        self.loading.startAnimating()
        
        Constants.getRequest(endpoint: Constants.APIEndpoint.client + "history", parameters: ["id": String(Constants.getIntStored(key: Constants.DBKeys.user + "id"))]) { (result) in
            guard let result = result else {
                Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
                let history =  try JSONDecoder().decode(HistoryComplete.self, from: jsonData)
                self.historyItems = history.data
                
                DispatchQueue.main.async {
                    self.loading.stopAnimating()
                    self.table.reloadData()
                }
            } catch {
                print("Error getting data")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryCell
        let h = self.historyItems[indexPath.row]
        
        let marca = h.marca ?? ""
        let modelo = h.modelo ?? ""
        let color = h.color ?? ""
        let placas = h.placas ?? ""
        
        cell.carLabel.text = marca + " " + modelo + " " + color + " " + placas
        
        if !h.fecha_finalizacion.isEmpty {
            cell.dateLabel.text = h.fecha_finalizacion
        } else {
            cell.dateLabel.text = h.fecha_actualizacion
        }
        
        cell.driverLabel.text = h.conductor
        cell.statusLabel.text = h.estatus
        cell.startLabel.text = h.origen
        cell.stopLabel.text = h.destino
        
        var mapPath = ""
        
        if h.ruta.isEmpty {
            mapPath = String(h.lat_origen) + "," + String(h.lng_origen)
        } else {
            mapPath = String(h.ruta.dropLast())
        }
        
        let parameters:[String:String] = ["size": "640x300", "key": Constants.APIKEY, "sensor": "false", "path": mapPath];
        let urlComponent = NSURLComponents(string: "https://maps.googleapis.com/maps/api/staticmap")!
        
        urlComponent.queryItems = parameters.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: urlComponent.url!)
            
            DispatchQueue.main.async {
                cell.mapImage.image = UIImage(data: data!)
            }
        }
        
        return cell
    }
    
    
    
}
