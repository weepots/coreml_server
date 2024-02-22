# CoreML Rest APIs
This project aims to create RestAPIs from CoreML models. CoreML models need to be run by Apple's proprietary language Swift. Therefore, we can use the Vapor Framework in Swift
to create a server where the CoreML models are deployed and can be accessed with HTTP protocols. 

This project was developed with help of these 2 repositories:

CoreML Zoo for CoreML converted models

https://github.com/john-rocky/CoreML-Models

CoreML Helpers

https://github.com/hollance/CoreMLHelpers

## Setting Up
### 1. Git clone repository
``` git clone <link> ```

### 2. Download ML models
Background Remover   
U2Net: https://github.com/john-rocky/CoreML-Models?tab=readme-ov-file#u2net  

Super Resolution   
realesrgan512: https://github.com/john-rocky/CoreML-Models?tab=readme-ov-file#real-esrgan  

Text 2 Image  
StableDiffusion1.5: https://github.com/john-rocky/CoreML-Models?tab=readme-ov-file#stable-diffusion-v1-5

### 3. Compile the ML models
We need to manually execute the compile process for the mlmodels as we do not have a .xcodeproj file due to the Vapor Framework. Projects with the .xcodeproj file do not need this step since the .mlmodel will automatically compile  
Run these 2 commands execute the compile process   
```
xcrun coremlcompiler compile <path+modelname.mlmodel> <output folder path>

xcrun coremlcompiler generate <path+modelname.mlmodel> --language Swift <output folder path>
```
Note: You can use . as the output folder path to compile in the same folder

*** IMPORTANT ***   
Delete the .mlmodel file after compiling so that the build process for xcode will not throw any errors.


### 4. Begin
Go to the macosai repository and start the frontend server to begin using this backend
