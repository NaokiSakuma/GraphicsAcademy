Shader "TrailByShaderGraph"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _TrailTexture ("TrailTexture", 2D) = "white" {}
        _NormalTexture ("NormalTexture", 2D) = "white" {}
        _DepthAmount ("Depth Amount", float) = -0.17
        _LightPow ("LightPow", Range(0, 1)) = 0
        _BlurWidth ("_BlurWidth", float) = 0.01
        _TessFactor ("Tessellation", Range(1, 50)) = 10
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "Renderpipeline" = "UniversalPipeline"
        }

        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hull
            #pragma domain domain

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float4 _MainTex_ST;
                TEXTURE2D(_TrailTexture);
                float _DepthAmount;
                float _LightPow;
                float _BlurWidth;
                float _TessFactor;
                SamplerState sampler_linear_repeat;
                SAMPLER(SamplerState_Linear_Repeat);
                float4 _TrailTexture_ST;
                sampler2D _NormalTexture;
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


            // RenderTextureから高さを求める
            float3 CalcHeight(float2 uv)
            {
                float3 mainTrail;

                // 隣接も影響させる
                for(int i = -1; i <= 1; i++)
                {
                    for(int j = -1; j <= 1; j++)
                    {
                        mainTrail += SAMPLE_TEXTURE2D_LOD(_TrailTexture, SamplerState_Linear_Repeat,
                            float2(uv.x + i * _BlurWidth, uv.y + j * _BlurWidth), 1);
                    }
                }

                return saturate(mainTrail / 9.0);
            }

            HsInput vert(VSInput IN)
            {
                HsInput OUT;
                OUT.uv = IN.uv;
                OUT.normalOS = IN.normal;
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

                float3 depth = float3(0, _DepthAmount, 0);
                float3 multied = CalcHeight(output.uv) * depth;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS + multied);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(normalOS, tangentOS);

                output.positionCS = TransformWorldToHClip(vertexInput.positionWS);

                Light mainLight = GetMainLight();

                float3x3 tangentMat = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
                output.lightTS = mul(tangentMat, mainLight.direction);;

                return output;
            }

            half4 frag(DsOutput IN) :SV_TARGET
            {
                float3 normalByTex = UnpackNormal(tex2D(_NormalTexture, IN.uv));
                float diff = 1 - saturate(dot(normalByTex, IN.lightTS));
                half4 col = tex2D(_MainTex, IN.uv);
                diff = lerp(1, diff, _LightPow);
                col.rgb *= diff;
                return col;
            }
            ENDHLSL
        }
    }
}
