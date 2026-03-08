import launch
import launch_ros
from ament_index_python.packages import get_package_share_directory
from launch.launch_description_sources import PythonLaunchDescriptionSource

def generate_launch_description():
    # 获取默认路径
    robot_name_in_model = "my_robot"
    pkg_my_robot = get_package_share_directory('my_robot')
    default_model_path = pkg_my_robot + "/urdf/my_robot.urdf"
    default_world_path = pkg_my_robot + "/worlds/simple.world"

    # 为launch声明参数 model
    action_declare_arg_model_path = launch.actions.DeclareLaunchArgument(
        name='model', default_value=str(default_model_path),
        description='URDF的绝对路径')

    # 获取文件内容生成新的参数
    robot_description = launch_ros.parameter_descriptions.ParameterValue(
        launch.substitutions.Command(
            ['cat ', launch.substitutions.LaunchConfiguration('model')],
            value_type=str
        )
    )

    # 状态发布节点
    robot_state_publisher_node = launch_ros.actions.Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        parameters=[{'robot_description' : robot_description}]
    )

    # # 关节状态发布节点
    # joint_state_publisher_node = launch_ros.actions.Node(
    #     package='joint_state_publisher'
    #     executable='joint_state_publisher'
    # )

    # 通过IncludeLaunchDescription包含gazebo_ros的launch文件来启动gazebo
    gazebo_launch = launch.actions.IncludeLaunchDescription(
        PythonLaunchDescriptionSource([get_package_share_directory('gazebo_ros'), 
                                      '/launch', 
                                      '/gazebo.launch.py']),
        launch_arguments=[('world', default_world_path), ('verbose', 'true')]
    )

    # 请求gazebo加载机器人
    spawn_entity_node = launch_ros.actions.Node(
        package='gazebo_ros',
        executable='spawn_entity.py',
        arguments=['-entity', robot_name_in_model, '-topic', 'robot_description'],
    )

    # # RViz节点
    # rviz_node = launch_ros.actions.Node(
    #     package='rviz2',
    #     executable='rviz2',
    # )

    return launch.LaunchDescription([
        action_declare_arg_model_path,
        robot_state_publisher_node,
        gazebo_launch,
        spawn_entity_node,
    ])