Shader "SnowScene/RoarBlur"
{
    Properties
    {
        [HideInInspector]_MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Renderpipeline"="UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float4 _MainTex_ST;
                float _FocusPower;
                int _FocusDetail;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                float2 centerUv = float2(0.5, 0.5);

                float2 focus = IN.uv - centerUv;
                half aspectX = _ScreenParams.x / 1334;
                float4 col = float4(0, 0, 0, 1);

                for (int i = 0; i < _FocusDetail; i++)
                {
                    float power = 1.0 - _FocusPower * (1.0 / _ScreenParams.x * aspectX) * i;
                    col.rgb += tex2D(_MainTex , focus * power + centerUv).rgb;
                }

                col.rgb *= 1.0 / _FocusDetail;
                return col;
            }
            ENDHLSL
        }
    }
}
