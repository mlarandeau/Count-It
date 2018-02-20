# Count-It
A video game frame rate counter for macOS.

NOTE: If you are looking for a built version Count It, please see [Count-It-App](https://github.com/mlarandeau/Count-It-App).

## Overview

Count It is a (mostly) abondoned project originally built by Michael LaRandeau and distributed by Ric Molina of [MacGamerHQ](https://www.macgamerhq.com).  As of the last version, 1.5.0, Count It will run on macOS 10.11, 10.12, and 10.13.  The source code is provided here in hopes that someone would have a desire to update and maintain this app into the future.  As of the release of this last version, Count It is still the only native video game frame rate counter for macOS.

Though Count It was designed specifically with games in mind, it is compatible with any macOS app that uses OpenGL or Metal as it's rendering engine.

## Built With

- XCode 9.2
- Swift 4
- Objective-C
- [Frida](https://www.frida.re) (Instrumentation Framework)
- DTrace (Alternative Instrumentation framework)
- SQLite (for interfacing with a game platform database)


## Architecture

Count It was originally built to use DTrace as the instrumentation tool to perform the actual frame rate tracking.  It now uses Frida by default, but DTrace can still be explicitly enabled in the app preferences window.  The overall app architecture was shaped by the fact that DTrace must be run as root.  Therefore, Count It consists of 3 targets:

1. Count_It: This is the user facing app
2. MLaRandeau.Count-It-TraceHelper: This is a privileged helper tool that performs the frame rate tracking when DTrace is enabled.  By DTrace is not enabled, it is used simply as a bridge to the target MLaRandeau.Count-It-FPSHelper.
3. MLaRandeau.Count-It-FPSHelper: Displays a window with the current frame rate.  This exists as a seperate target to get around the limitations of how windows are handled in spaces in macOS.

The three targets communicate using XPC.  More speciifically, Count_It launches MLaRandeau.Count-It-TraceHelper as a mach service and creates an XPC connection with it.  Count_It then launches MLaRandeau.Count-It-FPSHelper.  However, MLaRandeau.Count-It-FPSHelper is not an XPC service, and therefore an XPC connection cannot be created with it directly.  Instead, MLaRandeau.Count-It-FPSHelper forms an XPC connection with MLaRandeau.Count-It-TraceHelper once it launches and then passes it a token that is then passed back to the primary Count_It target through the original XPC connection.  Count_It can then use the token to form an XPC connection with MLaRandeau.Count-It-FPSHelper.

## Setup

Count It is heavily dependent on the installation of a priviliged helper tool that is installed using SMJobBless.  Therefore, the project must be signed with an Apple Developers license and each target must have the appropriate key/value pairs in their Info.plist file.

1. Count_It uses the SMPrivilegedExecutables key
2. MLaRandeau.Count-It-TraceHelper uses the SMAuthorizedClients key.  This must contain an entry for both Count_It and MLaRandeau.Count-It-FPSHelper targets.
3. MLaRandeau.Count-It-FPSHelper uses SMPriviligedExecutables key

The values for these keys have been removed from each Info.plist file because they contain information about the developers signing certificate.  You will need to set up the values for each key using your own developer license.  For more information on setting up the project to support SMJobBless with your developer license, please refer to the Apple example [here](https://developer.apple.com/library/content/samplecode/SMJobBless/Introduction/Intro.html).

## Instrumentation

By default, Count It uses [Frida](https://www.frida.re) as its intrumentation back end to perform the actual frame rate tracking.  The primary benefit of Frida is that it runs at the user level.  However, a fair number of games will crash when using Frida.  Therefore, you can still fall back to using DTrace as the instrumentation backend by enabling it through the "Advanced" tab of Count It's preference window.  We have yet to come across an OpenGL or Metal based game that is incompatible with Count It when using DTrace.    However, you must completely or partially disable System Integrity Protection for DTrace to function.  Instructions on how to do so are in the preference window of Count It.

## Areas for Improvement

1. User Interface: The interface is fairly bland and could greatly benefit from an updated look.  Streamlining/simplifying the search and addition of games to the users library would also be very beneficial since those were the majority of support questions that I was answering.
2. Data Storage:  User preferences are stored in User Defaults, and all data is persisted as archived objects in files.  Count It initially only needed to store a list of games with a limited amount of related information.  Eventually we added support for recording game sessions, however, the way we stored data never got updated to support all of the extra data.  A more robust data storage solution like Core Data would be beneficial.
3. Legacy Code: Count It was originally built on Mavericks (10.9) using Swift 1.  It now uses Swift 4 and requires macOS 10.11 or newer, but there were not significant updates to the code base at each step.  Combine that with the fact that I was still fairly new to Swift and Mac development when I started and the code quality leaves a lot to be desired.

## Authors

- Michael LaRandeau (Development and Design)
- Ric Molina (Original Concept and Distribution)
- Camilo López-Cristoffanini (Testing and Additional Design)
- Maty Aguiló (App Icon Design)

## Licence

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
