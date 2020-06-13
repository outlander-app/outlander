//
//  VirtualViewControllers.swift
//  Outlander
//
//  Created by Joseph McBride on 7/21/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

indirect enum ViewController<Message> {
    case _viewController(View<Message>, useLayoutGuide: Bool)

    func map<B>(_ transform: @escaping (Message) -> B) -> ViewController<B> {
        switch self {
        case let ._viewController(vc, useLayoutGuide): return ._viewController(vc.map(transform), useLayoutGuide: useLayoutGuide)
        }
    }

    static func viewController(_ view: View<Message>, useLayoutGuide: Bool = true) -> ViewController {
        ._viewController(view, useLayoutGuide: useLayoutGuide)
    }
}
