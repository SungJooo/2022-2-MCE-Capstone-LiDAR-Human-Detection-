# 2022-2 HGU-MCE Capstone "3D-LiDAR based Human Detection"

## Introduction

​	This repository contains how to train PointPillars[1] model with 3D LiDAR sensor data and utilize it for danger zone proximity warnings. We implemented a warning system at the smart factory which detects a worker who proximates to the hazardous zone.

​	This project was carried out as a 2022-2 MIP study with advisor Prof. Young-Keun Kim.



## Requirements

​	We used XT32 as a 3D LiDAR sensor of HESAI, and the training environment is as follows. 

* OS: Ubuntu 20.04 (doesn't matter)
* CPU: AMD Ryzen 7 3700X 8-Core Processor
* GPU: GeForce RTX 2080 SUPER
* Data: 8,998 Frames (about 30 GB)
* Training Environment: MATLAB 2022a
  * Required Toolbox: Lidar Toolbox, Parallel Computing Toolbox



## Part 1. Training

​	The following instructions would help you to train the PointPillars model. The specific steps are kindly descripted in 'main.m'.

```matlab
doTraining = true;
tempdir = '$ YOUR ROUTE OF TRAINING DATASET'
outputFolder = fullfile(tempdir,'TrainResult');
```

​	First, you need to set the flag as true to train the PointPillars model, and set the temporal route which the training dataset exists. After setting the temporal directory, execute the whole file to train the model. You need to place the sub-functions in the same directory to execute the main statement, and the functions are listed in the 'training' folder.

​	You would meet three big steps that cost your time. The time consuming part is as follows.

```matlab
% Step 1.
35 [croppedPointCloudObj,processedLabels] = cropFrontViewFromLidarData(...
36     lidarData,boxLabels,pointCloudRange);

% Step 2.
55 [trainData,trainLabels] = saveptCldToPCD(trainData,trainLabels,...
56     dataLocation,writeFiles);

% Step 3.
121 if doTraining
...
126 end
```

​	In the environment of our experiment, it costs 10 minutes of each step 1 & 2, and 42 hours in step 3 during 60 epochs.



## Part 2. Detecting

​	After the part 1 is over, we need to move onto the next part, which is detecting the human. We give you the sample point cloud frame data to test our algorithm. The file 'Detector.mat' is the trained model through the above step. The only thing you have to do is execute the whole file named 'main.m'. After that, you can see the result alike the above.



## Reference

[1] Lang, Alex H., Sourabh Vora, Holger Caesar, Lubing Zhou, Jiong Yang, and Oscar Beijbom. "PointPillars: Fast Encoders for Object Detection From Point Clouds." In 2019 IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR), 12689-12697. Long Beach, CA, USA: IEEE, 2019. https://doi.org/10.1109/CVPR.2019.01298.