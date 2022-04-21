Shader "SnowScene/Footprint"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _Color ("Snow Color", Color) = (1, 1, 1, 0)
        // todo 以下よくわからんマップだけど、パット見ノーマルマップとかに見える
        // todo whiteだとだめ？
        _BumpMap ("Bump Map", 2D) = "bump" {}
        _SpecGlowMap ("Specular Map", 2D) = "white" {}
        // render texture
        _IndentMap ("Indentation Map", 2D) = "white" {}
        // 凹みの滑らかさ
        _Tessellation ("Tessellation", Range(1, 32)) = 4
        // 雪の深さ
        _IndentDepth ("Indentation Depth", Range(0, 0.1)) = 0.1
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Queue"
            "Renderpipeline" = "UniversalPipeline"
        }


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // ?
            // #include "Tessellation.cginc"

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _IndentMap;
                sampler2D _SpecGlossMap;
                sampler2D _BumpMap;

                half4 _Color;
                half _Tessellation;
                half _IndentDepth;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                // どっかで使ってる、多分include先
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            // 名前てきとー、何しているかわかったら命名
            float Sampling(float2 uv, float2 offset)
            {
                return tex2Dlod(_IndentMap, float4(uv - offset, 0, 0)) * _IndentDepth;
            }

            float3 calcNormal(float2 texcoord)
            {
                const float3 off = float3(-0.01f, 0, 0.01f); // texture resolution to sample exact texels
                const float2 size = float2(0.01, 0.0); // size of a single texel in relation to world units

                float s01 = tex2Dlod(_IndentMap, float4(texcoord.xy - off.xy, 0, 0)) * _IndentDepth;
                float s21 = tex2Dlod(_IndentMap, float4(texcoord.xy - off.zy, 0, 0)) * _IndentDepth;
                float s10 = tex2Dlod(_IndentMap, float4(texcoord.xy - off.yx, 0, 0)) * _IndentDepth;
                float s12 = tex2Dlod(_IndentMap, float4(texcoord.xy - off.yz, 0, 0)) * _IndentDepth;

                float3 va = normalize(float3(size.xy, s21 - s01));
                float3 vb = normalize(float3(size.yx, s12 - s10));

                //return float3(s01, s12, 0);
                return normalize(cross(va, vb));
            }


            Varyings vert(Attributes IN)
            {
                // IN.positionOS.z += _IndentDepth;

                Varyings OUT;

                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                // よくわからん
                float3 offset = float3(-0.01f, 0, 0.01f);
                float2 size = float2(0.01, 0.0);

                float xySampling = Sampling(IN.uv, offset.xy);
                float zySampling = Sampling(IN.uv, offset.zy);
                float yxSampling = Sampling(IN.uv, offset.yx);
                float yzSampling = Sampling(IN.uv, offset.yz);

                float3 va = normalize(float3(size.xy, zySampling - xySampling));
                float3 vb = normalize(float3(size.yx, yzSampling - yxSampling));

                // float3 normal = normalize(cross(va, vb));

                float3 normal = normalize(calcNormal(IN.uv) + IN.positionOS.xyz);

                OUT.normal = normalize(normal + IN.normal);

                // うまくいかない
                // float3 tmpVertex = normalize(IN.normal + normal) * _IndentDepth;
                // コピってみる
                // float d = tex2Dlod(_IndentMap, float4(1 - IN.uv.x, IN.uv.y, 0, 0)).r * _IndentDepth;
                // float3 tmpVertex = IN.normal * (1 - d);
                IN.positionOS.xyz += normal * _IndentDepth;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                // float height = tex2Dlod(_IndentMap, )

                return OUT;
            }

            half4 frag(Varyings IN) :SV_TARGET
            {
                half4 rtCol = tex2D(_IndentMap, IN.uv);
                return rtCol;

                half4 col = tex2D(_MainTex, IN.uv);
                return col;
            }
            ENDHLSL
        }
    }
}
