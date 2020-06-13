//
//  Elm.swift
//  Outlander
//
//  Created by Joseph McBride on 7/21/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

struct Context<Message> {
    let viewController: NSViewController
    let send: (Message) -> Void

    func map<B>(_ transform: @escaping (B) -> Message) -> Context<B> {
        Context<B>(viewController: viewController, send: {
            self.send(transform($0))
        })
    }
}

struct Command<Message> {
    let run: (Context<Message>) -> Void

    func map<B>(_ transform: @escaping (Message) -> B) -> Command<B> {
        Command<B> { context in
            self.run(context.map(transform))
        }
    }
}

enum Subscription<Action> {
    case notification(name: Notification.Name, (Notification) -> Action)
}

final class NotificationSubscription<Action> {
    let name: Notification.Name
    var action: (Notification) -> Action
    let send: (Action) -> Void
    init(_ name: Notification.Name, handle: @escaping (Notification) -> Action, send: @escaping (Action) -> Void) {
        self.name = name
        action = handle
        self.send = send
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [unowned self] note in
            self.send(self.action(note))
        }
    }
}
