import UIKit
import WebKit

class Metodo:UIViewController, UIPickerViewDelegate, UIPickerViewDataSource
{

    @IBOutlet weak var pickV: UIPickerView!
    @IBOutlet weak var vview: UIView!
    @IBOutlet weak var okbutton: UIButton!
    @IBOutlet weak var cancelbutton: UIButton!
    @IBOutlet weak var back: UIButton!
    
    var pickD: [String] = [String]()
    var rowS: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pickV.delegate = self
        self.pickV.dataSource = self
        pickD = ["Efectivo", "Visa/Mastercard"]
    }
    
    @IBAction func dismissController(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindCreditCard", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickD.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: "System Bold", size: 15)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = pickD[row]
        pickerLabel?.textColor = UIColor.black

        return pickerLabel!
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickD[row]
    }
    
    private func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
          // This method is triggered whenever the user makes a change to the picker selection.
          // The parameter named row and component represents what was selected.
        rowS = row
      }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openCreditCardSegue2" {
            if segue.destination is CreditCard {
               
            }
        }
    }
    
    func openCreditCard(_ sender: Any) {
        self.performSegue(withIdentifier: "openCreditCardSegue2", sender: self)
    }
    
    @IBAction func cancelbuttondo(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func okbuttondo(_ sender: UIButton) {
        print("okbuttondo")
        if self.pickV.selectedRow(inComponent: 0)==0 {
            self.performSegue(withIdentifier: "unwindMetodo", sender: self)
        }
        if self.pickV.selectedRow(inComponent: 0) == 1 {
            openCreditCard(self)
        }
    }
  
    
}
