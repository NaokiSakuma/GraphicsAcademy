using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace CustomVolume
{
    public class RoarRenderFeature : ScriptableRendererFeature
    {
        [SerializeField]
        private Shader shader;

        private RoarRenderPass roarRenderPass;

        public override void Create()
        {
            roarRenderPass = new RoarRenderPass(shader);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            roarRenderPass.SetRenderTarget(renderer.cameraColorTarget);
            renderer.EnqueuePass(roarRenderPass);
        }
    }

}
