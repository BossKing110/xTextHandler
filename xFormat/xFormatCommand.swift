//
//  xFormatCommand.swift
//  xFormat
//
//  Created by cyan on 16/7/4.
//  Copyright © 2016年 cyan. All rights reserved.
//

import Foundation

class xFormatCommand: xTextCommand {
    override func handlers() -> Dictionary<String, xTextModifyHandler> {
        return [
            "xformat.json": { (text: String) -> (String) in vkBeautify(string: text, type: "json") },
            "xformat.xml": { (text: String) -> (String) in vkBeautify(string: text, type: "xml") },
            "xformat.css": { (text: String) -> (String) in vkBeautify(string: text, type: "css") },
            "xformat.sql": { (text: String) -> (String) in vkBeautify(string: text, type: "sql") },
        ]
    }
}
