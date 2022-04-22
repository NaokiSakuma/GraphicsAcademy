using UniRx;
using UniRx.Triggers;
using UnityEngine;

namespace SnowScene.Snow
{
    public class Footprint : MonoBehaviour
    {
        [SerializeField]
        private Texture2D stampTexture;

        [SerializeField]
        private RenderTexture renderTexture;
        [SerializeField]
        private int rtWidth = 512;
        [SerializeField]
        private int rtHeight = 512;

        [SerializeField]
        private Material stampMaterial;

        [SerializeField]
        private Material piledMaterial;

        [SerializeField]
        private int piledFrame;

        private RenderTexture scrRenderTexture;
        private RenderTexture destRenderTexture;

        private void Awake()
        {
            scrRenderTexture = new RenderTexture(rtWidth, rtHeight, 32);
            scrRenderTexture = renderTexture;
            destRenderTexture = new RenderTexture(rtWidth, rtHeight, 32);

            Observable
                .IntervalFrame(piledFrame)
                .Subscribe(_ =>
                {
                    PiledUp();
                })
                .AddTo(this);
        }

        public void DrawFootPoint(Vector2 position)
        {
            Graphics.Blit(scrRenderTexture, destRenderTexture);

            RenderTexture.active = scrRenderTexture;

            GL.PushMatrix();
            GL.LoadPixelMatrix(0, scrRenderTexture.width, scrRenderTexture.height, 0);

            var roundedPotion = CalcHitPosition(position);

            var screenRect = new Rect
            {
                x = roundedPotion.x - stampTexture.width * 0.5f,
                y = scrRenderTexture.height - roundedPotion.y - stampTexture.height * 0.5f,
                width = stampTexture.width,
                height = stampTexture.height
            };

            Graphics.DrawTexture(screenRect, stampTexture, stampMaterial);
            GL.PopMatrix();
            RenderTexture.active = null;
        }

        private Vector2 CalcHitPosition(Vector2 position)
        {
            return new Vector2(
                Mathf.Round(position.x * scrRenderTexture.width),
                Mathf.Round(position.y * scrRenderTexture.height));
        }

        private void PiledUp()
        {
            var tmp = RenderTexture.GetTemporary(rtWidth, rtHeight);
            Graphics.Blit(scrRenderTexture, tmp);
            Graphics.Blit(tmp, scrRenderTexture, piledMaterial);

            RenderTexture.ReleaseTemporary(tmp);
        }
    }
}
