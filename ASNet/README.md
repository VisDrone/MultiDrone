# ASNet
This is an implementation of ASNet

## Results

![Two_MDOT_results](https://github.com/VisDrone/MultiDrone/blob/master/figures/Two_MDOT_results.png)

![Three_MDOT_results](https://github.com/VisDrone/MultiDrone/blob/master/figures/Three_MDOT_results.png)

## Installation
### Requirements
- Matlab (2015b)
- MatConvNet (http://www.vlfeat.org/matconvnet/)

### Start Up
Reference the DSiam and SiameseFC
#### pretrained model
The vgg19 can be downloaded from http://www.vlfeat.org/matconvnet/pretrained/. 
The SiamFC can be downloaded from https://github.com/bertinetto/siamese-fc.
put these networks into the 'model' fold.

#### Run
matlab -nodisplay -r main_running_ASNet
