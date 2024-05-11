# Multi-Drone based Single Object Tracking with Agent Sharing Network

Multi-Drone based Single Object Tracking with Agent Sharing Network ([Paper](https://ieeexplore.ieee.org/document/9298794))

This is an implementation of ASNet and MDOT_toolkit.

## Abstract

![VisDrone](https://github.com/VisDrone/MultiDrone/blob/master/figures/camera.jpg)

Drone equipped with cameras can dynamically track the target in the air from a broader view compared with static cameras or moving sensors over the ground. However, it is still challenging to accurately track the target using a single drone due to several factors such as appearance variations and severe occlusions. In this paper, we collect a new Multi-Drone single Object Tracking (MDOT) dataset that consists of 92 groups of video clips with 113,918 high resolution frames taken by two drones and 63 groups of video clips with 145,875 high resolution frames taken by three drones. Besides, two evaluation metrics are specially designed for multi-drone single object tracking, i.e., automatic fusion score (AFS) and ideal fusion score (IFS). Moreover, an agent sharing network (ASNet) is proposed by self-supervised template sharing and view-aware fusion of the target from multiple drones, which can improve the tracking accuracy significantly compared with single drone tracking. Extensive experiments on MDOT show that our ASNet significantly outperforms recent state-of-the-art trackers.

## MDOT dataset
### Description
The consists of 92 groups of video clips with 113, 918 high resolution frames taken by two drones and 63 groups of video clips with 145, 875 high resolution frames taken by three drones.

![VisDrone](https://github.com/VisDrone/MultiDrone/blob/master/figures/dataset.jpg)

### Download
Baidu:  
[Two-MDOT][https://pan.baidu.com/s/1xGzGQo4aLiYRzQc7W_wwiA?pwd=1895](code:1895)
[Three-MDOT][https://pan.baidu.com/s/1dApKmMsSfKVsYl7mXX13cw?pwd=1895](code: 1895) 

Google:   
google link will be released soon.

### Evaluation code
The evaluation code can be found in [MDOT_toolkit](https://github.com/VisDrone/MultiDrone/tree/master/MDOT_toolkit)

## ASNet
### Description
![VisDrone](https://github.com/VisDrone/MultiDrone/blob/master/figures/ASNet.png)

### Download 

The code can be found in [ASNet](https://github.com/VisDrone/MultiDrone/tree/master/ASNet)

## References
[1] Y. Wu, J. Lim, and M.-H. Yang, "Online Object Tracking: A Benchmark", in CVPR 2013.

## Citation
Please cite this paper if you want to use it in your work.
```
@article{zhu2020multi,
  title={Multi-Drone based Single Object Tracking with Agent Sharing Network},
  author={Zhu, Pengfei and Zheng, Jiayu and Du, Dawei and Wen, Longyin and Sun, Yiming and Hu, Qinghua},
  journal={IEEE Transactions on Circuits and Systems for Video Technology,
  year={2020}
}
```
