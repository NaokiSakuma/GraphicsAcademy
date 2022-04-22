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
        _TessFactor ("Tessellation", Range(1, 50)) = 10
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
            #pragma hull hull
            #pragma domain domain

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ?
            // #include "Tessellation.cginc"
            TEXTURE2D(_IndentMap);
            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float4 _MainTex_ST;

                sampler2D _SpecGlossMap;
                sampler2D _BumpMap;
                float _TessFactor;
                half4 _Color;
                half _Tessellation;
                half _IndentDepth;
            SAMPLER(sampler_linear_repeat);
            SAMPLER(sampler_IndentMap);
            CBUFFER_END

            struct VSInput
            {
                float4 positionOS : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct HsInput
            {
                float4 positionOS  : POS;
                half3 normalOS     : NORMAL;
                float2 uv          : TEXCOORD0;
                half4 tangentOS    : TEXCOORD1;
            };

            struct HsControlPointOutput
            {
                float3 positionOS : POS;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD;
                float4 tangentOS  : TEXCOORD3;
            };

            struct HsConstantOutput
            {
                float tessFactor[3]    : SV_TessFactor;
                float insideTessFactor : SV_InsideTessFactor;
            };

            struct DsOutput
            {
                float4 positionCS : SV_Position;
                float2 uv         : TEXCOORD0;
                float3 lightTS    : TEXCOORD1;
            };

            // struct Varyings
            // {
            //     float4 positionHCS : SV_POSITION;
            //     float3 normal : NORMAL;
            //     float2 uv : TEXCOORD0;
            // };

            // 名前てきとー、何しているかわかったら命名
            // float Sampling(float2 uv, float2 offset)
            // {
            //     return tex2Dlod(_IndentMap, float4(uv - offset, 0, 0)) * _IndentDepth;
            // }
            //
            // float3 calcNormal(float2 texcoord)
            // {
            //     const float3 off = float3(-0.01f, 0, 0.01f); // texture resolution to sample exact texels
            //     const float2 size = float2(0.01, 0.0); // size of a single texel in relation to world units
            //
            //     float s01 = tex2Dlod(_IndentMap, float4(texcoord.xy - off.xy, 0, 0)) * _IndentDepth;
            //     float s21 = tex2Dlod(_IndentMap, float4(texcoord.xy - off.zy, 0, 0)) * _IndentDepth;
            //     float s10 = tex2Dlod(_IndentMap, float4(texcoord.xy - off.yx, 0, 0)) * _IndentDepth;
            //     float s12 = tex2Dlod(_IndentMap, float4(texcoord.xy - off.yz, 0, 0)) * _IndentDepth;
            //
            //     float3 va = normalize(float3(size.xy, s21 - s01));
            //     float3 vb = normalize(float3(size.yx, s12 - s10));
            //
            //     //return float3(s01, s12, 0);
            //     return normalize(cross(va, vb));
            // }

            float3 CalcHeight(float2 uv)
            {
                float3 mainTrail;

                for(int i = -1; i <= 1; i++)
                {
                    for(int j = -1; j <= 1; j++)
                    {
                        mainTrail += SAMPLE_TEXTURE2D_LOD(_IndentMap, sampler_linear_repeat,
                            float2(uv.x + i * 0.01, uv.y + j * 0.01), 1);
                    }
                }

                return saturate(mainTrail / 9.0);
            }

            HsInput vert(VSInput IN)
            {
                // IN.positionOS.z += _IndentDepth;

                HsInput OUT;

                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                // よくわからん
                float3 offset = float3(-0.01f, 0, 0.01f);
                float2 size = float2(0.01, 0.0);

                // float xySampling = Sampling(IN.uv, offset.xy);
                // float zySampling = Sampling(IN.uv, offset.zy);
                // float yxSampling = Sampling(IN.uv, offset.yx);
                // float yzSampling = Sampling(IN.uv, offset.yz);

                // float3 va = normalize(float3(size.xy, zySampling - xySampling));
                // float3 vb = normalize(float3(size.yx, yzSampling - yxSampling));

                // float3 normal = normalize(cross(va, vb));

                // float3 normal = normalize(calcNormal(IN.uv) + IN.normal.xyz);

                float3 normal = CalcHeight(IN.uv);

                OUT.normalOS = IN.normal;
                IN.positionOS.xyz += normal * _IndentDepth;

                OUT.positionOS = float4(IN.positionOS.xyz, 1);
                OUT.tangentOS = IN.tangent;
                return OUT;
            }

            [domain("tri")]
            [partitioning("integer")]
            [outputtopology("triangle_cw")]
            [patchconstantfunc("hullConst")]
            [outputcontrolpoints(3)]
            HsControlPointOutput hull(InputPatch<HsInput, 3> input, uint id : SV_OutputControlPointID)
            {
                HsControlPointOutput output;
                output.positionOS = input[id].positionOS.xyz;
                output.normalOS   = input[id].normalOS;
                output.uv         = input[id].uv;
                output.tangentOS  = input[id].tangentOS;
                return output;
            }

            HsConstantOutput hullConst(InputPatch<HsInput, 3> i)
            {
                HsConstantOutput o;

                float4 p0 = i[0].positionOS;
                float4 p1 = i[1].positionOS;
                float4 p2 = i[2].positionOS;

                o.tessFactor[0] = _TessFactor;
                o.tessFactor[1] = _TessFactor;
                o.tessFactor[2] = _TessFactor;
                o.insideTessFactor = _TessFactor;

                return o;
            }

            [domain("tri")]
            DsOutput domain(
            HsConstantOutput hsConst,
            const OutputPatch<HsControlPointOutput, 3> input,
            float3 bary : SV_DomainLocation)
            {
                DsOutput output;

                float3 positionOS =
                bary.x * input[0].positionOS +
                bary.y * input[1].positionOS +
                bary.z * input[2].positionOS;

                float3 normalOS = normalize(
                bary.x * input[0].normalOS +
                bary.y * input[1].normalOS +
                bary.z * input[2].normalOS);

                output.uv =
                bary.x * input[0].uv +
                bary.y * input[1].uv +
                bary.z * input[2].uv;

                float4 tangentOS = normalize(
                bary.x * input[0].tangentOS +
                bary.y * input[1].tangentOS +
                bary.z * input[2].tangentOS);

                // ここ？
                // float3 normal = normalize(calcNormal(output.uv) + normalOS.xyz);
                // float d = tex2Dlod(_IndentMap, float4(1 - output.uv.x, output.uv.y, 0, 0)).r * _IndentDepth;
                // positionOS.xyz += normal;


                // ----------------- copied from vertex shader -------------------
                // get vectors in the world coordinate
                VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(normalOS, tangentOS);

                output.positionCS = TransformWorldToHClip(vertexInput.positionWS);

                // Get Main Light
                Light mainLight = GetMainLight();

                // world to tangent
                float3x3 tangentMat = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
                output.lightTS = mul(tangentMat, mainLight.direction);;
                // ----------------- copied from vertex shader END-------------------

                return output;
            }

            half4 frag(DsOutput IN) :SV_TARGET
            {
                return half4(1,1,1,1);
                // half4 col = tex2D(_MainTex, IN.uv);
                // float3 normal = UnpackNormal(tex2D(_IndentMap, IN.uv));
                // float diff = saturate(dot(IN.lightTS, normal));
                //
                // col *= diff;
                // return col;

                // half4 rtCol = tex2D(_IndentMap, IN.uv);
                // return rtCol;
                //
                // half4 col = tex2D(_MainTex, IN.uv);
                // return col;
            }
            ENDHLSL
        }
    }
}
