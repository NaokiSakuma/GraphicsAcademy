using UnityEditor;
using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Timeline;

namespace Timeline
{
    public class PostProcessClip : PlayableAsset, ITimelineClipAsset
    {
        public PostProcessBehaviour template = new();

        public ClipCaps clipCaps => ClipCaps.Extrapolation | ClipCaps.Blending;

        public override Playable CreatePlayable(PlayableGraph graph, GameObject owner)
        {
            var playable = ScriptPlayable<PostProcessBehaviour>.Create(graph, template);
            var clone = playable.GetBehaviour();
            return playable;
        }
    }

#if UNITY_EDITOR

    [CustomEditor(typeof(PostProcessClip))]
    public class PostProcessClipEditor : Editor
    {
        private PostProcessClip postProcessClip;
        private Editor profileEditor;
        private SerializedProperty profileProperty;
        private SerializedProperty curveProperty;

        private void OnEnable()
        {
            postProcessClip = target as PostProcessClip;
            profileEditor = CreateEditor(postProcessClip?.template.profile);
            profileProperty = serializedObject.FindProperty("template.profile");
            curveProperty = serializedObject.FindProperty("template.weightCurve");
        }

        private void OnDisable()
        {
            DestroyImmediate(profileEditor);
        }

        public override void OnInspectorGUI()
        {
            postProcessClip.template.layer = EditorGUILayout.LayerField("Layer", postProcessClip.template.layer);
            serializedObject.Update();
            EditorGUILayout.PropertyField(profileProperty);
            EditorGUILayout.PropertyField(curveProperty);
            serializedObject.ApplyModifiedProperties();

            profileEditor?.OnInspectorGUI();
        }
    }
#endif
}
