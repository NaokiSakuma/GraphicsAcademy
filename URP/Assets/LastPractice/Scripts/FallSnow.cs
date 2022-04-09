using UniRx;
using UniRx.Triggers;
using UnityEngine;

namespace SnowScene
{
    public class FallSnow : MonoBehaviour
    {
        [SerializeField]
        private Camera snowCamera;
        [SerializeField]
        private Material snowMaterial;
        [SerializeField]
        private MeshFilter meshFilter;

        private const int SnowNum = 16000;
        private const int SnowVertex = 4;
        private const int SquareTriangleVertex = 6;
        private const float CameraRange = 16.0f;
        private const float CameraRangeReverse = 1.0f / CameraRange;
        private Vector3 oldMoveValue;

        private static class SnowShaderPropertyIds
        {
            public static readonly int Range = Shader.PropertyToID("_Range");
            public static readonly int RangeReverse = Shader.PropertyToID("_RangeReverse");
            public static readonly int Size = Shader.PropertyToID("_Size");
            public static readonly int MoveTotal = Shader.PropertyToID("_MoveTotal");
            public static readonly int CamUp = Shader.PropertyToID("_CamUp");
            public static readonly int TargetPosition = Shader.PropertyToID("_TargetPosition");
        }

        private void Awake()
        {
            meshFilter.sharedMesh = CreateSnowMesh();

            this.UpdateAsObservable()
                .Subscribe(_ =>
                {
                    SnowMaterialUpdate();
                })
                .AddTo(this);
        }

        private Mesh CreateSnowMesh()
        {
            var vertices = new Vector3[SnowNum * SnowVertex];

            for (var i = 0; i < SnowNum; i++)
            {
                var point = new Vector3(
                    Random.Range(-CameraRange, CameraRange),
                    Random.Range(-CameraRange, CameraRange),
                    Random.Range(-CameraRange, CameraRange)
                    );
                vertices[i * SnowVertex + 0] = point;
                vertices[i * SnowVertex + 1] = point;
                vertices[i * SnowVertex + 2] = point;
                vertices[i * SnowVertex + 3] = point;
            }

            var triangles = new int[SnowNum * SquareTriangleVertex];
            for (var i = 0; i < SnowNum; i++)
            {
                triangles[i * SquareTriangleVertex + 0] = i * SnowVertex + 0;
                triangles[i * SquareTriangleVertex + 1] = i * SnowVertex + 1;
                triangles[i * SquareTriangleVertex + 2] = i * SnowVertex + 2;
                triangles[i * SquareTriangleVertex + 3] = i * SnowVertex + 2;
                triangles[i * SquareTriangleVertex + 4] = i * SnowVertex + 1;
                triangles[i * SquareTriangleVertex + 5] = i * SnowVertex + 3;
            }
            var uvs = new Vector2[SnowNum * SnowVertex];
            for (var i = 0; i < SnowNum; i++)
            {
                uvs[i * SnowVertex + 0] = new Vector2(0.0f, 0.0f);
                uvs[i * SnowVertex + 1] = new Vector2(1.0f, 0.0f);
                uvs[i * SnowVertex + 2] = new Vector2(0.0f, 1.0f);
                uvs[i * SnowVertex + 3] = new Vector2(1.0f, 1.0f);
            }

            return new Mesh
            {
                vertices = vertices,
                triangles = triangles,
                uv = uvs,
                bounds = new Bounds(Vector3.zero, Vector3.one * 99999999)
            };
        }

        private void SnowMaterialUpdate()
        {
            snowMaterial.SetFloat(SnowShaderPropertyIds.Range, CameraRange);
            snowMaterial.SetFloat(SnowShaderPropertyIds.RangeReverse, CameraRangeReverse);
            snowMaterial.SetFloat(SnowShaderPropertyIds.Size, 0.1f);
            snowMaterial.SetVector(SnowShaderPropertyIds.MoveTotal, CalcMoveValue());
            snowMaterial.SetVector(SnowShaderPropertyIds.CamUp, snowCamera.transform.up);
            var targetPosition = snowCamera.transform.TransformPoint(Vector3.forward * CameraRange);
            snowMaterial.SetVector(SnowShaderPropertyIds.TargetPosition, targetPosition);
        }

        private Vector3 CalcMoveValue()
        {
            var moveValue = new Vector3(
                (Mathf.PerlinNoise(0f, Time.time * 0.1f) - 0.5f) * 10f,
                -2f,
                (Mathf.PerlinNoise(Time.time * 0.1f, 0f) - 0.5f) * 10f
            ) * Time.deltaTime;
            oldMoveValue += moveValue;

            return new Vector3(
                    Mathf.Repeat(oldMoveValue.x, CameraRange * 2.0f),
                    Mathf.Repeat(oldMoveValue.y, CameraRange * 2.0f),
                    Mathf.Repeat(oldMoveValue.z, CameraRange * 2.0f)
            );

        }
    }
}
