using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CustomVolume
{
    public class RoarRenderFeature : ScriptableRendererFeature
    {
        RoarRenderPass roarRenderPass;

        public override void Create()
        {
            roarRenderPass = new RoarRenderPass(RenderPassEvent.BeforeRenderingPostProcessing);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            roarRenderPass.Setup(renderer.cameraColorTarget);
            renderer.EnqueuePass(roarRenderPass);
        }
    }

    public class RoarRenderPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Render ZoomBlur Effects";
        static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        static readonly int TempTargetId = Shader.PropertyToID("_TempTargetZoomBlur");
        static readonly int FocusPowerId = Shader.PropertyToID("_FocusPower");
        static readonly int FocusDetailId = Shader.PropertyToID("_FocusDetail");
        static readonly int FocusScreenPositionId = Shader.PropertyToID("_FocusScreenPosition");
        static readonly int ReferenceResolutionXId = Shader.PropertyToID("_ReferenceResolutionX");
        RoarVolumeComponent roarVolumeComponent;
        Material zoomBlurMaterial;
        RenderTargetIdentifier currentTarget;

        public RoarRenderPass(RenderPassEvent evt)
        {
            renderPassEvent = evt;
            var shader = Shader.Find("PostEffect/ZoomBlur");
            if (shader == null)
            {
                Debug.LogError("Shader not found.");
                return;
            }
            zoomBlurMaterial = CoreUtils.CreateEngineMaterial(shader);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (zoomBlurMaterial == null)
            {
                Debug.LogError("Material not created.");
                return;
            }

            if (!renderingData.cameraData.postProcessEnabled) return;

            var stack = VolumeManager.instance.stack;
            roarVolumeComponent = stack.GetComponent<RoarVolumeComponent>();
            if (roarVolumeComponent == null) { return; }
            if (!roarVolumeComponent.IsActive()) { return; }

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public void Setup(in RenderTargetIdentifier currentTarget)
        {
            this.currentTarget = currentTarget;
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ref var cameraData = ref renderingData.cameraData;
            var source = currentTarget;
            int destination = TempTargetId;

            var w = cameraData.camera.scaledPixelWidth;
            var h = cameraData.camera.scaledPixelHeight;
            zoomBlurMaterial.SetFloat(FocusPowerId, roarVolumeComponent.focusPower.value);
            zoomBlurMaterial.SetInt(FocusDetailId, roarVolumeComponent.focusDetail.value);
            zoomBlurMaterial.SetVector(FocusScreenPositionId, roarVolumeComponent.focusScreenPosition.value);
            zoomBlurMaterial.SetInt(ReferenceResolutionXId, roarVolumeComponent.referenceResolutionX.value);

            int shaderPass = 0;
            cmd.SetGlobalTexture(MainTexId, source);
            cmd.GetTemporaryRT(destination, w, h, 0, FilterMode.Point, RenderTextureFormat.Default);
            cmd.Blit(source, destination);
            cmd.Blit(destination, source, zoomBlurMaterial, shaderPass);
        }
    }
}
