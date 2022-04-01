using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Day5.Practice2
{
    public class GlarePass : ScriptableRenderPass
    {
        private const string ProfilerTag = nameof(GlarePass);

        private readonly Material material;
        private readonly int paramsPropertyId = Shader.PropertyToID("_Params");
        private readonly int thresholdPropertyId = Shader.PropertyToID("_Threshold");
        private readonly int attenuationPropertyId = Shader.PropertyToID("_Attenuation");
        private readonly int intensityPropertyId = Shader.PropertyToID("_Intensity");

        private RenderTargetHandle destRenderTargetHandle;
        private RenderTargetHandle tmpRenderTargetHandle1;
        private RenderTargetHandle tmpRenderTargetHandle2;

        private RenderTargetIdentifier cameraColorTarget;
        private float threshold;
        private float attenuation;
        private float intensity;

        public GlarePass(Shader shader)
        {
            material = CoreUtils.CreateEngineMaterial(shader);
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
            destRenderTargetHandle.Init("_destRT");
            tmpRenderTargetHandle1.Init("_TempRT1");
            tmpRenderTargetHandle2.Init("_TempRT2");

        }

        public void SetRenderTarget(RenderTargetIdentifier target)
        {
            cameraColorTarget = target;
        }

        public void SetShaderProperty(float threshold, float attenuation, float intensity)
        {
            this.threshold = threshold;
            this.attenuation = attenuation;
            this.intensity = intensity;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }

            var cmd = CommandBufferPool.Get(ProfilerTag);

            var descriptor = renderingData.cameraData.cameraTargetDescriptor;

            cmd.GetTemporaryRT(destRenderTargetHandle.id, descriptor);
            cmd.GetTemporaryRT(tmpRenderTargetHandle1.id, descriptor);
            cmd.GetTemporaryRT(tmpRenderTargetHandle2.id, descriptor);

            material.SetFloat(thresholdPropertyId, threshold);
            material.SetFloat(attenuationPropertyId, attenuation);
            material.SetFloat(intensityPropertyId, intensity);

            cmd.Blit(cameraColorTarget, destRenderTargetHandle.Identifier());

            for (var i = 0; i < 4; i++)
            {
                cmd.Blit(cameraColorTarget, tmpRenderTargetHandle1.Identifier(), material, 0);

                var currentSrc = tmpRenderTargetHandle1.Identifier();
                var currentTarget = tmpRenderTargetHandle2.Identifier();
                var parameters = Vector3.zero;

                parameters.x = i is 0 or 1 ? -1 : 1;
                parameters.y = i is 0 or 2 ? -1 : 1;

                for (var j = 0; j < 4; j++)
                {
                    parameters.z = j;
                    cmd.SetGlobalVector(paramsPropertyId, parameters);
                    cmd.Blit( currentSrc, currentTarget, material, 1);
                    (currentSrc, currentTarget) = (currentTarget, currentSrc);
                }

                cmd.Blit(currentSrc, destRenderTargetHandle.Identifier(), material, 2);
            }

            cmd.Blit(destRenderTargetHandle.Identifier(), cameraColorTarget);

            cmd.ReleaseTemporaryRT(destRenderTargetHandle.id);
            cmd.ReleaseTemporaryRT(tmpRenderTargetHandle1.id);
            cmd.ReleaseTemporaryRT(tmpRenderTargetHandle2.id);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
