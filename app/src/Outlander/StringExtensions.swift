//
//  StringExtensions.swift
//  
//
//  Created by Joseph McBride on 7/18/19.
//

import Foundation

extension String {
  subscript (i: Int) -> Character {
    return self[index(startIndex, offsetBy: i)]
  }
}
