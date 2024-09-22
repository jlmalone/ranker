import Foundation
import SwiftUI


// TODO this is now crashing sort it out
//Failed to request default share mode for fileURL:file:///Users/joseph.malone/Library/Developer/CoreSimulator/Devices/4DE38375-3220-4ED5-A84D-35205FAD1371/data/Containers/Data/Application/6FAD5243-30E4-42E4-8AF0-1E5D05494FFF/Documents/db_full_words.sqlite3 error:Error Domain=NSOSStatusErrorDomain Code=-10814 "(null)" UserInfo={_LSLine=1608, _LSFunction=runEvaluator}
//Only support loading options for CKShare and SWY types. *** I dont know wht this is or where I come up with that. Help educate me***
//error fetching item for URL:file:///Users/joseph.malone/Library/Developer/CoreSimulator/Devices/4DE38375-3220-4ED5-A84D-35205FAD1371/data/Containers/Data/Application/6FAD5243-30E4-42E4-8AF0-1E5D05494FFF/Documents/db_full_words.sqlite3 : Error Domain=NSCocoaErrorDomain Code=256 "The file couldn’t be opened."
//Collaboration: error loading metadata for documentURL:file:///Users/joseph.malone/Library/Developer/CoreSimulator/Devices/4DE38375-3220-4ED5-A84D-35205FAD1371/data/Containers/Data/Application/6FAD5243-30E4-42E4-8AF0-1E5D05494FFF/Documents/db_full_words.sqlite3 error:Error Domain=NSFileProviderInternalErrorDomain Code=0 "No valid file provider found from URL file:///Users/joseph.malone/Library/Developer/CoreSimulator/Devices/4DE38375-3220-4ED5-A84D-35205FAD1371/data/Containers/Data/Application/6FAD5243-30E4-42E4-8AF0-1E5D05494FFF/Documents/db_full_words.sqlite3." UserInfo={NSLocalizedDescription=No valid file provider found from URL file:///Users/joseph.malone/Library/Developer/CoreSimulator/Devices/4DE38375-3220-4ED5-A84D-35205FAD1371/data/Containers/Data/Application/6FAD5243-30E4-42E4-8AF0-1E5D05494FFF/Documents/db_full_words.sqlite3.}
//Error acquiring assertion: <Error Domain=RBSServiceErrorDomain Code=1 "(originator doesn't have entitlement com.apple.runningboard.primitiveattribute AND originator doesn't have entitlement com.apple.runningboard.assertions.frontboard AND target is not running or doesn't have entitlement com.apple.runningboard.trustedtarget AND Target not hosted by originator)" UserInfo={NSLocalizedFailureReason=(originator doesn't have entitlement com.apple.runningboard.primitiveattribute AND originator doesn't have entitlement com.apple.runningboard.assertions.frontboard AND target is not running or doesn't have entitlement com.apple.runningboard.trustedtarget AND Target not hosted by originator)}>
//connection invalidated
//Created table or already exists.
//Column name: 3, Type: notable, Not null: INTEGER, Default Value: 1, Primary Key: 0
//Column name: 4, Type: reviewed, Not null: INTEGER, Default Value: 1, Primary Key: 0
//Created table or already exists.
//Column name: 3, Type: notable, Not null: INTEGER, Default Value: 1, Primary Key: 0
//Column name: 4, Type: reviewed, Not null: INTEGER, Default Value: 1, Primary Key: 0
//This app has crashed because it attempted to access privacy-sensitive data without a usage description.  The app's Info.plist must contain an NSMicrophoneUsageDescription key with a string value explaining to the user how the app uses this data.


//The above notes might have already been solved and can possibly be cleaned up
//TODO I guess this is the actual displayed wrapper of the Recorder widget and Associated text.
//Need to test and check that the associated ideas are getting saved. This may relieve responsibility from other files
    //like notes i put in the records.


struct AssociatedIdeasView: View {
    let word: String  // The word passed from the previous screen

    @State private var associatedWord: String = ""  // State to hold the input


    var body: some View {
        VStack {
            // Title at the top displaying the word
            Text("\(word)")
                .font(.largeTitle)
                .padding()

            Spacer()  // Pushes content to the top and bottom


            TextField("Enter associated word", text: $associatedWord)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Spacer()  // Pushes content to the top and bottom


            Text("\(word)")
                .padding()

            RecorderWidgetView(seedWord: word)

            Spacer()

            // "Done" button at the bottom
            Button(action: {
                // TODO: Save the data to the database
                // For now It just shows a confirmation dialog listing:
                //the filename for the recording if it exists
                //the filename for the transcript in it exists
                //the truncated version of the Textfield text that the user input

                print("Save associated ideas for \(word)")  // Debug print
            }) {
                Text("Done")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)  // Space from the bottom of the screen
        }
        .navigationBarTitleDisplayMode(.inline)  // Shows title inline in the navigation bar
    }
}

