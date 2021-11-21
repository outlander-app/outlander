//
//  File.swift
//  Outlander
//
//  Created by Joe McBride on 11/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class ExpressionEvaluator {
    let log = LogManager.getLog("\(ExpressionEvaluator.self)")

    func evaluateLogic(_ input: String) -> Bool {
        guard input.count > 0 else {
            return false
        }

        if let result = input.toBool() {
            return result
        }

        do {
            var result = false
            try ObjC.perform {
                let predicate = NSPredicate(format: input)
                result = predicate.evaluate(with: nil)
            }
            return result
        } catch let error as NSExceptionError {
            log.error("NSPredicate error: \(error.exception.description)")
            return false
        } catch {
            log.error("NSPredicate error: unknown error trying to parse expression '\(input)'")
            return false
        }
    }

    func evaluateValue<T>(_ input: String) -> T? {
        guard input.count > 0 else {
            return nil
        }

        do {
            var result: T?
            try ObjC.perform {
                let expression = NSExpression(format: input)
                result = expression.expressionValue(with: nil, context: nil) as? T
            }
            return result
        } catch let error as NSExceptionError {
            log.error("NSExpression error: \(error.exception.description)")
            return nil
        } catch {
            log.error("NSExpression error: unknown error trying to parse expression '\(input)'")
            return nil
        }
    }
}
