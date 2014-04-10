### Face Detector for iOS

![Camera Page](https://raw.githubusercontent.com/siggb/FaceDetector/master/Sources/Resources/screenshots/IMG_01.PNG "Camera Page")

This project were created for the educational purposes of the course "Systems Administration" ([Vladimir State University](http://vlsu.ru), specialty ID is 230101).

It is a client iOS-application for the face detection (not recognition) and transmitting photos through FTP-protocol. Requires XCode 5 and iOS 7 iPhone. Project runs only on device.

## Requirements

* Xcode 5 or higher
* Apple LLVM compiler
* iOS 7.0 or higher
* ARC

### Example Usage

Step 1: Go to the "Camera Page" and take a photo with detected face (or faces).

Step 2: Next, go to the ["Store Page"](https://raw.githubusercontent.com/siggb/FaceDetector/master/Sources/Resources/screenshots/IMG_02.PNG) and select any photo from your usage history. All photos take by you previously are stored in the internal device MySQL database.

Step 3: On the ["Detail Page"](https://raw.githubusercontent.com/siggb/FaceDetector/master/Sources/Resources/screenshots/IMG_03.PNG) you can resize photo if you want. And, of course, you can share your file through FTP to the server side. The server application called [Rumpus-FTPServer](http://www.maxum.com/Rumpus/). You should run it before the file transferring and change server IP-addres in the current project.

Step 4: When image with detected face (or faces) [will be on the computer](https://raw.githubusercontent.com/siggb/FaceDetector/master/Sources/Resources/screenshots/IMG_04.png) you can co do anything with it.

Step 5: Profit!

## License

Face Detector is available under the MIT license.

Copyright © 2013 Ildar Sibagatov.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
