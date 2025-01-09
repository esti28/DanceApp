### DanceApp

# Precomputing reference video pose

The script takes 2 arguments: 
1) the path to the video file on which to perform pose detection
2) the path to the file to which the poses and timestamps are to be saved

- Run the pose detection executable `./DetectReferencePose <path-to-video> <path-to-save-data>`
- Alternatively compile the script `swiftc -parse-as-library DanceApp/DetectReferencePose.swift -o <executable-name>` and run the executable as `./<executable-name> <path-to-video> <path-to-save-data>` 