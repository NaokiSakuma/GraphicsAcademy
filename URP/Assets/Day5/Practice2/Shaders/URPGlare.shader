Shader "Day5/URPGlare"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Off
        ZTest Always
        ZWrite Off

        Tags
        {
            "RenderType"="Opaque"
            // レンダリングパイプラインをURPにする
            "Renderpipeline" = "UniversalPipeline"
        }

        Pass
        {
            // HLSLを記述する
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // hlslでよく使用されるマクロをインクルード
            // #include "UnityCG.cginc"に近い
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // appdeta -> Attributes
            struct Attributes
            {
                // vertex -> positionOS
                // OSはObject Spaceの略
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            // v2f -> Varyings
            struct Varyings
            {
                float2 uv : TEXCOORD0;
                // vertex -> positionHCS
                // HSCはHomogeneous Clip Space（等質クリップ座標）の略
                float4 positionHCS : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Threshold;
            // Texture2Dを宣言
            TEXTURE2D(_CameraDepthTexture);
            // SamplerStateを宣言
            SAMPLER(sampler_CameraDepthTexture);

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                // UnityObjectToClipPos -> TransformObjectToHClip
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            // hlslではfixedが使えないのでhalfにする
            half4 frag (Varyings IN) : SV_Target
            {
                // SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                // textureとsamplerが必要になった
                half depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, IN.uv);
                // Linear01Depth(depth);
                // zBufferParamが必要になった
                half linear01Depth = Linear01Depth(depth, _ZBufferParams);
                half4 col = tex2D(_MainTex, IN.uv);
                half brightness = max(col.r, max(col.g, col.b));
                half contribution = max(0, brightness - _Threshold);
                contribution /= max(brightness, 0.00001);
                return col * contribution * (1 - linear01Depth);
            }

            // HLSLの記述を終える
            ENDHLSL
        }

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
                half2 uvOffset : TEXCOORD1;
                half pathFactor : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _MainTex_TexelSize;
            half3 _Params;
            float _Attenuation;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.pathFactor = pow(4, _Params.z);
                OUT.uvOffset = half2(_Params.x, _Params.y) * _MainTex_TexelSize.xy * OUT.pathFactor;
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 col = half4(0, 0, 0, 1);

                half2 uv = IN.uv;
                [unroll]
                for (int j = 0; j < 4; j++)
                {
                    col.rgb += tex2D(_MainTex, uv).rgb * pow(saturate(_Attenuation), j * IN.pathFactor);
                    uv += IN.uvOffset;
                }

                return col;
            }
            ENDHLSL
        }

        Pass
        {
            Blend One One
            ColorMask RGB

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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Intensity;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                return tex2D(_MainTex, IN.uv) * _Intensity;
            }
            ENDHLSL
        }
    }
}
