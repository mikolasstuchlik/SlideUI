# SlideUI

Slides made in `SlideUI` leverage the power of `SwiftUI` allowing you to presesent Web, Code and more on a single Prezi-like plane!

![Demo](doc/demo.gif)

## What is the `SlideUI`

`SlideUI` is a Swift Package, that provides set of predefined `SwiftUI` Views and types allowing you to compose a presentation that is able to compile code, execute `SwiftUI` Views, integrate Web View and anything the `SwiftUI` can do.

### Is `SlideUI` for me, or should I stick with Keynote?

`SlideUI` is useful, when you want to save some precious time during the presentation - either by integrating resources directly to your presentation or making things just a little bit more clear by smart organization of slides on the Prezi-like plane.

On the other hand, if your presentation is text/image heavy, you don't have any live coding to show or you're not familiar with `SwiftUI`, you're going to be better served by conventional software, just like Keynote.
Also remember, that the presentation is a running program and an error in your code may crash the presentation. I always double-check my live coding examples before the talk.

## Creating a new project

In order to run `SlideUI`, you will need the macOS 13 or newer.

### Install templates and create project
 - The project contains Project and Slide templates in the directory `Templates`. Copy the contents of the `Templates` directory to Xcode default template directory:
```
cp -r /path/to/SlideUI/Templates/* ~/Library/Developer/Xcode/Templates
```

 - Open `Xcode`, select `File -> New -> Project`. In template popup select category "Other" and "Slide App".
 - Give name to your project and select Team `none`.
 - The first line contains `#error` line. Copy link to the SlideUI repository and delete the line.
 ```swift
 `#error("Add Swift Package https://github.com/mikolasstuchlik/SlideUI.git")`
 ```
 - Add the SlideUI Package Dependency from branch `master` and add all targets provided by the SlideUI package.
 - Ensure, that in `Signing & Capabilites` ensure, that `Signing Certificate` is set to `Sign to Run Locally`

### Run the presentation
Run the presentation by using Compile and Run. (Notice, that in some cases it might be beneficial to build the presentation for Release.)

The application will launch a windows called Control Panel. The presentation itself is launched by the big green "play" button.

If your presentation contains some instances of `SwitchView`, you may want to generate thumbnail by clicking "Reload Previews" in the Control Panel - **after the presentation is launched and resized.**

## Usage

### Overview - important types
The three most important types of the `SlideUI` are `Slide`, `Background` and `Focus`. All `Slide` views have equal size.
 - `Slide` is a type of `SwiftUI.View`, that is used to create a slide in our presentation.
 - `Background` is a type of `SwiftUI.View`, that is optimized for decorating your presentation with additional resources like shapes, images etc. Unlike `Slide`, a `Background` allows you to create the view as big or small as you want.
 - `Focus` is an element of ordered array - it allows you to specify the order in which you want to go through your slides.
 
 All types of `Slide`, `Background` and instances of `Focus` must be added to the `App.swift` file.
 
 ```swift
 private let backgrounds: [any Background.Type] = [
    ABackground.self,
]

private let slides: [any Slide.Type] = [
    TitleSlide.self,
]

// @focuses(focuses){
private var focuses: [Focus] = [
    Focus(kind: .specific([TitleSlide.self])),
    Focus(kind: .unbound(Camera(offset: CGVector(dx: 0.0, dy: 0.0), scale: 0.2225)))
]
// }@focuses(focuses)
 ```

(Note, the `// @annotation` is used for optional code generation tool.)

### Adding a new `Slide` or `Background`
All `Slide` types should be stored somewhere in the `Slides` directory. All `Background` types should be stored somewhere in `Background` directory.

If you want to create a new `Slide` (or `Background`), in Xcode select `File -> New -> File`, select `macOS` template category. There in category "Slides" and "Backgrounds" you'll find various templates for your slides and backgrounds.

Do not forget to add your `Slide` (or `Background`) types to the `slides` (or `backgrounds`) array in the `App.swift`.

### Adding new focus
You may add a new step to the pass through the presentation by adding new instance of `Focus` into the array `focuses` in the `App.swift`. You may either select a specific position of the camera by creating an `.unbound` focus, or focus on one (or more) slide, by creating a `.specific` focus.

### Execution checklist
When running the presentation, follow recommended checklist

  - Run the application 
  - Window with "Control Panel" opens
  - Click on the greep "Play" button to run the slides
  - Window with "Presentation" opens
  - Resize the "Presentation" window to it's correct size
  - In "Control Panel" window hit "Reload Previews" button next to "Play" button (this generates thumbnails for Toggle views)
  - Go to "Presentation" window and hit "esc" key, so the First Responders are resseted (I'm unable to reset First Responder `onAppear`)
  - Now the app is in "Presentation" mode and "forward" and "backward" events are available

### User input modes overview

The presentation has following modes wich can be in effect simultaneously:

 - "Presentation" and "Editor" mode
 - "Editing..." and "Non-Editing" mode
 - "Camera free roam" and "Fixed camera" mode
 
#### "Presentation" and "Editor" mode
Switched by segmented control in the "Control Panel" window. Allows you to change the purpose of the application.

 - "Presentation" mode (default) optimized for running the slides.
 - "Editor" mode is an experimental mode, that allows you to rearrange the order, delete and add Focuses. The editor mode also allows you to edit Hints, emmit generated code from the current runtime state and move slides by using cursor in "Camera free roam" mode. Notice, that "Editor" mode suffers from **significant** performance issues.
 
#### "Editing..." and "Non-Editing" mode
Controls the event capture engine of the presentations. Captured events are following
 
 - Space bar and Enter -> Forward gesture (moves focus forward)
 - Backspace -> Backward gesture (moves focus backward)
 - Esc -> Ends user input
 
The "Editing..." mode is state, when the *First Responder* is *not* the window itself - meaning, some button or text field are in the *First Responder* state. If the "Editing..." mode is active, all input (except for hitting the Esc key) is forwarded to the current *First Responder*.

The "Editing..." mode is active, when there is a text `"Editing..."` in the right-bottom corner of the "Presentation" window.

#### "Camera free roam" and "Fixed camera" mode
"Camera free roam" is a mode, when moving the cursor towards the edges of the "Presentation" window also move the camera. Scroll wheel events also change the focus. Notice, that this mode has **significant** performance issues. 

The "Camera free roam" is not available, unless you click the "icon with lock" in the bottom right corner of the "Presentation" window. If the icon is red, the "Camera free roam" mode can be entered via "double-click". 

The "Camera free roam" mode can be exitted either by hitting "Esc", or double-clicking. If a Slide of hit when "Camera free roam" mode was exitted, the Slide will be focused.

## Examples

I have updated and published my presentation which take advantage of SlideUI. Those presentations are all in Czech.

[SlideUI seznámení](https://github.com/mikolasstuchlik/slides-slideui)

[Sestavování projektu - Hlavičky a linkování](https://github.com/mikolasstuchlik/slides-link)

[String processing a regulární výrazy](https://github.com/mikolasstuchlik/slides-string)

## Further development

The `SlideUI` was created for one-time usage, but over time grew so I have decided to release it to the public. I have created the `SlideUI`, because I don't have much opportunities to work with `SwiftUI` and I wanted to try it out. Therefore, some features are poorly implemented, or broken or have poor performance. 

I will appreciate any help with the development and accept any reasonable Pull Request. 

There is a list of currently tracked issues and feature ideas.

MUST HAVE:
 - Refactor problematic feautres (editor, free cam, ...) and remove unneeded features
 - PDF mode

MUST FIX:
 - Disable double-click in unrelated window

NICE TO HAVE:
 - Add the posibility to save file from editor as executable
 - Optimize input fields for numbers
 - Separate `SlideVaporized` module to a different repository
 - Separate `SlideUIViews` module to a different repository

FIX:
- Fix freecam edge-scroll performance hit
- Fix freecam scaling performance hit
- Fix freecam movement when moving a slide in editor mode
- Fix performance degradation in editor mode
- Investigate strange scrolling behavior of editor

Future Directions:
 - Use declaration and expression macros instead of immutable arrays (Or runtime reflection metadata)
 - Provide API to render shapes into images and save resources.
