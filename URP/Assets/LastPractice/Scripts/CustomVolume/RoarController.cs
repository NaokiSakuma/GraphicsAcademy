using UnityEngine;
using UnityEngine.Rendering;

namespace CustomVolume
{
    [ExecuteAlways]
    public class RoarController : MonoBehaviour
    {
        public VolumeProfile volumeProfile;
        [Range(0f, 100f)]
        public float focusPower = 10f;
        [Range(0, 10)]
        public int focusDetail = 5;
        public int referenceResolutionX = 1334;
        public Vector2 focusScreenPosition = Vector2.zero;
        RoarVolumeComponent roarVolumeComponent;

        void Update()
        {
            if (volumeProfile == null) return;
            if (roarVolumeComponent == null) volumeProfile.TryGet<RoarVolumeComponent>(out roarVolumeComponent);
            if (roarVolumeComponent == null) return;

            roarVolumeComponent.focusPower.value = focusPower;
            roarVolumeComponent.focusDetail.value = focusDetail;
            roarVolumeComponent.focusScreenPosition.value = focusScreenPosition;
            roarVolumeComponent.referenceResolutionX.value = referenceResolutionX;
        }
    }
}
