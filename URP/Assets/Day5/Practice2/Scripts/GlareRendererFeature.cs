using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Day5.Practice2
{
    public class GlareRendererFeature : ScriptableRendererFeature
    {
        [SerializeField]
        private Shader shader;

        [SerializeField, Range(0.0f, 1.0f)]
        private float threshold = 0.5f;
        [SerializeField, Range(0.5f, 0.95f)]
        private float attenuation = 0.9f;
        [SerializeField, Range(0.0f, 10.0f)]
        private float intensity = 1.0f;

        private GlarePass glarePass;

        public override void Create()
        {
            glarePass = new GlarePass(shader);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            glarePass.SetRenderTarget(renderer.cameraColorTarget);
            glarePass.SetShaderProperty(threshold, attenuation, intensity);
            renderer.EnqueuePass(glarePass);
        }
    }
}
