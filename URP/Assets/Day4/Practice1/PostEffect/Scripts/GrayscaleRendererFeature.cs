using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Day4.Practice1.PostEffect
{
    public class GrayscaleRendererFeature : ScriptableRendererFeature
    {
        [SerializeField]
        private Shader shader;

        private GrayscalePass grayscalePass;

        public override void Create()
        {
            grayscalePass = new GrayscalePass(shader);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            grayscalePass.SetRenderTarget(renderer.cameraColorTarget);
            renderer.EnqueuePass(grayscalePass);
        }
    }
}
