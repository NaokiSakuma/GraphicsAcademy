using UnityEngine;

namespace SnowScene.Snow
{
    public class PiledUpSnow : MonoBehaviour
    {
        [SerializeField]
        private RenderTexture renderTexture;

        [SerializeField]
        private Material material;

        private void Awake()
        {

        }

        private void Update()
        {
            // Graphics.Blit(renderTexture, material);
        }
    }
}
