//
//  HandlersCache.swift
//


import Foundation

public typealias CompletionHandler = (_ json: JSON, _ error: CogsResponseError) -> ()

class Handler {
    
    public var closure: CompletionHandler?
    
    public var timestamp: TimeInterval?
    
    public func alive(forTime: Int) -> Bool {
        //check is still alive
        //MARK: TO DO
        return true
    }
}

class HandlersCache {
    
    private var cache:[String : Handler] = [String : Handler]()
    
    public var countLimit: Int = 10000
    
    public var objectAge: Int  = 60 //seconds
    
    public init() { }
    
    public func object(forKey key: Int) -> Handler? {
        //check is it still live
        if let object = cache[String(key)] {
            if object.alive(forTime: objectAge) {
                return cache[String(key)]
            }
        }
        return nil
    }
    
    public func setObject(_ obj: Handler, forKey key: Int) {
        
        guard cache.count < countLimit  else { return }
        
        cache[String(key)] = obj
    }
    
    public func removeObject(forKey key: Int) -> Handler? {
        return cache.removeValue(forKey: String(key))
    }
    
    public func removeAllObjects() {
        cache.removeAll()
    }
    
}
