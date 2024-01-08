import QtQuick 2.9
import QtQuick3D

///     @author Omid Esrafilian <esrafilian.omid@gmail.com>

Node{

    function crossProduct(vec_a, vec_b)
    {
        var vec_c = Qt.vector3d(0, 0, 0)
        vec_c.x = vec_a.y * vec_b.z - vec_a.z * vec_b.y
        vec_c.y = -(vec_a.x * vec_b.z - vec_a.z * vec_b.x)
        vec_c.z = vec_a.x * vec_b.y - vec_a.y * vec_b.x

        return vec_c
    }

    function dotProduct(vec_a, vec_b)
    {
        return (vec_a.x*vec_b.x + vec_a.y*vec_b.y + vec_a.z*vec_b.z)
    }

    function vecNorm(_vec)
    {
        return Math.sqrt(dotProduct(_vec, _vec))
    }

    function normalizeVec(_vec)
    {
        var norm_vec = vecNorm(_vec)
        return Qt.vector3d(_vec.x/norm_vec, _vec.y/norm_vec, _vec.z/norm_vec)
    }

    function normalizeVec4(_vec)
    {
        var norm_vec = Math.sqrt(_vec.x*_vec.x + _vec.y*_vec.y + _vec.z*_vec.z + _vec.w*_vec.w)
        return Qt.vector4d(_vec.x/norm_vec, _vec.y/norm_vec, _vec.z/norm_vec, _vec.w/norm_vec)
    }

    function eulerFromQuaternions(vec_q)
    {
        var M_PI = 3.1415
        var sinr_cosp = 2 * (vec_q.w * vec_q.x + vec_q.y * vec_q.z)
        var cosr_cosp = 1 - 2 * (vec_q.x * vec_q.x + vec_q.y * vec_q.y)
        var roll = Math.atan2(sinr_cosp, cosr_cosp)

        // pitch (y-axis rotation)
        var sinp = Math.sqrt(1 + 2 * (vec_q.w * vec_q.y - vec_q.x * vec_q.z))
        var cosp = Math.sqrt(1 - 2 * (vec_q.w * vec_q.y - vec_q.x * vec_q.z))
        var pitch = 2 * Math.atan2(sinp, cosp) - M_PI / 2

        // yaw (z-axis rotation)
        var siny_cosp = 2 * (vec_q.w * vec_q.z + vec_q.x * vec_q.y)
        var cosy_cosp = 1 - 2 * (vec_q.y * vec_q.y + vec_q.z * vec_q.z)
        var yaw = Math.atan2(siny_cosp, cosy_cosp)

        var rad_2_deg = 180.0 / 3.1415
        console.log("euler:", roll * rad_2_deg, pitch * rad_2_deg, yaw * rad_2_deg)
        return Qt.vector3d(roll * rad_2_deg, pitch * rad_2_deg, yaw * rad_2_deg)
    }

    function get_rotation_between(vec_a, vec_b)
    {
        var vec_a_n = normalizeVec(vec_a)
        var vec_b_n = normalizeVec(vec_b)

        var cos_angle = dotProduct(vec_a_n, vec_b_n)
        if(cos_angle === 1)
        {
            return Quaternion.fromEulerAngles(Qt.vector3d(0, 0, 0))
        }else if(cos_angle === -1)
        {
            var axis_idx = 0
            var dx = Math.abs(vec_a_n.x - vec_b_n.x)
            if(dx < Math.abs(vec_a_n.y - vec_b_n.y))
            {
                dx = Math.abs(vec_a_n.y - vec_b_n.y)
                axis_idx = 1
            }
            if(dx < Math.abs(vec_a_n.z - vec_b_n.z))
                axis_idx = 2

            switch(axis_idx)
            {
            case 0:
                return Quaternion.fromEulerAngles(Qt.vector3d(0, 180, 0))
            case 1:
                return Quaternion.fromEulerAngles(Qt.vector3d(0, 0, 180))
            case 2:
                return Quaternion.fromEulerAngles(Qt.vector3d(180, 0, 0))
            }
        }

        var angle_ = Math.acos(cos_angle)
        var axis_ = normalizeVec(crossProduct(vec_a_n, vec_b_n))

        return Quaternion.fromAxisAndAngle(axis_, angle_ * 180/3.1415)
    }

    id: line_root
    property vector3d p_1: Qt.vector3d(10, 0, 0)
    property vector3d p_2: Qt.vector3d(0, 20, 0)
    property real lineWidth: 5
    property alias color: line_mat.diffuseColor

    readonly property vector3d vec_1: Qt.vector3d(p_2.x - p_1.x,
                                          p_2.y - p_1.y,
                                          p_2.z - p_1.z)
    readonly property real length_: vecNorm(vec_1)
    readonly property vector3d vec_2: Qt.vector3d(0, length_, 0)

    rotation: get_rotation_between(vec_2, vec_1)
    position: p_1

    Model {
        readonly property real scale_pose: 50
        readonly property real height: line_root.length_
        readonly property real radius: line_root.lineWidth * 0.1
        source: "#Cylinder"
        scale: Qt.vector3d(radius/scale_pose, 0.5 * height/scale_pose, radius/scale_pose)
        position: Qt.vector3d(0, 0.5 * height, 0)

        materials:
            DefaultMaterial {
            id: line_mat
            diffuseColor: "blue"
        }
    }
}
