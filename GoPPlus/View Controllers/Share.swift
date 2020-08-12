import UIKit

class Share: UIViewController {

    @IBOutlet weak var codeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.codeLabel.text = Constants.getStringStored(key: Constants.DBKeys.user + "codigo")
    }

    @IBAction func dismissController(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doShare(_ sender: Any) {
        let text = "¡Usa mi código " + Constants.getStringStored(key: Constants.DBKeys.user + "codigo") + " y recibe un descuento en tu primer viaje con GoPPlus!"
        let textToShare = [text]
        let activityViewController = UIActivityViewController(activityItems: textToShare as [Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
}
