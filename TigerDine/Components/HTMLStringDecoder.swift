//
//  HTMLStringDecoder.swift
//  TigerDine
//
//  Created by Campbell Bagley on 8/18/26.
//

import Foundation

// Some handle sample code for decoding HTML character codes in text so that I don't have to
// manually handle them everwhere I might encounter them.
extension String {
    func decodingHTMLEntities() -> String {
        guard self.contains("&") else { return self }
        
        var result = self
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        
        if result.contains("&#") {
            let regex = try? NSRegularExpression(pattern: "&#([0-9]+);", options: [])
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            
            regex?.matches(in: result, options: [], range: range).reversed().forEach { match in
                if let numRange = Range(match.range(at: 1), in: result),
                   let codePoint = UInt32(result[numRange]),
                   let scalar = UnicodeScalar(codePoint),
                   let matchRange = Range(match.range, in: result) {
                    result.replaceSubrange(matchRange, with: String(scalar))
                }
            }
        }
        
        return result
    }
}
