//
//  NavigationViewController.swift
//  CostumerView
//
//  Created by Yannick Klose on 23.09.17.
//  Copyright © 2017 Yannick Klose. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import DocuSignSDK
import HyperTrack
import Parse

class NavigationViewController: UIViewController {
    
    @IBOutlet weak var htView: UIView!
    @IBOutlet weak var signButton: UIButton!
    var hyperTrackMap : HTMap? = nil

    private func facetime(phoneNumber:String) {
        if let facetimeURL:NSURL = NSURL(string: "facetime://\(phoneNumber)") {
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(facetimeURL as URL)) {
                application.openURL(facetimeURL as URL)
            }
        }
    }

    func isSDKInitialized() -> Bool{
        if (HyperTrack.getPublishableKey() == nil){
            showAlert(title:"Step 3 is not completed", message: "Please initialize the Hypertrack SDK.")
            return false
        }
        
        
        if(HyperTrack.getPublishableKey() == "YOUR_PUBLISHABLE_KEY"){
            showAlert(title:"Step 3 is not completed", message: "The API key is not correct.If you have the key add it properyly, if you don't get the API Key as described on the repo.")
            return false
        }
        
        if(HyperTrack.getUserId() == nil || HyperTrack.getUserId() == ""){
            showAlert(title:"Step 4 is not completed", message: "Yay the SDK is set up , but the user is not created",buttonTitle: "Create User" ){(action) in
            }
        }
        
        return true
    }

    fileprivate func showAlert(title: String?, message: String?, buttonTitle : String = "OK",handler: ((UIAlertAction) -> Swift.Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let ok : UIAlertAction = UIAlertAction.init(title: buttonTitle, style: .cancel) { (action) in
            if (handler != nil){
                handler!(action)
            }
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        isSDKInitialized()

        hyperTrackMap = HyperTrack.map()
        hyperTrackMap?.enableLiveLocationSharingView = true
        hyperTrackMap?.showConfirmLocationButton = true
        hyperTrackMap?.setHTViewInteractionDelegate(interactionDelegate: self)
        hyperTrackMap?.embedIn(self.htView)
    }
    
    @IBAction func sign(_ sender: Any) {
        DSMManager .login(withUserId: "lenopix@gmail.com"    , password: "asdfasdf123", integratorKey: "f06c1d79-7d6f-4ecc-9b57-2259c585bd53"
        , host: URL(string: "https://demo.docusign.net/restapi")) { (_) in
            let manager = DSMTemplatesManager()
            manager.presentSendTemplateControllerWithTemplate(withId: "221d2fc0-8394-4e35-8639-9de7c34e82c8", tabValueDefaults: ["":""], pdfToInsert: NSData() as Data!, insertAtPosition: DSMDocumentInsertAtPosition.beginning
                , signingMode: DSMSigningMode.online, presenting: self, animated: true, completion: nil)
        }
    }

    @IBAction func facetime(_ sender: Any) {
        facetime(phoneNumber: "+14088215303") //Ralfs phone number
    }
}

extension NavigationViewController:HTViewInteractionDelegate {


    func didSelectLocation(place : HyperTrackPlace?){

        //  Start a Live Location Trip : Step 2. This is the callback which gets called when the user select a location. Create an action and assign it.
        let htActionParams = HyperTrackActionParams()
        htActionParams.expectedPlace = place
        htActionParams.type = "visit"
        htActionParams.lookupId = UUID().uuidString

        HyperTrack.createAndAssignAction(htActionParams, { (action, error) in
            if let error = error {
                print("recieved error while creating and assigning action. error : " + (error.errorMessage))
                return
            }
            if let action = action {

                HyperTrack.trackActionFor(lookUpId: action.lookupId!, completionHandler: { (actions, error) in
                    if (error != nil) {
                        return
                    }
                    if let lookUpId = action.lookupId {
                        // Send lookUpId to parse server
                        let testObject = PFObject(className: "TrackingId")
                        testObject["Id"] = action.lookupId
                        testObject.saveInBackground { (success, failure) in
                            print(success)
                        }
                    }
                })

                return
            }
        })
    }


    func didTapBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func didTapStopLiveLocationSharing(actionId : String){
        //This is the callback when user want to stop the trip. Complete the action

        HyperTrack.completeAction(actionId)
    }

    func didTapShareLiveLocationLink(action : HyperTrackAction){
        if let lookupId = action.lookupId {

            let textToShare : Array = [lookupId]
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            activityViewController.completionWithItemsHandler = { activityType, complete, returnedItems, error in
            }
            self.present(activityViewController, animated: false, completion: nil)

        }
    }

}

