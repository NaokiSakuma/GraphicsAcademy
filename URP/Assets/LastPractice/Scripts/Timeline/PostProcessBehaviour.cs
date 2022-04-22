using System;
using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Rendering;

namespace Timeline
{
    [Serializable]
    public class PostProcessBehaviour : PlayableBehaviour
    {
        [HideInInspector]
        public Volume volume;
        public VolumeProfile profile;
        public int layer;
        public AnimationCurve weightCurve = AnimationCurve.Linear(0f, 0f, 1f, 1f);

        public override void OnBehaviourPlay(Playable playable, FrameData info)
        {
            if (profile != null)
            {
                QuickVolume();
            }
        }

        public override void OnBehaviourPause(Playable playable, FrameData info)
        {
            if (volume != null)
            {
                GameObject.DestroyImmediate(volume.gameObject);
            }
        }

        private void QuickVolume()
        {
            if (volume != null)
            {
                return;
            }

            volume = new GameObject().AddComponent<Volume>();
            var gameObject = volume.gameObject;
            gameObject.layer = layer;
            gameObject.hideFlags = HideFlags.DontSave | HideFlags.NotEditable;
            gameObject.name = $"PostProcessBehaviourVolume [Profile {profile.name}]";
            volume.weight = 0;
            volume.priority = 1;
            volume.isGlobal = true;
            volume.profile = profile;
        }

        public void ChangeWeight(float time)
        {
            if (volume == null)
            {
                return;
            }

            volume.weight = weightCurve.Evaluate(time);
        }
    }
}
