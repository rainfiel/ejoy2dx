# ejoy2dx
a wrapper of ejoy2d

# usage
### run example
Open project/example/plaform/msvc/build/example.sln with vc2012 or open project/example/platform/ios/example.xcodeproj with xcode

### create your own project
```
cd tools/project_creator
python creator.py your_prj_name
```

then

Open project/your_prj_name/plaform/msvc/build/your_prj_name.sln with vc2012 or open project/your_prj_name/platform/ios/your_prj_name.xcodeproj with xcode
>note: set your own project as startup project in the msvc solution before build

# prerequisites
OpenAL is required for Windows exe, you can download it from here: https://www.openal.org/downloads/oalinst.zip
