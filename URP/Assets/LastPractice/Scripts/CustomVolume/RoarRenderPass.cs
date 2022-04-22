using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CustomVolume
{
    public class RoarRenderPass : ScriptableRenderPass
    {
        private const string ProfilerTag = nameof(RoarRenderPass);

        private readonly Material material;
        private readonly int mainTexId = Shader.PropertyToID("_MainTex");
        private readonly int focusPowerId = Shader.PropertyToID("_FocusPower");
        private readonly int focusDetailId = Shader.PropertyToID("_FocusDetail");

        private RenderTargetHandle tmpRenderTargetHandle;
        private RoarVolumeComponent roarVolumeComponent;
        private RenderTargetIdentifier currentTarget;

        public RoarRenderPass(Shader shader)
        {
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
            material = CoreUtils.CreateEngineMaterial(shader);
            tmpRenderTargetHandle.Init("_TmpRT");
        }

        public void SetRenderTarget(RenderTargetIdentifier target)
        {
            currentTarget = target;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!renderingData.cameraData.postProcessEnabled)
            {
                return;
            }

            var stack = VolumeManager.instance.stack;
            roarVolumeComponent = stack.GetComponent<RoarVolumeComponent>();

            if (roarVolumeComponent == null)
            {
                return;
            }

            if (!roarVolumeComponent.IsActive())
            {
                return;
            }

            var cmd = CommandBufferPool.Get(ProfilerTag);
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;

            cmd.SetGlobalTexture(mainTexId, currentTarget);
            cmd.GetTemporaryRT(tmpRenderTargetHandle.id, descriptor);
            cmd.Blit(currentTarget, tmpRenderTargetHandle.Identifier());

            material.SetFloat(focusPowerId, roarVolumeComponent.focusPower.value);
            material.SetInt(focusDetailId, roarVolumeComponent.focusDetail.value);
            cmd.Blit(tmpRenderTargetHandle.Identifier(), currentTarget, material);

            cmd.ReleaseTemporaryRT(tmpRenderTargetHandle.id);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
