# FROM 指定基础镜像。这里用的是 ROS2 Humble 桌面版
FROM osrf/ros:humble-desktop
# 设置环境变量，避免在安装软件包时弹出交互式配置界面（比如时区选择），保证自动化安装。
ENV DEBIAN_FRONTEND=noninteractive

# 在容器内执行命令，安装项目所需的系统级依赖：
# 编译工具：cmake, build-essential
# 库文件：PCL、OpenCV、VTK、Qt5、Eigen、GTest（用于测试）
# VLC 相关：用于后续 RTSP 推流
# ROS 包：xacro（处理 URDF）、teleop-twist-keyboard（键盘控制）
# 最后 rm -rf ... 是清理 apt 缓存，减小镜像体积。
RUN apt-get update && apt-get install -y \
    python3-pip \
    git \
    cmake \
    build-essential \
    libpcl-dev \
    libopencv-dev \
    libvtk7-dev \
    libvtk7-qt-dev \
    qt5-default \
    qtbase5-dev \
    libeigen3-dev \
    libgtest-dev \
    libvlc-dev \
    libvlccore-dev \
    vlc \
    ros-humble-xacro \
    ros-humble-teleop-twist-keyboard \
    && rm -rf /var/lib/apt/lists/*

# 安装 Python 依赖，为后续感知融合阶段（YOLO 等）做准备。
RUN pip3 install torch torchvision opencv-python ultralytics numpy scipy

# 设置容器内的工作目录为 /workspace，后续命令都会在这个目录下执行。
WORKDIR /workspace

# 将当前目录（即你主机上的 my_robot 包）复制到容器内的 /workspace/src/my_robot。注意，这里的“当前目录”是指你执行 docker build 时的目录，通常就是 my_robot 包的根目录。
COPY . src/my_robot

# 在容器内编译你的 ROS2 工作空间。先 source ROS 环境，然后运行 colcon build 编译 my_robot 包。
RUN . /opt/ros/humble/setup.sh && colcon build --symlink-install

# 将 ROS2 工作空间的环境设置写入 bash 启动文件，这样每次进入容器时，ROS2 环境就会自动生效。
RUN echo "source /workspace/install/setup.bash" >> ~/.bashrc

# 设置容器启动时的默认命令，即打开一个 bash 终端。
CMD ["/bin/bash"]