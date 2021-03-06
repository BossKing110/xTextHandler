//
//  xTextModifier.swift
//  xTextHandler
//
//  Created by cyan on 16/7/4.
//  Copyright © 2016年 cyan. All rights reserved.
//

import XcodeKit
import AppKit

class xTextModifier {

    /// Regular expressions
    static let xTextHandlerStringPattern    = "\"(.+)\""                    // match "abc"
    static let xTextHandlerHexPattern       = "([0-9a-fA-F]+)"              // match 00FFFF
    static let xTextHandlerRGBPattern       = "([0-9]+.+[0-9]+.+[0-9]+)"    // match 20, 20, 20 | 20 20 20 ...
    static let xTextHandlerRadixPattern     = "([0-9]+)"                    // match numbers
    
    /// Select text with regex
    ///
    /// - parameter invocation: XCSourceEditorCommandInvocation
    /// - parameter pattern:    regex pattern
    /// - parameter handler:    handler
    static func select(invocation: XCSourceEditorCommandInvocation, pattern: String?, handler: xTextModifyHandler) {
        
        var regex: RegularExpression?
        
        if pattern != nil {
            do {
                try regex = RegularExpression(pattern: pattern!, options: .caseInsensitive)
            } catch {
                xTextLog(string: "Create regex failed")
            }
        }
        
        // enumerate selections
        for i in 0..<invocation.buffer.selections.count {
            
            let range = invocation.buffer.selections[i]
            // match clipped text
            let match = xTextMatcher.match(selection: range as! XCSourceTextRange, invocation: invocation)
            
            if match.clipboard { // handle clipboard text
                if match.text.characters.count > 0 {
                    let pasteboard = NSPasteboard.general()
                    pasteboard.declareTypes([NSPasteboardTypeString], owner: nil)
                    pasteboard.setString(handler(match.text), forType: NSPasteboardTypeString)
                }
                continue
            }
            
            if match.text.characters.count == 0 {
                continue
            }
            
            // handle selected text
            var texts: Array<String> = []
            if regex != nil { // match using regex
                regex!.enumerateMatches(in: match.text, options: RegularExpression.MatchingOptions(rawValue: 0), range: match.range, using: { (result, flags, stop) in
                    if let range = result?.range(at: 1) {
                        texts.append((match.text as NSString).substring(with: range))
                    }
                })
            } else { // match all
                texts.append((match.text as NSString).substring(with: match.range))
            }
            
            if texts.count == 0 {
                continue
            }
            
            var replace = match.text
            for text in texts {
                // replace each matched text with handler block
                if let textRange = replace.range(of: text) {
                    replace.replaceSubrange(textRange, with: handler(text))
                }
            }
            
            // separate text to lines using newline charset
            let lines = replace.components(separatedBy: NSCharacterSet.newlines)
            // update buffer
            invocation.buffer.lines.replaceObjects(in: NSMakeRange(range.start.line, range.end.line - range.start.line + 1), withObjectsFrom: lines)
            // cancel selection
            let newRange = XCSourceTextRange()
            newRange.start = range.start
            newRange.end = range.start
            invocation.buffer.selections[i] = newRange
        }
    }
    
    /// Select any text
    ///
    /// - parameter invocation: XCSourceEditorCommandInvocation
    /// - parameter handler:    handler
    static func any(invocation: XCSourceEditorCommandInvocation, handler: xTextModifyHandler) {
        self.select(invocation: invocation, pattern: nil, handler: handler)
    }
    
    /// Select numbers
    ///
    /// - parameter invocation: XCSourceEditorCommandInvocation
    /// - parameter handler:    handler
    static func radix(invocation: XCSourceEditorCommandInvocation, handler: xTextModifyHandler) {
        self.select(invocation: invocation, pattern: xTextHandlerRadixPattern, handler: handler)
    }
    
    /// Select hex color
    ///
    /// - parameter invocation: XCSourceEditorCommandInvocation
    /// - parameter handler:    handler
    static func hex(invocation: XCSourceEditorCommandInvocation, handler: xTextModifyHandler) {
        self.select(invocation: invocation, pattern: xTextHandlerHexPattern, handler: handler)
    }
    
    /// Select RGB color
    ///
    /// - parameter invocation: XCSourceEditorCommandInvocation
    /// - parameter handler:    handler
    static func rgb(invocation: XCSourceEditorCommandInvocation, handler: xTextModifyHandler) {
        self.select(invocation: invocation, pattern: xTextHandlerRGBPattern, handler: handler)
    }
}
