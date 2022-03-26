using System.Linq;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class CoordinateTransformation : MonoBehaviour
{
    [SerializeField] private Camera viewCamera;
    [SerializeField] private Material material;

    private Mesh mesh;
    private MeshRenderer meshRenderer;
    private Vector3[] vertices;

    private void Awake()
    {
        Initialize();
    }

    private void Initialize()
    {
        mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;
        meshRenderer = GetComponent<MeshRenderer>();
        meshRenderer.material = material;
        vertices = new Vector3[8];

        var triangles = new []{
            0, 2, 1,
            1, 2, 3,
            1, 3, 5,
            7, 5, 3,
            3, 2, 7,
            6, 7, 2,
            2, 0, 6,
            4, 6, 0,
            0, 1, 4,
            5, 4, 1,
            4, 7, 6,
            5, 7, 4
        };

        var colors = new Color[] {
            new(0.0f, 0.0f, 0.0f),
            new(1.0f, 0.0f, 0.0f),
            new(0.0f, 1.0f, 0.0f),
            new(1.0f, 1.0f, 0.0f),
            new(0.0f, 0.0f, 1.0f),
            new(1.0f, 0.0f, 1.0f),
            new(0.0f, 1.0f, 1.0f),
            new(1.0f, 1.0f, 1.0f),
        };
        mesh.SetVertices(vertices);
        mesh.SetTriangles(triangles, 0);
        mesh.SetColors(colors);
        UpdateVertices();
    }

    private void Update()
    {
        UpdateVertices();
    }

    private void UpdateVertices()
    {
        var near = viewCamera.nearClipPlane;
        var far = viewCamera.farClipPlane;

        // 視錐台のnearとfar
        var nearFrustumHeight = 2.0f * near * Mathf.Tan(viewCamera.fieldOfView * 0.5f * Mathf.Deg2Rad);
        var nearFrustumWidth = nearFrustumHeight * viewCamera.aspect;
        var farFrustumHeight = 2.0f * far * Mathf.Tan(viewCamera.fieldOfView * 0.5f * Mathf.Deg2Rad);
        var farFrustumWidth = farFrustumHeight * viewCamera.aspect;

        vertices[0] = new Vector3(nearFrustumWidth * -0.5f, nearFrustumHeight * -0.5f, near);
        vertices[1] = new Vector3(nearFrustumWidth * 0.5f, nearFrustumHeight * -0.5f, near);
        vertices[2] = new Vector3(nearFrustumWidth * -0.5f, nearFrustumHeight * 0.5f, near);
        vertices[3] = new Vector3(nearFrustumWidth * 0.5f, nearFrustumHeight * 0.5f, near);
        vertices[4] = new Vector3(farFrustumWidth * -0.5f, farFrustumHeight * -0.5f, far);
        vertices[5] = new Vector3(farFrustumWidth * 0.5f, farFrustumHeight * -0.5f, far);
        vertices[6] = new Vector3(farFrustumWidth * -0.5f, farFrustumHeight * 0.5f, far);
        vertices[7] = new Vector3(farFrustumWidth * 0.5f, farFrustumHeight * 0.5f, far);

        var calcVertices = vertices
            .Select(x =>
            {
                // mvp変換するので四次元に
                var vertex = new Vector4(x.x, x.y, x.z, 1);
                var vpMatrix = viewCamera.projectionMatrix * viewCamera.worldToCameraMatrix;
                vertex = vpMatrix * vertex;
                // w除算
                vertex /= vertex.w;
                return new Vector3(vertex.x, vertex.y, vertex.z);
            })
            .ToArray();

        mesh.vertices = calcVertices;
        mesh.RecalculateBounds();
    }
}
