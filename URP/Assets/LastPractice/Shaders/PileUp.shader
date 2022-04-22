Shader "SnowScene/PileUp"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TrailTex ("TrailTex", 2D) = "white" {}
        _PileSpeed ("Pile Speed", float) = 0.1
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
                sampler2D _TrailTex;
                float4 _TrailTex_ST;
                float _PileSpeed;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _TrailTex);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 col = tex2D(_TrailTex, IN.uv);
                col.rgb = saturate(col.rbg - _PileSpeed);
                return col;
            }
            ENDHLSL
        }
    }
}
