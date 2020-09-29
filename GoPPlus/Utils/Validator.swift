import UIKit
import WebKit

class Validator: NSObject {
    
    static let requiredError:String = "El campo %s es requerido."
    static let emailError:String = "El campo %s no es una dirección de correo."
    static let passwordError:String = "El campo %s no es una contraseña válida. Mínimo 8 caracteres, máximo 16. Debe contener mínimo: una letra mayúscula, una minúscula, un caracter especial y números. No debe contener acentos ni los siguientes caracteres <>"
    static let numberError:String = "El campo %s no es un valor numérico"
    static let monthError:String = "El campo %s no es un mes válido"
    static let yearError:String = "El campo %s no es un año válido"
    static let cvvError:String = "El campo %s no es un valor válido"
    static let textError:String = "El campo %s no es un texto válido"
    static let nameError:String = "El campo %s no es un nombre válido"
    
    static func matches(pattern: String, value: String) -> Bool {
        return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive).firstMatch(in: value, options: [], range: NSRange(location: 0, length: value.utf16.count)) != nil
    }
    
    static func isEmail(email: String) -> Bool {
        return matches(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", value: email)
    }
    
    static func isName(name: String) -> Bool {
        return matches(pattern: "^[a-zA-Z\\u00C0-\\u017F ]+$", value: name)
    }
    
    static func isAlpha(text: String) -> Bool {
        return matches(pattern: "^[a-z]+$", value: text)
    }
    
    static func isAlphaNumeric(text: String) -> Bool {
        return matches(pattern: "^[a-z0-9]+$", value: text)
    }
    
    static func isAlphaNumericDash(text: String) -> Bool {
        return matches(pattern: "^[A-z0-9@*_\\-]+$", value: text)
    }
    
    static func isUpperCase(text: String) -> Bool {
        return matches(pattern: ".*[A-Z].*", value: text)
    }
    
    static func isLowerCase(text: String) -> Bool {
        return matches(pattern: ".*[a-z].*", value: text)
    }
    
    static func isNumber(text: String) -> Bool {
        return matches(pattern: ".*[0-9].*", value: text)
    }
    
    static func isText(text: String) -> Bool {
        return matches(pattern: "^([A-zÀ-ü0-9 .,:?!¿¡*#])*$", value: text)
    }
    
    static func isValidMonth(text: String) -> Bool {
        return matches(pattern: "^1[0-2]$|^0[1-9]$", value: text)
    }
    
    static func isValidCVV(text: String) -> Bool {
        return matches(pattern: "^[0-9]{3,4}$", value: text)
    }
    
    static func isPassword(password: String) -> Bool {
        let invalidChar = matches(pattern: ".*[\\u00E0-\\u00FC<>`¨´~].*", value: password)
        let hasUpper = isUpperCase(text: password)
        let hasLower = isLowerCase(text: password)
        let hasNumber = isNumber(text: password)
        let hasSpecialChar = matches(pattern: ".*[-[]{}()*+¿?¡!.,^$|#_/='&%$·@|:]].*", value: password)
        let hasLength = password.count >= 8 && password.count <= 16
        
        return !invalidChar && hasUpper && hasLower && hasNumber && hasSpecialChar && hasLength
    }
    
    static func isRequired(text: String) -> Bool {
        return text.count > 0
    }

    static func replaceMessage(name: String, value: String, message: String) -> String {
        var new_message:String = message
            
        new_message = new_message.replacingOccurrences(of: "%s", with: name, options: .literal, range: nil)
        new_message = new_message.replacingOccurrences(of: "%p", with: value, options: .literal, range: nil)

        return new_message
    }
    
}
