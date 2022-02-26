using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
[RequireComponent(typeof(MeshFilter))]
public class CreateCubeMesh : MonoBehaviour
{
    [SerializeField] private Material material;

    private void Start()
    {
        var vertices = new Vector3[]
        {
            // 0
            new(0.0f, 0.0f, 0.0f), // 正面
            new(1.0f, 0.0f, 0.0f),
            new(1.0f, 1.0f, 0.0f),
            new(0.0f, 1.0f, 0.0f),
            // 4

            new(1.0f, 1.0f, 0.0f), // 上面
            new(0.0f, 1.0f, 0.0f),
            new(0.0f, 1.0f, 1.0f),
            new(1.0f, 1.0f, 1.0f),
            // 8
            new(1.0f, 0.0f, 0.0f), // 右面
            new(1.0f, 1.0f, 0.0f),
            new(1.0f, 1.0f, 1.0f),
            new(1.0f, 0.0f, 1.0f),
            // 12
            new(0.0f, 0.0f, 0.0f), // 左面
            new(0.0f, 1.0f, 0.0f),
            new(0.0f, 1.0f, 1.0f),
            new(0.0f, 0.0f, 1.0f),
            // 16
            new(0.0f, 1.0f, 1.0f), // 背面
            new(1.0f, 1.0f, 1.0f),
            new(1.0f, 0.0f, 1.0f),
            new(0.0f, 0.0f, 1.0f),
            // 20
            new(0.0f, 0.0f, 0.0f), // 下面
            new(1.0f, 0.0f, 0.0f),
            new(1.0f, 0.0f, 1.0f),
            new(0.0f, 0.0f, 1.0f),

        };

        var triangles = new[]
        {
            0, 3, 2, 0, 2, 1,       //前面 ( 0 -  3)
            5, 6, 7, 5, 7, 4,       //上面 ( 4 -  7)
            8, 9, 10, 8, 10, 11,    //右面 ( 8 - 11)
            15, 14, 13, 15, 13, 12, //左面 (12 - 15)
            16, 18, 17, 16, 19, 18, //奥面 (16 - 19)
            23, 20, 21, 23, 21, 22, //下面 (20 - 23)
        };

        var mesh = new Mesh();
        mesh.Clear();
        mesh.SetVertices(vertices);
        mesh.SetTriangles(triangles, 0);
        mesh.RecalculateNormals();

        var meshFilter = GetComponent<MeshFilter>();
        meshFilter.mesh = mesh;

        var meshRenderer = GetComponent<MeshRenderer>();
        meshRenderer.material = material;
    }
}
