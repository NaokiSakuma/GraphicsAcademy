using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Day4.Practice1.PostEffect
{
    public class GrayscalePass: ScriptableRenderPass
    {
        private const string ProfilerTag = nameof(GrayscalePass);
        private const string ProfilingSamplerName = "SrcToDest";

        private readonly Material material;
        private readonly ProfilingSampler profilingSampler;

        private RenderTargetHandle tmpRenderTargetHandle;
        private RenderTargetIdentifier cameraColorTarget;

        public GrayscalePass(Shader shader)
        {
            material = CoreUtils.CreateEngineMaterial(shader);
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
            profilingSampler = new ProfilingSampler(ProfilingSamplerName);
            tmpRenderTargetHandle.Init("_TempRT");
        }

        public void SetRenderTarget(RenderTargetIdentifier target)
        {
            cameraColorTarget = target;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            // いる？
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }

            var cmd = CommandBufferPool.Get(ProfilerTag);

            // ?
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;

            cmd.GetTemporaryRT(tmpRenderTargetHandle.id, descriptor);

            // これいらんかも？
            using (new ProfilingScope(cmd, profilingSampler))
            {
                cmd.Blit(cameraColorTarget, tmpRenderTargetHandle.Identifier(), material);
            }

            cmd.Blit(tmpRenderTargetHandle.Identifier(), cameraColorTarget);
            cmd.ReleaseTemporaryRT(tmpRenderTargetHandle.id);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
