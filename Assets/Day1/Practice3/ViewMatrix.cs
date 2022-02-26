using UnityEngine;

public class ViewMatrix : MonoBehaviour
{
    [SerializeField] private Camera matCamera;
    private void Start()
    {
        var mMatrix = transform.localToWorldMatrix;
        
        // todo const
        var vertex = new Vector4(2, 0, 0, 1);
        Debug.Log($"World: {mMatrix * vertex}");

        var vMatrix = matCamera.worldToCameraMatrix;
        var vpMatrix = vMatrix * mMatrix;
        Debug.Log($"Camera: {MulVp(vpMatrix, vertex)}");
    }

    private Vector4 MulVp(Matrix4x4 vpMatrix, Vector4 vertex)
    {
        var result = vpMatrix * vertex;
        result.z *= -1;
        return result;
    }
}
