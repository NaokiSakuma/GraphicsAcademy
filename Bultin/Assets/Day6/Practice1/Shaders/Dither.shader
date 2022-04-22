Shader "Day6/Dither"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _DitherTex ("Dither Pattern (R)", 2D) = "white" {}
        _Threshold ("_Threshold", Range(0, 16)) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 texcoord: TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 clipPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DitherTex;
            int _Threshold;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            float4 frag (v2f i): COLOR
            {
                int ditherPattern[16] =
                {
                    0, 8, 2, 10,
                    12, 4, 14, 6,
                    3, 11, 1, 9,
                    15, 7, 13, 5
                };

                float4 color = tex2D(_MainTex, i.uv);
                float2 viewPortPos = i.clipPos.xy / i.clipPos.w * 0.5 + 0.5;
                float2 screenPos = viewPortPos * _ScreenParams.xy;
                float2 ditherUv = screenPos % 4;
                float dither = ditherPattern[ditherUv.x + ditherUv.y * 4];
                clip(_Threshold - dither);

                return color;
            }
            ENDCG
        }
    }
}
