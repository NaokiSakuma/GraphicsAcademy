using SnowScene.Inputs;
using UniRx;
using UniRx.Triggers;
using UnityEngine;


namespace SnowScene.Player
{
    public class PlayerActor : MonoBehaviour
    {
        [SerializeField]
        private float moveSpeed;

        private PlayerInput playerInput;

        private void Awake()
        {
            playerInput = new PlayerInput();

            this.UpdateAsObservable()
                .Select(_ => playerInput.InputMoveValue)
                .Where(x => x != Vector2.zero)
                .Subscribe(x =>
                {
                    var moveValue = new Vector3(x.x, 0, x.y);
                    transform.Translate(moveValue * Time.deltaTime * moveSpeed);
                })
                .AddTo(this);

        }

        private void OnDestroy()
        {
            playerInput.Dispose();
        }
    }
}
