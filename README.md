# Procedurez
Universal iOS app to remind users what the steps are to certain procedurez. Procedurez allows you to create, or import / export steps of procedures that you wish to remember. Steps have names, details and maybe even children (i.e., substeps). With a colorful interface and Swipe to Mark Complete functionality, figuring out how to do a process months / years later is a breeze.

## Installation
The following features might help you install this software:
- Written in Xcode 7.1.1
- Universal app
- Deployment Target 8.4
- CoreData.framework library

## API
Procedurez uses the API from parse.com for importing data from online. 

It uses a JSON format such as the following:

`{"title":"IBOutlets", "details":"How to create Storyboard objects and connect them to view controllers", "position":0, "sectionIdentifier":"Do", "steps": 
[{"title":"Click On Storyboard", "details":"", "position":0, "sectionIdentifier":"Do", "steps": []}]}`

## How to Use Procedurez
Read the "How to Use This App" Procedure on the first page. It will tell you what you need to know in more detail.

Step Creation:
- Create a new Procedure by tapping the Plus button on the Blue table of Procedures.
- Give your Procedure a title by Naming the first step.
- Enter any details, briefly. (Commands should be entered as substeps.)
- Tap the Save button.
- Add substeps by pressing the Plus button.
- Give the substep a title and details.
- Save the substep.
- Add a substep of the substep if you like.
- Return to the parent step to add more siblings of a step.

Basic Use:
- Tap on a Procedure to see the steps.
- Mark the step as Done by swiping on it (left to right) if you like.
- Return it to Do by swiping on it again.
- Tap on a step to see its substeps.

Editing:
- Tap on the Edit button.
- Edit the title in the text field.
- Edit the details in the text view.
- Move the substeps by touching and holding the 3 grab bars, then dragging it to where you prefer.
- Tap the Save button.

Deleting (NON-REVERSIBLE!!!)
- Delete a procedure or a substep (when not editting) by swiping right to left, then tapping the Delete button.
- Delete a procedure or a substep (when editting) by tapping the red circle, then the Delete button that appears.

Exporting:
- Tap the Procedure.
- Tap the Share button (on the Procedure / First-Step title page).
- Choose to send the Procedure by Email or save to Notes. (Creates a JSON formatted string.)
- Send the Email, or save the Note.

Importing via Parse.com:
- Tap the Gear icon on the Blue Procedures table page.
- Select one of the Procedures in the table.
- Make sure the JSON formatted string that appears in the text view is the correct one.
- Tap the Save button.
- Return to the Blue Procedures table page.

Importing by copy and pasting from Notes, an Email body, etc:
- Tap the Gear icon on the Blue Procedures table page.
- Tap the Plus symbol.
- Paste the JSON formatted string into the text view.
- Tap anywhere outside the text view.
- Tap the Save button.
- Return to the Blue Procedures table page.

## Collaboration
If you wish to create a procedure and have it added to the parse.com data so all can share in your thoughtfulness, just follow these steps:
- Export your procedure according to the How to Use This App steps.
- Select how to share it, via Email or Notes, then Email.
- Add Procedurez (at least) to the Subject Line of the Email.
- Send it to ransomkb@yahoo.com.

It will be evaluated and vetted for form and safety. If it passes muster, it will be added to the parse.com data for all to share in.

## Contact 
Send any messages about bugs, issues, requests, praise, etc. to ransomkb@yahoo.com.

## License
Copyright 2015 Ransom Kennicott Barber
