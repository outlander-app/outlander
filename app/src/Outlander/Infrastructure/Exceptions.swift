//
//  Exceptions.swift
//  Outlander
//
//  Created by Joe McBride on 11/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

public struct NSExceptionError: Swift.Error {
    public let exception: NSException

    public init(exception: NSException) {
        self.exception = exception
    }
}

public enum ObjC {
    public static func perform(workItem: () -> Void) throws {
        let exception = ExecuteWithObjCExceptionHandling {
            workItem()
        }
        if let exception = exception {
            throw NSExceptionError(exception: exception)
        }
    }
}
