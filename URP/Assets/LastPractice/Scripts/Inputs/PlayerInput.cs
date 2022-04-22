using System;
using UnityEngine;
using UnityEngine.InputSystem;

namespace SnowScene.Inputs
{
    public class PlayerInput : PlayerInputControls.IPlayerActions, IDisposable
    {
        private readonly PlayerInputControls inputControls = new();

        public Vector2 InputMoveValue { get; private set; }

        public PlayerInput()
        {
            inputControls.Player.SetCallbacks(this);
            inputControls.Enable();
        }

        public void OnMove(InputAction.CallbackContext context)
        {
            InputMoveValue = context.ReadValue<Vector2>();
        }

        public void Dispose()
        {
            inputControls.Disable();
            inputControls.Dispose();
        }
    }
}
