import UIKit

class PasswordTextField: UITextField {
    
    override var isSecureTextEntry: Bool {
        didSet {
            if isFirstResponder {
                _ = becomeFirstResponder()
            }
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        
        var startPosition: UITextPosition?
        var endPosition: UITextPosition?
        
        // Remember the place where cursor was placed before switching secureTextEntry
        if let selectedRange = self.selectedTextRange {
            startPosition = selectedRange.start
            endPosition = selectedRange.end
        }

        let success = super.becomeFirstResponder()
        if isSecureTextEntry, let text = self.text {
            self.text?.removeAll()
            insertText(text)
        }
        
        // Put the cursor back
        if let startPosition = startPosition {
            self.selectedTextRange = self.textRange(from: startPosition, to: endPosition ?? startPosition)
        }
        
        return success
    }
}
