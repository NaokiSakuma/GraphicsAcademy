using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CustomVolume
{
    public class RoarVolumeComponent : VolumeComponent, IPostProcessComponent
    {
        public FloatParameter focusPower = new(0f);
        public IntParameter focusDetail = new(5);
        public Vector2Parameter focusScreenPosition = new(Vector2.zero);
        public IntParameter referenceResolutionX = new(1334);

        public bool IsActive() => focusPower.value > 0f;
        public bool IsTileCompatible() => false;
    }
}
