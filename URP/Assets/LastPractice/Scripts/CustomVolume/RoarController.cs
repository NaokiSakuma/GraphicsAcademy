using UniRx;
using UniRx.Triggers;
using UnityEngine;
using UnityEngine.Rendering;

namespace CustomVolume
{
    [ExecuteAlways]
    public class RoarController : MonoBehaviour
    {
        [SerializeField]
        private VolumeProfile volumeProfile;
        [Range(0f, 100f), SerializeField]
        private float focusPower = 10f;
        [Range(0, 10), SerializeField]
        private int focusDetail = 5;

        private void Awake()
        {
            volumeProfile.TryGet<RoarVolumeComponent>(out var roarVolumeComponent);
            if (roarVolumeComponent == null)
            {
                return;
            }

            this.UpdateAsObservable()
                .Subscribe(_ =>
                {
                    roarVolumeComponent.focusPower.value = focusPower;
                    roarVolumeComponent.focusDetail.value = focusDetail;
                })
                .AddTo(this);
        }
    }
}
