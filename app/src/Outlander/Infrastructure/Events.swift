//
//  Events.swift
//  Outlander
//
//  Created by Joseph McBride on 5/16/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import AppKit
import Foundation

protocol Events2 {
    func post<EventType>(_ event: EventType) where EventType: Event
    func register<EventType>(_ observer: AnyObject, handler: @escaping ((_ event: EventType) -> Void)) where EventType: Event

    func post<EventType>(_ event: EventType) where EventType: StickyEvent
    func register<EventType>(_ observer: AnyObject, handler: @escaping ((_ event: EventType) -> Void)) where EventType: StickyEvent

    func unregister<EventType>(_ observer: AnyObject, _ evt: DummyEvent<EventType>) where EventType: BaseEvent
}

class NulloEvents2: Events2 {
    func post(_: some Event) {}

    func register<EventType>(_: AnyObject, handler _: @escaping ((EventType) -> Void)) where EventType: Event {}

    func post(_: some StickyEvent) {}

    func register<EventType>(_: AnyObject, handler _: @escaping ((_ event: EventType) -> Void)) where EventType: StickyEvent {}

    func unregister(_: AnyObject, _: DummyEvent<some BaseEvent>) {}
}

struct EchoTextEvent: StickyEvent {
    var text: String
    var preset: String?
    var color: String?
    var mono: Bool = false
}

struct EchoTagEvent: StickyEvent {
    var tag: TextTag
}

struct ErrorEvent: Event {
    var error: String
}

struct CommandEvent: Event {
    var command: Command2
}

struct GameCommandEvent: Event {
    var command: Command2
}

struct VariableChangedEvent: Event {
    var key: String
    var value: String
}

struct EmulatedTextEvent: Event {
    var data: String
}

struct LoadLayoutEvent: Event {
    var layout: String
}

struct SaveLayoutEvent: Event {
    var layout: String
}

struct ToggleLayoutSettingsEvent: Event {
}

extension Events2 {
    func echoText(_ text: String, preset: String? = nil, color: String? = nil, mono: Bool = false) {
        let data = EchoTextEvent(text: "\(text)\n".hexDecoededString(), preset: preset, color: color, mono: mono)
        post(data)
    }

    func echoTag(_ tag: TextTag) {
        let evt = EchoTagEvent(tag: tag)
        post(evt)
    }

    func echoError(_ text: String) {
        let evt = ErrorEvent(error: "\(text)\n".hexDecoededString())
        post(evt)
    }

    func sendCommand(_ command: Command2) {
        let evt = CommandEvent(command: command)
        post(evt)
    }

    func sendGameCommand(_ command: Command2) {
        let evt = GameCommandEvent(command: command)
        post(evt)
    }

    func variableChanged(_ key: String, value: String) {
        let evt = VariableChangedEvent(key: key, value: value)
        post(evt)
    }

    func emulateGameText(_ data: String) {
        let evt = EmulatedTextEvent(data: data)
        post(evt)
    }

    func loadLayout(_ layout: String) {
        let evt = LoadLayoutEvent(layout: layout)
        post(evt)
    }

    func saveLayout(_ layout: String) {
        let evt = SaveLayoutEvent(layout: layout)
        post(evt)
    }

    func toggleLayoutSettings() {
        let evt = ToggleLayoutSettingsEvent()
        post(evt)
    }
}

class DummyEvent<T> where T: BaseEvent {}

class SwenEvents: Events2 {
    var storage = SwenStorage()

    func post<EventType>(_ event: EventType) where EventType: Event {
        Swen<EventType>.post(event, in: storage)
    }

    func register<EventType>(_ observer: AnyObject, handler: @escaping ((_ event: EventType) -> Void)) where EventType: Event {
        Swen<EventType>.register(observer, in: storage, handler: handler)
    }

    func post<EventType>(_ event: EventType) where EventType: StickyEvent {
        Swen<EventType>.post(event, in: storage)
    }

    func register<EventType>(_ observer: AnyObject, handler: @escaping ((_ event: EventType) -> Void)) where EventType: StickyEvent {
        Swen<EventType>.register(observer, in: storage, handler: handler)
    }

    func unregister<EventType>(_ observer: AnyObject, _: DummyEvent<EventType>) where EventType: BaseEvent {
        Swen<EventType>.unregister(observer, in: storage)
    }
}
