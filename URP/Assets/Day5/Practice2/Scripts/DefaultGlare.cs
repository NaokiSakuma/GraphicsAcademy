using UnityEngine;

namespace Day5.Practice2
{
    public class DefaultGlare : MonoBehaviour
    {
        [SerializeField]
        private Material _material;

        [SerializeField, Range(0.0f, 1.0f)]
        private float _threshold = 0.5f;
        [SerializeField, Range(0.5f, 0.95f)]
        private float _attenuation = 0.9f;
        [SerializeField, Range(0.0f, 10.0f)]
        private float _intensity = 1.0f;

        private void OnRenderImage(RenderTexture source, RenderTexture dest)
        {
            if (_material == null){
                Graphics.Blit(source, dest);
                return;
            }

            var paramsId = Shader.PropertyToID("_Params");
            _material.SetFloat("_Threshold", _threshold);
            _material.SetFloat("_Attenuation", _attenuation);
            _material.SetFloat("_Intensity", _intensity);
            var tempRT1 = RenderTexture.GetTemporary(source.width, source.height);
            var tempRT2 = RenderTexture.GetTemporary(source.width, source.height);

            // SourceをDestにコピーしておく
            Graphics.Blit(source, dest);

            // 4方向にスターを作るループ
            for (int i = 0; i < 4; i++)
            {
                // まず明度が高い部分を抽出する
                Graphics.Blit(source, tempRT1, _material, 0);

                var currentSrc = tempRT1;
                var currentTarget = tempRT2;
                var parameters = Vector3.zero;

                // x, yにUV座標のオフセットを代入する
                // (-1, -1), (-1, 1), (1, -1), (1, 1)
                parameters.x = i == 0 || i == 1 ? -1 : 1;
                parameters.y = i == 0 || i == 2 ? -1 : 1;

                // 1方向にぼかしを伸ばしていくループ
                for (int j = 0; j < 4; j++)
                {
                    // zに描画回数のindexを代入してマテリアルにセット
                    parameters.z = j;
                    _material.SetVector(paramsId, parameters);

                    // 二つのRenderTextureに交互にBlitして効果を足していく
                    Graphics.Blit(currentSrc, currentTarget, _material, 1);
                    var tmp = currentSrc;
                    currentSrc = currentTarget;
                    currentTarget = tmp;
                }

                // Destに加算合成する
                Graphics.Blit(currentSrc, dest, _material, 2);
            }

            // RenderTextureを開放する
            RenderTexture.ReleaseTemporary(tempRT1);
            RenderTexture.ReleaseTemporary(tempRT2);
        }
    }
}
