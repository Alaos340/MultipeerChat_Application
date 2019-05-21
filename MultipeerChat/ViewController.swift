//
//  ViewController.swift
//  MultipeerChat
//
//  Created by Iskandre Muchery on 19/05/2019.
//  Copyright © 2019 Iskandre Muchery. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    var PeerID:MCPeerID!
    var Session:MCSession!
    var AdvertiserAssistant:MCAdvertiserAssistant!

    @IBOutlet weak var TextMessageView: UITextView!
    @IBOutlet weak var InputMessageView: UITextField!
    @IBOutlet weak var SendButton: UIButton!
    @IBOutlet weak var ConnectButton: UIBarButtonItem!

    var send:String!
    var receive:String!
    var host:Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
        PeerID = MCPeerID(displayName: UIDevice.current.name)
        Session = MCSession(peer: PeerID, securityIdentity: nil, encryptionPreference: .required)
        Session.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.removeKeyboard))
        view.addGestureRecognizer(tap)
        
        SendButton.isEnabled = false
        TextMessageView.isEditable = false
        host = false
        Session.disconnect()
    }
    
    @objc func removeKeyboard(_ sender: UITapGestureRecognizer)
    {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func SendButtonPressed(_ sender: Any) {
        if InputMessageView.text != "" {
            send = "\n\(PeerID.displayName): \(InputMessageView.text!)\n"
            let message = send.data(using: String.Encoding.utf8, allowLossyConversion: false)
            
            do {
                try self.Session.send(message!, toPeers: self.Session.connectedPeers, with: .reliable)
            } catch {
                print("Error: message not sent. Please try again")
            }
            TextMessageView.text = TextMessageView.text + "\n\(PeerID.displayName): \(InputMessageView.text!)\n"
            InputMessageView.text = ""
        } else {
            let emptyAlert = UIAlertController(title: "No message entered", message: nil, preferredStyle: .alert)
            emptyAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(emptyAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func ConnectButtonPressed(_ sender: Any) {
        if Session.connectedPeers.count == 0 && !host {
            let ConnectActionSheet = UIAlertController(title: "Multipeer Chat", message: "Host or Join a chat?", preferredStyle: .actionSheet)
            ConnectActionSheet.addAction(UIAlertAction(title: "Host", style: .default, handler: {
                (action:UIAlertAction) in
                
                self.AdvertiserAssistant = MCAdvertiserAssistant(serviceType: "None", discoveryInfo: nil, session: self.Session)
                self.AdvertiserAssistant.start()
                self.host = true
            }))
            
            ConnectActionSheet.addAction(UIAlertAction(title: "Join", style: .default, handler: {
                (action:UIAlertAction) in
                
                let joined = MCBrowserViewController(serviceType: "None", session: self.Session)
                joined.delegate = self
                self.present(joined, animated: true, completion: nil)
            }))
            
            ConnectActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(ConnectActionSheet, animated: true, completion: nil)
            
        } else if Session.connectedPeers.count == 0 && host {
            let wait = UIAlertController(title: "Waiting...", message: "Waiting for someone to join chat", preferredStyle: .actionSheet)
            wait.addAction(UIAlertAction(title: "Disconnect", style: .destructive, handler: {
                (action) in
                self.Session.disconnect()
                self.host = false
            }))
            
            wait.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(wait, animated: true, completion: nil)
            
        } else {
            let disconnect = UIAlertController(title: "Are you certain you want to disconnect", message: nil, preferredStyle: .actionSheet)
            disconnect.addAction(UIAlertAction(title: "Disconnect", style: .destructive, handler: {
                (action:UIAlertAction) in
                self.Session.disconnect()
            }))
            disconnect.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(disconnect, animated: true, completion: nil)
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("\(PeerID.displayName) connected in chat.")
        case MCSessionState.connecting:
            print("\(PeerID.displayName) connecting in chat.")
        case MCSessionState.notConnected:
            print("\(PeerID.displayName) failed to connect.")
        @unknown default:
            print("Fatal error")
        }
        if session.connectedPeers.count == 0 {
            DispatchQueue.main.async {
                self.SendButton.isEnabled = false
            }
        } else {
            DispatchQueue.main.async {
                self.SendButton.isEnabled = true
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.receive = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)! as String
            self.TextMessageView.text = self.TextMessageView.text + self.receive
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
}

