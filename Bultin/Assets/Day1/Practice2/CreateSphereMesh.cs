using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class CreateSphereMesh : MonoBehaviour
{
    [SerializeField] private Material material;
    [SerializeField] private Vector2Int divide;

    private const int MinDivide = 2;

    private void Start()
    {
        Create();
    }

    [ContextMenu("Create")]
    private void Create()
    {
        var data = CreateSphere(divide.x, divide.y);

        var mesh = new Mesh();
        mesh.Clear();
        mesh.SetVertices(data.Vertices);
        mesh.SetIndices(data.Indices, MeshTopology.Triangles, 0);

        var meshFilter = GetComponent<MeshFilter>();
        meshFilter.mesh = mesh;
        mesh.RecalculateNormals();

        var meshRenderer = GetComponent<MeshRenderer>();
        meshRenderer.material = material;
    }

    private readonly struct MeshData
    {
        public readonly Vector3[] Vertices;
        public readonly int[] Indices;

        public MeshData(Vector3[] vertices, int[] indices)
        {
            Vertices = vertices;
            Indices = indices;
        }
    }

    MeshData CreateSphere(int divideX, int divideY, float size = 1f)
    {
        divideX = divideX < MinDivide ? MinDivide : divideX;
        divideY = divideY < MinDivide ? MinDivide : divideY;

        var vertices = CreateVertices(divideX, divideY, size);
        var indices = CreateIndices(divideX, divideY, vertices.Length);

        return new MeshData(vertices, indices);
    }

    private Vector3[] CreateVertices(int divideX, int divideY, float size)
    {
        var radius = size * 0.5f;
        var cnt = 0;
        var vertCount = divideX * (divideY - 1) + 2;
        var vertices = new Vector3[vertCount];

        // 中心角
        var centerRadianX = 2f * Mathf.PI / divideX;
        var centerRadianY = 2f * Mathf.PI / divideY;

        // 天面
        vertices[cnt++] = new Vector3(0, radius, 0);
        for (var vy = 0; vy < divideY - 1; vy++)
        {
            // divideYの分割位置におけるθ
            var yRadian =(vy + 1) * centerRadianY / 2f;

            // 1辺の長さ
            var tmpLen = Mathf.Abs(Mathf.Sin(yRadian));

            var y = Mathf.Cos(yRadian);
            for (var vx = 0; vx < divideX; vx++)
            {
                // divideXの分割位置におけるθ
                var xRadian = vx * centerRadianX;
                var pos = new Vector3(
                    tmpLen * Mathf.Sin(xRadian),
                    y,
                    tmpLen * Mathf.Cos(xRadian)
                );
                // サイズ反映
                vertices[cnt++] = pos * radius;
            }
        }

        // 底面
        vertices[cnt] = new Vector3(0, -radius, 0);

        return vertices;
    }

    private int[] CreateIndices(int divideX, int divideY, int verticesLength)
    {
                var topAndBottomTriCount = divideX * 2;
        // 側面三角形の数
        var aspectTriCount = divideX * (divideY - 2) * 2;

        var indices = new int[(topAndBottomTriCount + aspectTriCount) * 3];

        // 天面のindexを割り振る
        var offsetIndex = 0;
        var cnt = 0;
        for (var i = 0; i < divideX * 3; i++)
        {
            switch (i % 3)
            {
                case 0:
                    indices[cnt++] = 0;
                    break;
                case 1:
                    indices[cnt++] = 1 + offsetIndex;
                    break;
                case 2:
                {
                    var index = 2 + offsetIndex++;
                    // 蓋をする
                    index = index > divideX ? indices[1] : index;
                    indices[cnt++] = index;
                    break;
                }
            }
        }

        // 側面Index
        // 開始Index番号
        var startIndex = indices[1];

        // 天面、底面を除いたIndex要素数
        var sideIndexLen = divideX * (divideY - 2) * 2 * 3;

        // ループ時に使用するIndex
        var loopFirstIndex = 0;
        var loopSecondIndex = 0;

        // 一周したときのindex数
        var lapDiv = divideX * 2 * 3;

        var createSquareFaceCount = 0;

        for (var i = 0; i < sideIndexLen; i++)
        {
            // 一周の頂点数を超えたら更新(初回も含む)
            if (i % lapDiv == 0)
            {
                loopFirstIndex = startIndex;
                loopSecondIndex = startIndex + divideX;
                createSquareFaceCount++;
            }

            switch (i % 6)
            {
                case 0:
                case 3:
                    indices[cnt++] = startIndex;
                    break;
                case 1:
                    indices[cnt++] = startIndex + divideX;
                    break;
                case 2:
                case 4:
                {
                    if (i > 0 &&
                        (i % (lapDiv * createSquareFaceCount - 2) == 0 ||
                         i % (lapDiv * createSquareFaceCount - 4) == 0)
                       )
                    {
                        // 1周したときのループ処理
                        // 周回ポリゴンの最後から2番目のIndex
                        indices[cnt++] = loopSecondIndex;
                    }
                    else
                    {
                        indices[cnt++] = startIndex + divideX + 1;
                    }

                    break;
                }
                case 5:
                {
                    if (i > 0 && i % (lapDiv * createSquareFaceCount - 1) == 0)
                    {
                        // 1周したときのループ処理
                        // 周回ポリゴンの最後のIndex
                        indices[cnt++] = loopFirstIndex;
                    }
                    else
                    {
                        indices[cnt++] = startIndex + 1;
                    }

                    // 開始Indexの更新
                    startIndex++;
                    break;
                }
                default:
                    Debug.LogError("Invalid : " + i);
                    break;
            }
        }


        // 底面Index
        offsetIndex = verticesLength - 1 - divideX;
        var loopIndex = offsetIndex;

        for (var i = divideX * 3 - 1; i >= 0; i--)
        {
            switch (i % 3)
            {
                case 0:
                    // 底面の先頂点
                    indices[cnt++] = verticesLength - 1;
                    offsetIndex++;
                    break;
                case 1:
                    indices[cnt++] = offsetIndex;
                    break;
                case 2:
                {
                    var value = 1 + offsetIndex;
                    if (value >= verticesLength - 1)
                    {
                        value = loopIndex;
                    }

                    indices[cnt++] = value;
                    break;
                }
            }
        }

        return indices;
    }
}