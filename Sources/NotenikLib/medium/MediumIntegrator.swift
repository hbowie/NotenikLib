//
//  MediumIntegrator.swift
//
//  Created by Herb Bowie on 12/28/20.
//
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

public class MediumIntegrator {
    
    var ui:   MediumUI
    var info: MediumInfo
    
    let endpointPrefix = "https://api.medium.com/v1"
    let userDetailsSuffix = "/me"
    let users = "/users/"
    let posts = "/posts"
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    var userData = MediumUser()
    var postResponse = MediumPostResponse()
    
    /// Initialize with a caller and in info object.
    public init(ui: MediumUI, info: MediumInfo) {
        self.ui = ui
        self.info = info
    }
    
    /// Attempt to authenticate. 
    public func getUserDetails() {
        
        guard info.authToken.count > 0 else {
            info.status = .tokenNeeded
            info.msg = "Medium Integration Token Needed"
            ui.mediumUpdate()
            return
        }
        
        // Create URL
        let url = URL(string: endpointPrefix + userDetailsSuffix)
        guard let requestUrl = url else {
            info.status = .internalError
            info.msg = "Could not make the requiredURL"
            ui.mediumUpdate()
            return
        }
        
        info.status = .authenticationStarted
        info.msg = "Working on Authentication..."
        ui.mediumUpdate()

        // Create URL Request
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        request.setValue("Bearer " + info.authToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json",         forHTTPHeaderField: "Content-Type")
        request.setValue("application/json",         forHTTPHeaderField: "Accept")
        request.setValue("utf-8",                    forHTTPHeaderField: "Accept-Charset")

        // Send HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (gotData, response, error) in
            
            var proceeding = true
            
            // Check if Error took place
            if let error = error {
                self.info.status = .authenticationFailed
                let errorStr = String(describing: error)
                if errorStr.contains("The Internet connection appears to be offline.") {
                    self.info.msg = "The Internet connection appears to be offline."
                } else {
                    self.info.msg = "Authentication error: \(error)"
                }
                proceeding = false
            }
            
            if proceeding {
                // Read HTTP Response Status code
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200 {
                        self.info.status = .authenticationFailed
                        self.info.msg = "Unexpected HTTP URL Response code of \(response.statusCode)"
                        proceeding = false
                    }
                } else {
                    self.info.status = .internalError
                    self.info.msg = "No HTTP URL Response code returned"
                    proceeding = false
                }
            }
            
            // Convert HTTP Response Data to a simple String
            if proceeding {
                if let gotData = gotData {
                    do {
                        self.userData = try self.decoder.decode(MediumUser.self, from: gotData)
                        self.info.status = .authenticationSucceeded
                        self.info.userid = self.userData.data.id
                        self.info.username = self.userData.data.username
                        self.info.name = self.userData.data.name
                        self.info.url = self.userData.data.url
                        self.info.imageURL = self.userData.data.imageUrl
                        self.info.msg = "Authentication complete"
                    } catch {
                        self.info.status = .internalError
                        self.info.msg = "JSON decoding falied due to \(error)"
                        proceeding = false
                    }
                } else {
                    self.info.status = .authenticationFailed
                    self.info.msg = "Couldn't access response data"
                    proceeding = false
                }
            }
            
            DispatchQueue.main.async {
                self.ui.mediumUpdate()
            }
        }
        task.resume()
    }
    
    /// Attempt to submit a note to Medium as a new story.
    public func submitPost() {
        
        guard info.authToken.count > 0 else {
            info.status = .tokenNeeded
            info.msg = "Medium Integration Token Needed"
            ui.mediumUpdate()
            return
        }
        
        guard info.userid.count > 0 else {
            info.status = .authenticationNeeded
            info.msg = "Authentication Needed"
            ui.mediumUpdate()
            return
        }
        
        guard let note = info.note else {
            info.status = .internalError
            info.msg = "No Note Provided"
            ui.mediumUpdate()
            return
        }
        
        // Create URL
        let url = URL(string: endpointPrefix + users + info.userid + posts)
        guard let requestUrl = url else {
            info.status = .internalError
            info.msg = "Could not make the post URL successfully"
            ui.mediumUpdate()
            return
        }
        
        info.status = .postStarted
        info.msg = "Submitting Post..."
        ui.mediumUpdate()

        // Create URL Request
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer " + info.authToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json",         forHTTPHeaderField: "Content-Type")
        request.setValue("application/json",         forHTTPHeaderField: "Accept")
        request.setValue("utf-8",                    forHTTPHeaderField: "Accept-Charset")
        
        let post = MediumPost()
        post.title = note.title.value
        post.contentFormat = "markdown"
        post.content = "# \(note.title.value)\n\n" + note.body.value
        post.publishStatus = "draft"
        do {
            let jsonData = try encoder.encode(post)
            request.httpBody = jsonData
        } catch {
            info.status = .internalError
            info.msg = "Unable to encode post due to \(error)"
            ui.mediumUpdate()
            return
        }

        // Send HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (gotData, response, error) in
            
            var proceeding = true
            
            // Check if Error took place
            if let error = error {
                self.info.status = .postFailed
                let errorStr = String(describing: error)
                if errorStr.contains("The Internet connection appears to be offline.") {
                    self.info.msg = "The Internet connection appears to be offline."
                } else {
                    self.info.msg = "Post error: \(error)"
                }
                proceeding = false
            }
            
            if proceeding {
                // Read HTTP Response Status code
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 201 {
                        self.info.status = .postFailed
                        self.info.msg = "Unexpected HTTP URL Response code of \(response.statusCode)"
                        proceeding = false
                    }
                } else {
                    self.info.status = .internalError
                    self.info.msg = "No HTTP URL Response code returned"
                    proceeding = false
                }
            }
            
            // Convert HTTP Response Data
            if proceeding {
                if let gotData = gotData {
                    do {
                        self.postResponse = try self.decoder.decode(MediumPostResponse.self, from: gotData)
                        self.info.status = .postSucceeded
                        self.info.postURL = self.postResponse.data.url
                        self.info.msg = "Draft Successfully Submitted"
                    } catch {
                        self.info.status = .internalError
                        self.info.msg = "JSON decoding falied due to \(error)"
                        proceeding = false
                    }
                } else {
                    self.info.status = .postFailed
                    self.info.msg = "Couldn't access response data"
                    proceeding = false
                }
            }
            
            DispatchQueue.main.async {
                self.ui.mediumUpdate()
            }
        }
        task.resume()
    }
}
