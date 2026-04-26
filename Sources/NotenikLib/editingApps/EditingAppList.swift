//
//  EditingAppList.swift
//  NotenikLib
//
//  Created by Herb Bowie on 4/21/26.
//

import Foundation

public class EditingAppList: Sequence {
    
    public typealias Element = EditingApp
    
    private var apps: [EditingApp] = []
    
    public init() {
        
    }
    
    public func set(concat: String) {
        let appPaths = concat.components(separatedBy: ";;")
        for path in appPaths {
            if !path.isEmpty {
                add(path: path)
            }
        }
    }
    
    public func add(path: String) {
        guard !path.isEmpty else { return }
        let newApp = EditingApp(path: path)
        add(newApp: newApp)
    }
    
    public func add(url: URL) {
        let newApp = EditingApp(url: url)
        add(newApp: newApp)
    }
    
    public func add(newApp: EditingApp) {
        var i = 0
        for existingApp in apps {
            if newApp == existingApp {
                return
            }
            if newApp < existingApp {
                apps.insert(newApp, at: i)
                return
            }
            i += 1
        }
        apps.append(newApp)
    }
    
    public func clear() {
        apps.removeAll()
    }
    
    public var count: Int {
        return apps.count
    }
    
    public var isEmpty: Bool {
        return apps.isEmpty
    }
    
    public func getApp(for name: String) -> EditingApp? {
        guard !name.isEmpty else { return nil }
        for app in apps {
            if name == app.name {
                return app
            }
        }
        return nil
    }
    
    public var concat: String {
        var c = ""
        for app in apps {
            if !c.isEmpty {
                c.append(";;")
            }
            c += app.url.path
        }
        return c
    }
    
    public func makeIterator() -> EditingAppsIterator {
        return EditingAppsIterator(apps: apps)
    }
    
    public func display() {
        print("EditingAppList")
        for app in apps {
            print("  - \(app.name)")
        }
    }
}
