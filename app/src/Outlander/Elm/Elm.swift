//
//  Elm.swift
//  Outlander
//
//  Created by Joseph McBride on 7/21/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import Cocoa

struct Context<Message> {
    let viewController: NSViewController
    let send: (Message) -> ()
    
    func map<B>(_ transform: @escaping (B) -> Message) -> Context<B> {
        return Context<B>(viewController: viewController, send: {
            self.send(transform($0))
        })
    }
}

struct Command<Message> {
    let run: (Context<Message>) -> ()
    
    func map<B>(_ transform: @escaping (Message) -> B) -> Command<B> {
        return Command<B> { context in
            self.run(context.map(transform))
        }
    }
}

enum Subscription<Action> {
    case notification(name: Notification.Name, (Notification) -> Action)
}

final class NotificationSubscription<Action> {
    let name: (Notification.Name)
    var action: (Notification) -> Action
    let send: (Action) -> ()
    init(_ name: Notification.Name, handle: @escaping (Notification) -> Action, send: @escaping (Action) -> ()) {
        self.name = name
        self.action = handle
        self.send = send
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [unowned self] note in
            self.send(self.action(note))
        }
    }
}
