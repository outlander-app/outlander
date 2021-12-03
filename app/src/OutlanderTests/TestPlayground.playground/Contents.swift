import Cocoa

var key = "weaponslists"

var variables: [String: String] = [
    "weapon": "sword",
]

var result: String?
for idx in 0 ..< key.count {
    var test = String(key.dropLast(idx))
    guard let val = variables[test] else {
        continue
    }
    result = val + String(key.dropFirst(test.count))
    break
}

print(result)
