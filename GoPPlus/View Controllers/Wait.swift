import UIKit
import WebKit

class Wait: UIViewController, WKNavigationDelegate {
    
    public var serviceData:Constants.ServiceData?
    var cancelURL = Constants.APIEndpoint.payment + "postauth-service-start?act=CANCEL&id="
    public var confirmationVisible:Bool = false
    public var statusLabelValue:String = ""
    
    let alert:UIAlertController = UIAlertController(title: "GoPPlus", message: "No se encontraron unidades cercanas, ¿Desea seguir esperando?", preferredStyle: UIAlertController.Style.alert)
    
    @IBOutlet weak var webview: WKWebView?
    @IBOutlet weak var statusLabel: UILabel!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webview?.navigationDelegate = self
        self.confirmationVisible = false
        self.statusLabel.text = "Espere un momento"
        
        self.alert.addAction(UIAlertAction(title: "No, cancelar", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
            self.cancelService()
        }))
        
        self.alert.addAction(UIAlertAction(title: "Seguir esperando", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
            self.confirmationVisible = false
            self.alert.dismiss(animated: true, completion: nil)
        }))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.statusLabel.text = "Espere un momento"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.statusLabel.text = "Espere un momento"
    }
    
    public func setServiceData(data: Constants.ServiceData) {
        self.serviceData = data
        
        DispatchQueue.main.async {
            if self.statusLabelValue.isEmpty {
                self.statusLabelValue = "Buscando la unidad más cercana"
                self.statusLabel.text = self.statusLabelValue
            } else {
                self.statusLabel.text = self.statusLabelValue
            }
        }
        
        if !self.confirmationVisible {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(10) ) {
                self.openConfirmation()
            }
        }
    }
    
    func openConfirmation() {
        DispatchQueue.main.async {
            self.confirmationVisible = true
            self.present(self.alert, animated: true, completion: nil)
        }
    }
    
    public func hideAlert() {
        DispatchQueue.main.async {
            if self.confirmationVisible {
                self.alert.dismiss(animated: true, completion: nil)
                self.confirmationVisible = false
            }
        }
    }
    
    func cancelService() {
        if let id = self.serviceData?.id {
            self.statusLabel.text = "Cancelando servicio"
            let url_ =  self.cancelURL + String(id)
            webview?.load(URLRequest(url: URL(string: url_)!))
            webview?.isHidden = false
            self.view.bringSubviewToFront(webview!)
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let url_ = navigationResponse.response.url?.absoluteString {
            
            if url_.range(of: "postauth-service-end") != nil {
                webView.isHidden = true
                self.view.sendSubviewToBack(webView)
                self.statusLabel.text = "Servicio cancelado, espere un momento"
            }
            
            if url_.range(of: "postauth-service-error") != nil {
                webView.isHidden = true
                self.view.sendSubviewToBack(webView)
                self.statusLabel.text = "Espere un momento"
                
                if let errorMessage = getQueryStringParameter(url: navigationResponse.response.url?.absoluteString ?? "", param: "e") {
                    Constants.showMessage(msg: errorMessage)
                } else {
                    Constants.showMessage(msg: "Algo ha pasado, intenta nuevamente")
                }
            }
        }
        decisionHandler(.allow)
    }
}
