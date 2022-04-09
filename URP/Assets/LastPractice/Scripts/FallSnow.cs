using UnityEngine;

namespace Snow
{
    public class FallSnow : MonoBehaviour
    {
        private const int SNOW_NUM = 16000;
        private Vector3[] _vertices;
        private int[] _triangles;
        private Vector2[] _uvs;

        private float _range;
        private float _rangeR;
        private Vector3 _move;

        void Start()
        {
            _range = 16.0f;
            _rangeR = 1.0f / _range;
            _vertices = new Vector3[SNOW_NUM * 4];

            for (int i = 0; i < SNOW_NUM; i++)
            {
                float x = Random.Range(-_range, _range);
                float y = Random.Range(-_range, _range);
                float z = Random.Range(-_range, _range);
                var point = new Vector3(x, y, z);
                _vertices[i * 4 + 0] = point;
                _vertices[i * 4 + 1] = point;
                _vertices[i * 4 + 2] = point;
                _vertices[i * 4 + 3] = point;
            }
            _triangles = new int[SNOW_NUM * 6];
            for (int i = 0; i < SNOW_NUM; i++)
            {
                _triangles[i * 6 + 0] = i * 4 + 0;
                _triangles[i * 6 + 1] = i * 4 + 1;
                _triangles[i * 6 + 2] = i * 4 + 2;
                _triangles[i * 6 + 3] = i * 4 + 2;
                _triangles[i * 6 + 4] = i * 4 + 1;
                _triangles[i * 6 + 5] = i * 4 + 3;
            }
            _uvs = new Vector2[SNOW_NUM * 4];
            for (int i = 0; i < SNOW_NUM; i++)
            {
                _uvs[i * 4 + 0] = new Vector2(0.0f, 0.0f);
                _uvs[i * 4 + 1] = new Vector2(1.0f, 0.0f);
                _uvs[i * 4 + 2] = new Vector2(0.0f, 1.0f);
                _uvs[i * 4 + 3] = new Vector2(1.0f, 1.0f);
            }

            Mesh mesh = new Mesh();
            mesh.name = "MeshSnowFlakes";
            mesh.vertices = _vertices;
            mesh.triangles = _triangles;
            mesh.uv = _uvs;
            mesh.bounds = new Bounds(Vector3.zero, Vector3.one * 99999999);
            var mf = GetComponent<MeshFilter>();
            mf.sharedMesh = mesh;
        }

        void LateUpdate()
        {
            var targetPosition = Camera.main.transform.TransformPoint(Vector3.forward * _range);
            var renderer = GetComponent<Renderer>();
            renderer.material.SetFloat("_Range", _range);
            renderer.material.SetFloat("_RangeR", _rangeR);
            renderer.material.SetFloat("_Size", 0.1f);
            renderer.material.SetVector("_MoveTotal", _move);
            renderer.material.SetVector("_CamUp", Camera.main.transform.up);
            renderer.material.SetVector("_TargetPosition", targetPosition);
            float x = (Mathf.PerlinNoise(0f, Time.time * 0.1f) - 0.5f) * 10f;
            float y = -2f;
            float z = (Mathf.PerlinNoise(Time.time*0.1f, 0f)-0.5f) * 10f;
            _move += new Vector3(x, y, z) * Time.deltaTime;
            _move.x = Mathf.Repeat(_move.x, _range * 2.0f);
            _move.y = Mathf.Repeat(_move.y, _range * 2.0f);
            _move.z = Mathf.Repeat(_move.z, _range * 2.0f);
        }
    }
}
