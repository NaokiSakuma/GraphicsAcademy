using UnityEngine;
using UnityEngine.Playables;

namespace Timeline
{
    public class PostProcessMixerBehaviour : PlayableBehaviour
    {
        public override void ProcessFrame(Playable playable, FrameData info, object playerData)
        {
            var inputCount = playable.GetInputCount();
            for (var i = 0; i < inputCount; i++)
            {
                var playableInput = (ScriptPlayable<PostProcessBehaviour>)playable.GetInput(i);
                var input = playableInput.GetBehaviour();
                var inputWeight = playable.GetInputWeight(i);
                if (Mathf.Approximately(inputWeight, 0f))
                {
                    continue;
                }

                var normalizedTime = (float)(playableInput.GetTime() / playableInput.GetDuration());
                input.ChangeWeight(normalizedTime);
            }
        }
    }
}
